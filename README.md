# calendar-mobile

Offline-first Flutter mobile app that mirrors the [calendar-app](https://calendar.bhenning.com) backend. Data is stored locally in SQLite via Drift and synced to the server when online.

## Features

- **Calendar** — browse occurrences by date using an interactive calendar widget
- **Occurrences** — view and update event occurrences with status and notes
- **Tasks** — manage tasks and subtasks with priorities, due dates, and assignees
- **Credit Cards** — track statement close dates, due dates, and annual fees
- **Offline-first** — all views work without a network connection; mutations are queued and pushed on next sync
- **Sync** — bidirectional sync: full pull from server + push of pending local changes

## Tech Stack

| Layer | Library |
|---|---|
| State management | flutter_riverpod |
| Local database | Drift (SQLite) |
| HTTP client | Dio |
| Connectivity detection | connectivity_plus |
| Calendar widget | table_calendar |
| Settings persistence | shared_preferences |

## Project Structure

```
lib/
  api/
    api_client.dart        # Dio-based HTTP client
    api_models.dart        # API response models
  core/
    constants.dart         # App constants and sync status codes
    theme.dart             # App theme and text styles
  database/
    app_database.dart      # Drift database definition
    app_database.g.dart    # Generated code (do not edit)
  providers/
    providers.dart         # Riverpod providers
  screens/
    calendar_screen.dart
    credit_card_screen.dart
    main_screen.dart
    occurrence_list_screen.dart
    settings_screen.dart
    task_list_screen.dart
  services/
    sync_service.dart      # Pull/push sync logic
  widgets/
    category_badge.dart
    status_badge.dart
    sync_banner.dart
  main.dart
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (SDK constraint: `^3.11.4`)
- Android SDK + platform-tools (`adb` in PATH) for Android deployment
- A running instance of the calendar-app backend (default: `https://calendar.bhenning.com`)

## Getting Started

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

The default backend URL is `https://calendar.bhenning.com`. This can be changed at runtime in the app's Settings screen.

## Building

### Android

```bash
# APK (default: release)
./build-android.sh

# Specific mode
./build-android.sh debug
./build-android.sh release

# App bundle instead of APK
./build-android.sh release appbundle
```

Output: `build/app/outputs/flutter-apk/app-<mode>.apk`

### Linux Desktop

```bash
./build-linux.sh          # release (default)
./build-linux.sh debug
```

Output: `build/linux/x64/<mode>/bundle/calendar_mobile`

## Deploying to an Android Device

```bash
./deploy.sh          # debug (default)
./deploy.sh release
```

The script checks device connectivity before building and gives instructions if the device is not reachable. If the script reports no device found:

1. Connect the phone via USB cable.
2. Swipe down the notification shade and tap the USB notification.
3. Select **PTP (Photo Transfer Protocol)** or **File Transfer**.
4. Enable USB Debugging:
   - Settings > About Phone — tap **Build Number** 7 times.
   - Settings > Developer Options — enable **USB Debugging**.
5. On the **"Allow USB Debugging?"** prompt, tap **Allow**.

## Sync Architecture

`SyncService` performs a two-phase sync:

1. **Pull** — fetches categories, persons, occurrences (±1 month from today), tasks, credit cards, and credit card tracker rows from the server and upserts them into SQLite.
2. **Push** — iterates rows with a non-zero `syncStatus` and applies the pending create/update/delete to the server, then clears the flag locally.

Sync status codes (stored in SQLite):

| Code | Meaning |
|---|---|
| 0 | Synced |
| 1 | Pending create |
| 2 | Pending update |
| 3 | Pending delete |

## Settings

The Settings screen (accessible from the main navigation) exposes:

- **Base URL** — backend endpoint, persisted via `shared_preferences`
- **Sync status** — current sync phase (idle / pushing / pulling / error)
- **Sync Now** — manually trigger a full sync (enabled only when online)
- **Refresh** — pull all data from the server
