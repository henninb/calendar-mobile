import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../api/api_client.dart';
import '../core/constants.dart';
import '../database/app_database.dart';
import '../services/sync_service.dart';

// ── Shared Preferences ───────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

// ── Secure Storage ───────────────────────────────────────────────────────────

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

/// Holds the API key value eagerly loaded from secure storage at startup,
/// so ApiKeyNotifier.build() can remain synchronous.
final apiKeyInitialValueProvider = Provider<String>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

// ── Settings ─────────────────────────────────────────────────────────────────

final baseUrlProvider = NotifierProvider<BaseUrlNotifier, String>(BaseUrlNotifier.new);

class BaseUrlNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString(AppConstants.prefBaseUrl) ?? AppConstants.defaultBaseUrl;
  }

  void set(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
      dev.log('BaseUrlNotifier.set: rejected non-https URL', name: 'settings');
      return;
    }
    state = url;
    ref.read(sharedPreferencesProvider).setString(AppConstants.prefBaseUrl, url);
  }
}

final apiKeyProvider = NotifierProvider<ApiKeyNotifier, String>(ApiKeyNotifier.new);

class ApiKeyNotifier extends Notifier<String> {
  @override
  String build() {
    // Initial value was read from secure storage in main() before runApp.
    return ref.read(apiKeyInitialValueProvider);
  }

  Future<void> set(String key) async {
    state = key;
    // Persist to Android Keystore / iOS Keychain; never write to SharedPreferences.
    await ref.read(secureStorageProvider).write(
      key: AppConstants.prefApiKey,
      value: key,
    );
  }
}

// ── Database ─────────────────────────────────────────────────────────────────

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── API Client ───────────────────────────────────────────────────────────────
//
// Fix: use a NotifierProvider so the ApiClient (and its underlying Dio instance)
// is created once and reused. URL changes call updateBaseUrl() in-place instead
// of leaking a new Dio instance on every settings save.

final apiClientProvider = NotifierProvider<ApiClientNotifier, ApiClient>(ApiClientNotifier.new);

class ApiClientNotifier extends Notifier<ApiClient> {
  @override
  ApiClient build() {
    final client = ApiClient(ref.read(baseUrlProvider), apiKey: ref.read(apiKeyProvider));
    ref.listen<String>(baseUrlProvider, (_, next) => client.updateBaseUrl(next));
    ref.listen<String>(apiKeyProvider, (_, next) => client.updateApiKey(next));
    return client;
  }
}

// ── Sync Service ─────────────────────────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(dbProvider), ref.watch(apiClientProvider));
});

// ── Forced Offline Toggle ────────────────────────────────────────────────────
//
// Persisted manual override that suppresses all sync regardless of network
// state. Useful when the WireGuard tunnel is down but the OS still reports
// a network interface as connected.

final forcedOfflineProvider =
    NotifierProvider<ForcedOfflineNotifier, bool>(ForcedOfflineNotifier.new);

class ForcedOfflineNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(sharedPreferencesProvider)
            .getBool(AppConstants.prefForcedOffline) ??
        false;
  }

  void toggle() {
    final next = !state;
    state = next;
    ref
        .read(sharedPreferencesProvider)
        .setBool(AppConstants.prefForcedOffline, next);
    dev.log('ForcedOfflineNotifier: forcedOffline=$next', name: 'connectivity');
  }
}

// ── Connectivity ─────────────────────────────────────────────────────────────
//
// connectivity_plus only fires onConnectivityChanged when the state *changes*.
// On Linux/desktop the stream never emits at startup, so we do an explicit
// checkConnectivity() call and then stay subscribed to changes.
//
// The effective online state is: networkOnline AND NOT forcedOffline.
// This keeps isOnlineProvider as the single source of truth consumed by all
// sync logic — no call sites need changing.

final _connectivity = Connectivity();

final isOnlineProvider =
    NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);

