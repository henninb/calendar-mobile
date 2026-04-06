#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODE="${1:-release}"   # release | debug | profile

echo "==> Flutter pub get"
flutter pub get

echo "==> Drift code generation"
flutter pub run build_runner build --delete-conflicting-outputs

echo "==> Building Linux ($MODE)"
flutter build linux "--$MODE"

OUT="build/linux/x64/$MODE/bundle"
BIN="$OUT/calendar_mobile"

echo "==> Running $BIN"
"./$BIN"
