import 'dart:developer' as dev;

abstract final class AppConstants {

  // Supply at build time: flutter build apk --dart-define=DEFAULT_BASE_URL=https://...
  // Intentionally empty when not provided so no personal domain is baked into source.
  static const String defaultBaseUrl = String.fromEnvironment(
    'DEFAULT_BASE_URL',
    defaultValue: '',
  );
  static const String prefBaseUrl      = 'base_url';
  static const String prefApiKey       = 'api_key';
  static const String prefSyncDays     = 'gcal_sync_days';
  static const String prefSyncForce    = 'gcal_sync_force';
  static const String prefForcedOffline = 'forced_offline';
  static const int    defaultSyncDays = 365;

  static const Duration syncDebounce    = Duration(seconds: 3);
  static const Duration connectCheck    = Duration(seconds: 5);
  static const Duration periodicSync    = Duration(minutes: 5);
  static const Duration wgCheckTimeout  = Duration(seconds: 3);
  static const Duration wgRequestTimeout = Duration(seconds: 15);
  static const Duration wgVerifyDelay   = Duration(seconds: 2);

  static const int occurrencePastMonths   = 1;
  static const int occurrenceFutureMonths = 3;
}

abstract final class TaskStatus {
  static const String todo       = 'todo';
  static const String inProgress = 'in_progress';
  static const String done       = 'done';
  static const String cancelled  = 'cancelled';
}

abstract final class OccurrenceStatus {
  static const String upcoming  = 'upcoming';
  static const String completed = 'completed';
  static const String skipped   = 'skipped';
  static const String overdue   = 'overdue';
}

abstract final class GroceryConstants {
  static const List<String> units = [
    'each', 'lb', 'oz', 'fl_oz', 'g', 'kg', 'liter', 'ml',
    'bunch', 'bag', 'box', 'can', 'jar', 'pack',
  ];
}

// Fix #12: enum gives exhaustive switch checking; explicit .value property
// maps to the integer stored in SQLite (column type stays IntColumn).
enum SyncStatus {
  synced(0),
  pendingCreate(1),
  pendingUpdate(2),
  pendingDelete(3);

  const SyncStatus(this.value);
  final int value;

  /// Converts the raw SQLite integer back to the enum.
  /// Falls back to [pendingUpdate] for unrecognised values so the row is
  /// retried rather than silently dropped.
  static SyncStatus fromInt(int v) {
    final result = SyncStatus.values.where((s) => s.value == v).firstOrNull;
    if (result == null) {
      dev.log(
        'SyncStatus.fromInt: unexpected value $v, treating as pendingUpdate',
        name: 'db',
        level: 900,
      );
      return SyncStatus.pendingUpdate;
    }
    return result;
  }

  /// Returns the status a record should carry after a local mutation.
  /// Synced records become [pendingUpdate]; any already-pending status is
  /// preserved so a [pendingCreate] is never downgraded to [pendingUpdate]
  /// (which would cause the push to be skipped due to a missing serverId).
  static int next(int current) =>
      current == SyncStatus.synced.value ? SyncStatus.pendingUpdate.value : current;
}