class ConnectivityNotifier extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _active = false;
  bool _networkOnline = true;

  @override
  bool build() {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _sub?.cancel();
    });

    // Re-evaluate effective state whenever the forced-offline toggle changes.
    ref.listen<bool>(forcedOfflineProvider, (_, _) {
      if (!_active) return;
      state = _networkOnline && !ref.read(forcedOfflineProvider);
    });

    _init();
    // Optimistic initial state: assume network is up, honour forced-offline.
    return !ref.read(forcedOfflineProvider);
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    if (!_active) return;
    _networkOnline = _isOnline(results);
    state = _networkOnline && !ref.read(forcedOfflineProvider);

    _sub = _connectivity.onConnectivityChanged.listen((results) {
      if (!_active) return;
      _networkOnline = _isOnline(results);
      final forced = ref.read(forcedOfflineProvider);
      final effective = _networkOnline && !forced;
      dev.log(
        'ConnectivityNotifier: network=$_networkOnline forced=$forced → effective=$effective'
        ' (${results.map((r) => r.name).join(', ')})',
        name: 'connectivity',
      );
      state = effective;
    });
  }

  static bool _isOnline(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);
}

// Keep the stream around for the Settings screen's detail display.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return _connectivity.onConnectivityChanged;
});

// ── Sync State ───────────────────────────────────────────────────────────────

enum SyncPhase { idle, pulling, pushing, error }

class SyncState {
  final SyncPhase phase;
  final String? errorMessage;
  final int pendingCount;

  const SyncState({
    this.phase = SyncPhase.idle,
    this.errorMessage,
    this.pendingCount = 0,
  });

  SyncState copyWith({
    SyncPhase? phase,
    Object? errorMessage = _keep,
    int? pendingCount,
  }) =>
      SyncState(
        phase: phase ?? this.phase,
        errorMessage: identical(errorMessage, _keep)
            ? this.errorMessage
            : errorMessage as String?,
        pendingCount: pendingCount ?? this.pendingCount,
      );

  // Sentinel that distinguishes "caller did not pass errorMessage" from
  // "caller explicitly passed null to clear it".
  static const _keep = Object();
}

final syncStateProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);

class SyncNotifier extends Notifier<SyncState> {
  Timer? _periodicTimer;

