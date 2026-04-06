import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// ── Settings ─────────────────────────────────────────────────────────────────

final baseUrlProvider = NotifierProvider<BaseUrlNotifier, String>(BaseUrlNotifier.new);

class BaseUrlNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString(AppConstants.prefBaseUrl) ?? AppConstants.defaultBaseUrl;
  }

  void set(String url) {
    state = url;
    ref.read(sharedPreferencesProvider).setString(AppConstants.prefBaseUrl, url);
  }
}

// ── Database ─────────────────────────────────────────────────────────────────

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── API Client ───────────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  return ApiClient(baseUrl);
});

// ── Sync Service ─────────────────────────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(dbProvider), ref.watch(apiClientProvider));
});

// ── Connectivity ─────────────────────────────────────────────────────────────
//
// connectivity_plus only fires onConnectivityChanged when the state *changes*.
// On Linux/desktop the stream never emits at startup, so we do an explicit
// checkConnectivity() call and then stay subscribed to changes.

final _connectivity = Connectivity();

final isOnlineProvider = NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);

class ConnectivityNotifier extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _active = false;

  @override
  bool build() {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _sub?.cancel();
    });
    _init();
    return true; // optimistic initial state until checkConnectivity completes
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    if (!_active) return;
    state = _isOnline(results);

    _sub = _connectivity.onConnectivityChanged.listen((results) {
      if (!_active) return;
      final online = _isOnline(results);
      dev.log(
        'ConnectivityNotifier: online=$online (${results.map((r) => r.name).join(', ')})',
        name: 'connectivity',
      );
      state = online;
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

  SyncState copyWith({SyncPhase? phase, String? errorMessage, int? pendingCount}) =>
      SyncState(
        phase: phase ?? this.phase,
        errorMessage: errorMessage,
        pendingCount: pendingCount ?? this.pendingCount,
      );
}

final syncStateProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);

class SyncNotifier extends Notifier<SyncState> {
  Timer? _periodicTimer;

  @override
  SyncState build() {
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => silentRefresh(),
    );
    ref.onDispose(() => _periodicTimer?.cancel());
    return const SyncState();
  }

  Future<void> sync() async {
    if (state.phase != SyncPhase.idle) return;
    dev.log('SyncNotifier.sync: start', name: 'sync');

    final syncSvc = ref.read(syncServiceProvider);

    state = state.copyWith(phase: SyncPhase.pushing);
    try {
      final result = await syncSvc.pushPending();
      if (result.errors.isNotEmpty) {
        dev.log('SyncNotifier.sync: push errors=${result.errors}', name: 'sync', level: 900);
        state = state.copyWith(
          phase: SyncPhase.error,
          errorMessage: result.errors.first,
        );
        return; // stay in error — user must dismiss before syncing again
      }
    } catch (e) {
      dev.log('SyncNotifier.sync: push threw $e', name: 'sync', level: 900);
      state = state.copyWith(phase: SyncPhase.error, errorMessage: e.toString());
      return;
    }

    state = state.copyWith(phase: SyncPhase.pulling);
    try {
      await ref.read(syncServiceProvider).fullRefresh();
      dev.log('SyncNotifier.sync: complete', name: 'sync');
      state = state.copyWith(phase: SyncPhase.idle, errorMessage: null);
    } catch (e) {
      dev.log('SyncNotifier.sync: refresh threw $e', name: 'sync', level: 900);
      state = state.copyWith(
        phase: SyncPhase.error,
        errorMessage: _friendlyError(e),
      );
    }
  }

  // Called on a timer — doesn't touch the sync phase indicator so it's silent
  // until an error occurs.
  Future<void> silentRefresh() async {
    if (state.phase != SyncPhase.idle) return;
    dev.log('SyncNotifier.silentRefresh: start', name: 'sync');
    state = state.copyWith(phase: SyncPhase.pulling);
    try {
      await ref.read(syncServiceProvider).fullRefresh();
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

final categoriesProvider = StreamProvider((ref) {
  return ref.watch(dbProvider).watchCategories();
});

final eventsProvider = StreamProvider((ref) {
  return ref.watch(dbProvider).watchEvents();
});

final occurrencesProvider = StreamProvider((ref) {
  return ref.watch(dbProvider).watchOccurrences();
});

final tasksProvider = StreamProvider((ref) {
  return ref.watch(dbProvider).watchTasks();
});

final creditCardsProvider = StreamProvider((ref) {
  return ref.watch(dbProvider).watchCreditCards();
});

final trackerCacheProvider = StreamProvider((ref) {
  return ref.watch(dbProvider).watchTrackerCache();
});

final personsProvider = StreamProvider((ref) {
  return ref.watch(dbProvider).watchPersons();
});

final subtasksForTaskProvider = StreamProvider.autoDispose.family<List<Subtask>, int>((ref, taskLocalId) {
  return ref.watch(dbProvider).watchSubtasksForTask(taskLocalId);
});
