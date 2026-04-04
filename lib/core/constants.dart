class AppConstants {
  AppConstants._();

  static const String defaultBaseUrl = 'https://calendar.bhenning.com';
  static const String prefBaseUrl    = 'base_url';
  static const String prefSyncDays   = 'gcal_sync_days';
  static const String prefSyncForce  = 'gcal_sync_force';
  static const int    defaultSyncDays = 365;

  static const Duration syncDebounce  = Duration(seconds: 3);
  static const Duration connectCheck  = Duration(seconds: 5);
}

// Sync status codes stored in SQLite
class SyncStatus {
  static const int synced        = 0;
  static const int pendingCreate = 1;
  static const int pendingUpdate = 2;
  static const int pendingDelete = 3;
}
