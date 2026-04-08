# CLAUDE.md — calendar-mobile

## Project Overview

Flutter offline-first mobile app that mirrors a remote `calendar-app` REST API.
- **State management**: Riverpod (`flutter_riverpod`)
- **Local DB**: Drift (SQLite ORM) — `lib/database/app_database.dart`
- **HTTP**: Dio — `lib/api/api_client.dart`
- **Sync layer**: `lib/services/sync_service.dart` (pull + push pending mutations)
- **Targets**: Android, iOS, Linux desktop

## Build & Run

```bash
# Code generation (Drift, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Analyze
flutter analyze

# Test
flutter test

# Run (choose a connected device/emulator)
flutter run
```

## Architecture

```
lib/
  api/          # Dio client + JSON models (pure data, no Flutter deps)
  core/         # AppConstants, SyncStatus enum, theme
  database/     # Drift tables, DAOs, migration strategy
  providers/    # Riverpod providers
  screens/      # UI screens
  services/     # SyncService (business logic)
  widgets/      # Reusable widgets
```

---

## Security Practices (always follow these)

### 1. Never log sensitive data
Use `dart:developer` `log()` (already the project standard — never `print()`).
Never include financial data, full card numbers, email addresses, or tokens in log output.
Credit card `lastFour` and tracker rows are PII — keep them out of logs.

```dart
// GOOD
dev.log('sync complete: pushed=$count', name: 'sync');

// BAD — leaks PII
dev.log('card: ${card.name} ${card.lastFour}', name: 'sync');
```

### 2. Validate the server base URL before use
`AppConstants.defaultBaseUrl` and the user-supplied URL from SharedPreferences are the
only network targets. Before applying a new base URL:
- Assert it starts with `https://` in release builds.
- Reject empty strings and bare IP addresses without an explicit opt-in flag.
- Never interpolate user-supplied strings directly into path segments.

```dart
// GOOD — Dio serializes query params safely
_dio.get('/occurrences', queryParameters: {'limit': limit});

// BAD — user-controlled value injected into path
_dio.get('/occurrences/${userInput}');
```

### 3. Parameterized queries only
Drift's typed query builder is the default and is always safe.
`customStatement()` is permitted **only** for DDL operations (CREATE INDEX, schema
migrations) using **hardcoded** identifiers — never with runtime/user values.
Never build SQL strings via interpolation.

```dart
// GOOD — Drift type-safe builder
select(tasks)..where((t) => t.id.equals(localId))

// GOOD — DDL with hardcoded table name constant
await customStatement('CREATE UNIQUE INDEX IF NOT EXISTS idx_${t}_server_id ON $t(server_id)');

// BAD — never do this
await customStatement('SELECT * FROM tasks WHERE title = "$userInput"');
```

### 4. Force HTTPS for API traffic
All API calls go through `ApiClient`. The base URL must use `https://` in production.
Do not disable certificate verification (`badCertificateCallback`) for any release build.
If adding a self-signed cert option for development, gate it behind a debug-only flag.

### 5. Protect sensitive fields in the local database
The SQLite database is unencrypted (acceptable for this use case) but treat it accordingly:
- Do not store raw credentials, full card PANs, or auth tokens in any Drift table.
- `lastFour` (last 4 digits only) is acceptable.
- If authentication headers are added to `ApiClient` in the future, store tokens in
  `flutter_secure_storage`, not `SharedPreferences`.

### 6. Validate URL Launcher targets
Before calling `url_launcher`, check the scheme is `https://` or a known deep-link
scheme. Never launch an arbitrary URL from server-provided data without validation.

### 7. Error messages must not leak implementation details
Errors surfaced to the user (via `SyncResult.errors`, SnackBars, dialogs) should
describe *what failed*, not internal stack traces or raw SQL errors.
`_dioErrorDetail` in `SyncService` already sanitizes API errors — follow the same
pattern for DB errors.

### 8. Exhaustive enum switches
All `switch` on `SyncStatus` must be exhaustive (no `default` fallthrough).
The Dart compiler enforces this when switching on sealed classes/enums without a
`default` case — rely on this, never suppress the warning.

---

## Dart / Flutter Best Practices

### Code style
- Use `const` constructors wherever the widget tree is fixed.
- Prefer `final` over `var`; use `late` only when initialization truly cannot be
  eager.
- No `dynamic` types in new code. Use explicit generics (`List<Task>`, not `List`).
- Use `sealed class` or exhaustive `enum` for domain states (see `SyncStatus`).

### State management (Riverpod)
- Keep providers small and focused; one provider per concern.
- Use `AsyncNotifier` / `StreamNotifier` for async state — never raw `StateProvider`
  holding a `Future`.
- Providers that need the database or API client must receive them via `ref.watch`,
  not by constructing singletons inside the provider.

### Database (Drift)
- All schema changes require a `schemaVersion` bump and a matching `onUpgrade` branch.
- Write idempotent migrations (use `IF NOT EXISTS`, `IF EXISTS`, etc.).
- Batch writes (`db.batch(...)`) for bulk upserts — never loop individual inserts.
- Use `transaction()` when multiple tables must be updated atomically
  (see `replaceTrackerCache`).

### Networking (Dio)
- All API calls are in `ApiClient` — no Dio usage in screens or providers.
- Set explicit `connectTimeout` and `receiveTimeout` on the `BaseOptions`.
- Add a Dio interceptor for auth headers if authentication is introduced, rather than
  adding headers at each call site.
- Catch `DioException` specifically; let unexpected exceptions propagate or be caught
  at the top-level sync boundary.

### Sync layer
- `SyncService.fullRefresh()` and `pushPending()` are the only public entry points;
  keep screens decoupled from raw API/DB calls.
- Orphan purge logic (delete local rows no longer on the server) must run *after* the
  upsert so foreign keys are never violated.
- Log each orphan purge at debug level before deleting; this aids incident diagnosis.

### Testing
- Widget tests go in `test/`; use `flutter test`.
- Mock `ApiClient` and `AppDatabase` with `mockito` or `mocktail` — do not hit real
  network or disk in unit/widget tests.
- For Drift, use an in-memory database (`NativeDatabase.memory()`) in tests.

---

## What Not To Do

- Do not add `print()` anywhere — use `dart:developer` `log()`.
- Do not store secrets or tokens in `SharedPreferences`.
- Do not introduce `dynamic` typed API responses — always parse through the
  `ApiModels` layer.
- Do not bypass Riverpod and reach into `AppDatabase` directly from widget code.
- Do not commit generated files (`*.g.dart`, `build/`) — they are produced by
  `build_runner`.
- Do not disable lint rules project-wide in `analysis_options.yaml`; suppress
  per-line with a comment only when there is a documented reason.
