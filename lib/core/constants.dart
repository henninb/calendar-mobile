class AppConstants {
  AppConstants._();

  static const String defaultBaseUrl = 'https://calendar.bhenning.com';
  static const String prefBaseUrl      = 'base_url';
  static const String prefSyncDays     = 'gcal_sync_days';
  static const String prefSyncForce    = 'gcal_sync_force';
  static const String prefForcedOffline = 'forced_offline';
  static const int    defaultSyncDays = 365;

  static const Duration syncDebounce  = Duration(seconds: 3);
  static const Duration connectCheck  = Duration(seconds: 5);
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
  /// Falls back to [synced] for unexpected values so callers never crash,
  /// but the unknown value will simply not be pushed.
  static SyncStatus fromInt(int v) => SyncStatus.values.firstWhere(
        (s) => s.value == v,
        orElse: () => SyncStatus.synced,
      );
}
