import 'dart:async';
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
// connectivity_plus only fires onConnectivityChanged when the state *changes*.
// On Linux/desktop the stream never emits at startup, so we do an explicit
// checkConnectivity() call and then stay subscribed to changes.

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
    final results = await Connectivity().checkConnectivity();
    if (mounted) state = _isOnline(results);

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) state = _isOnline(results);
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

// Keep the stream around for the Settings screen's detail display
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
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
  SyncNotifier(this._ref) : super(const SyncState());

  final Ref _ref;

  Future<void> sync() async {
    if (state.phase != SyncPhase.idle) return;

    final syncSvc = _ref.read(syncServiceProvider);

    state = state.copyWith(phase: SyncPhase.pushing);
    try {
      final result = await syncSvc.pushPending();
      if (result.errors.isNotEmpty) {
        state = state.copyWith(
          phase: SyncPhase.error,
          errorMessage: result.errors.first,
        );
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      state = state.copyWith(phase: SyncPhase.error, errorMessage: e.toString());
      await Future.delayed(const Duration(seconds: 2));
    }

    state = state.copyWith(phase: SyncPhase.pulling);
    try {
      await syncSvc.fullRefresh();
      state = state.copyWith(phase: SyncPhase.idle, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        phase: SyncPhase.error,
        errorMessage: _friendlyError(e),
      );
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(phase: SyncPhase.idle);
    }
  }

  // Called on startup — doesn't touch the sync phase indicator so it's silent
  // until an error occurs.
  Future<void> silentRefresh() async {
    if (state.phase != SyncPhase.idle) return;
    state = state.copyWith(phase: SyncPhase.pulling);
    try {
      await _ref.read(syncServiceProvider).fullRefresh();
      state = state.copyWith(phase: SyncPhase.idle, errorMessage: null);
    } catch (e) {
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

  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Connection refused') || msg.contains('SocketException')) {
      return 'Cannot reach backend — check the URL in Settings';
    }
    if (msg.contains('timed out')) return 'Request timed out — is the server running?';
    return msg.length > 120 ? '${msg.substring(0, 120)}…' : msg;
  }
}

// ── Data Streams ─────────────────────────────────────────────────────────────

final categoriesProvider = StreamProvider((ref) {
  return ref.watch(dbProvider).watchCategories();
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
