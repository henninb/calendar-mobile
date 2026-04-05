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

final baseUrlProvider = StateNotifierProvider<BaseUrlNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BaseUrlNotifier(prefs);
});

class BaseUrlNotifier extends StateNotifier<String> {
  BaseUrlNotifier(this._prefs)
      : super(_prefs.getString(AppConstants.prefBaseUrl) ?? AppConstants.defaultBaseUrl);

  final SharedPreferences _prefs;

  void set(String url) {
    state = url;
    _prefs.setString(AppConstants.prefBaseUrl, url);
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
// Fix #9: single Connectivity instance shared by both providers to avoid
// duplicate platform-channel subscriptions.
//
// connectivity_plus only fires onConnectivityChanged when the state *changes*.
// On Linux/desktop the stream never emits at startup, so we do an explicit
// checkConnectivity() call and then stay subscribed to changes.

final _connectivity = Connectivity();

final isOnlineProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    if (mounted) state = _isOnline(results);

    _sub = _connectivity.onConnectivityChanged.listen((results) {
      if (mounted) {
        final online = _isOnline(results);
        dev.log('ConnectivityNotifier: online=$online (${results.map((r) => r.name).join(', ')})', name: 'connectivity');
        state = online;
      }
    });
  }

  static bool _isOnline(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// Keep the stream around for the Settings screen's detail display.
// Reuses the same Connectivity instance (fix #9).
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

final syncStateProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(this._ref) : super(const SyncState()) {
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => silentRefresh(),
    );
  }

  final Ref _ref;
  Timer? _periodicTimer;

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> sync() async {
    if (state.phase != SyncPhase.idle) return;
    dev.log('SyncNotifier.sync: start', name: 'sync');

    final syncSvc = _ref.read(syncServiceProvider);

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
      await syncSvc.fullRefresh();
      dev.log('SyncNotifier.sync: complete', name: 'sync');
      state = state.copyWith(phase: SyncPhase.idle, errorMessage: null);
    } catch (e) {
      dev.log('SyncNotifier.sync: refresh threw $e', name: 'sync', level: 900);
      state = state.copyWith(
        phase: SyncPhase.error,
        errorMessage: _friendlyError(e),
      );
      // stay in error — user must dismiss before syncing again
    }
  }

  // Called on startup — doesn't touch the sync phase indicator so it's silent
  // until an error occurs.
  Future<void> silentRefresh() async {
    if (state.phase != SyncPhase.idle) return;
    dev.log('SyncNotifier.silentRefresh: start', name: 'sync');
    state = state.copyWith(phase: SyncPhase.pulling);
    try {
      await _ref.read(syncServiceProvider).fullRefresh();
      dev.log('SyncNotifier.silentRefresh: complete', name: 'sync');
      state = state.copyWith(phase: SyncPhase.idle, errorMessage: null);
    } catch (e) {
      dev.log('SyncNotifier.silentRefresh: threw $e', name: 'sync', level: 900);
      // Keep error visible (don't auto-dismiss) so the user can read it.
      state = state.copyWith(
        phase: SyncPhase.error,
        errorMessage: _friendlyError(e),
      );
    }
  }

  void clearError() {
    state = state.copyWith(phase: SyncPhase.idle, errorMessage: null);
  }

  // Fix #13: keep both the start (exception type) and the tail (key detail)
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