  @override
  SyncState build() {
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      // Fix: skip the refresh when offline so we don't transition to
      // SyncPhase.error every 5 minutes and show a spurious error banner.
      (_) { if (ref.read(isOnlineProvider) && ref.read(baseUrlProvider).isNotEmpty) silentRefresh(); },
    );
    ref.onDispose(() => _periodicTimer?.cancel());
    return const SyncState();
  }

  Future<void> sync() async {
    if (ref.read(baseUrlProvider).isEmpty) {
      state = state.copyWith(
        phase: SyncPhase.error,
        errorMessage: 'No backend URL configured — enter one in Settings',
      );
      return;
    }
    // Allow retrying from error state so a single push failure doesn't
    // permanently block future syncs (e.g. recurring task chain breaks).
    if (state.phase != SyncPhase.idle && state.phase != SyncPhase.error) return;
    dev.log('SyncNotifier.sync: start', name: 'sync');

    final syncSvc = ref.read(syncServiceProvider);

    state = state.copyWith(phase: SyncPhase.pushing, errorMessage: null);
    String? pushError;
    try {
      final result = await syncSvc.pushPending();
      if (result.errors.isNotEmpty) {
        dev.log('SyncNotifier.sync: push errors=${result.errors}', name: 'sync', level: 900);
        pushError = result.errors.first;
        // Fall through — still do fullRefresh so the server-spawned next
        // recurring task is pulled down even when some pushes failed.
      }
    } catch (e) {
      dev.log('SyncNotifier.sync: push threw $e', name: 'sync', level: 900);
      pushError = _friendlyError(e);
    }

    state = state.copyWith(phase: SyncPhase.pulling);
    try {
      await syncSvc.fullRefresh();
      dev.log('SyncNotifier.sync: complete', name: 'sync');
      // Surface any push error after a successful pull so the user sees it
      // but future sync cycles can still proceed.
      state = state.copyWith(
        phase: pushError != null ? SyncPhase.error : SyncPhase.idle,
        errorMessage: pushError,
      );
    } catch (e) {
      dev.log('SyncNotifier.sync: refresh threw $e', name: 'sync', level: 900);
      state = state.copyWith(
        phase: SyncPhase.error,
        errorMessage: pushError ?? _friendlyError(e),
      );
    }
  }

  // Called on a timer. Also pushes pending items so mutations queued while
  // offline are sent as soon as connectivity is restored between timer ticks.
  Future<void> silentRefresh() async {
    if (ref.read(baseUrlProvider).isEmpty) return; // not yet configured
    if (state.phase != SyncPhase.idle) return;
    dev.log('SyncNotifier.silentRefresh: start', name: 'sync');
    state = state.copyWith(phase: SyncPhase.pulling);
    final svc = ref.read(syncServiceProvider);
    try {
      // Push any items queued while offline; swallow push errors here — they
      // will surface when the user next triggers an explicit sync.
      try {
        final result = await svc.pushPending();
        if (result.errors.isNotEmpty) {
          dev.log('SyncNotifier.silentRefresh: push errors (suppressed)=${result.errors}', name: 'sync', level: 900);
        }
      } catch (e) {
        dev.log('SyncNotifier.silentRefresh: push threw (suppressed) $e', name: 'sync', level: 900);
      }
      await svc.fullRefresh();
      dev.log('SyncNotifier.silentRefresh: complete', name: 'sync');
      state = state.copyWith(phase: SyncPhase.idle, errorMessage: null);
    } catch (e) {
      dev.log('SyncNotifier.silentRefresh: threw $e', name: 'sync', level: 900);
      state = state.copyWith(
        phase: SyncPhase.error,
        errorMessage: _friendlyError(e),
      );
    }
  }

  /// Triggers a full sync only when the app has effective connectivity.
  /// Safe to call after a widget's ref has been disposed because this method
  /// uses the notifier's own internal ref, not the caller's widget ref.
  void syncIfOnline() {
    if (ref.read(isOnlineProvider)) sync();
  }

  void clearError() {
    state = state.copyWith(phase: SyncPhase.idle, errorMessage: null);
  }

  // Keep both the start (exception type) and the tail (key detail)
  // so truncation never hides the most useful part of the message.
  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Connection refused') || msg.contains('SocketException')) {
      return 'Cannot reach backend — check the URL in Settings';
    }
    if (msg.contains('timed out')) return 'Request timed out — is the server running?';
    if (msg.length <= 120) return msg;
    return '${msg.substring(0, 80)}…${msg.substring(msg.length - 37)}';
  }
}

// ── Data Streams ─────────────────────────────────────────────────────────────

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(dbProvider).watchCategories();
});

final eventsProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(dbProvider).watchEvents();
});

final occurrencesProvider = StreamProvider<List<Occurrence>>((ref) {
  return ref.watch(dbProvider).watchOccurrences();
});

final tasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(dbProvider).watchTasks();
});

final creditCardsProvider = StreamProvider<List<CreditCard>>((ref) {
  return ref.watch(dbProvider).watchCreditCards();
});

final trackerCacheProvider = StreamProvider<List<CreditCardTrackerCacheData>>((ref) {
  return ref.watch(dbProvider).watchTrackerCache();
});

final personsProvider = StreamProvider<List<Person>>((ref) {
  return ref.watch(dbProvider).watchPersons();
});

final subtasksForTaskProvider = StreamProvider.autoDispose.family<List<Subtask>, int>((ref, taskLocalId) {
  return ref.watch(dbProvider).watchSubtasksForTask(taskLocalId);
});
