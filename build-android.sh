#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODE="${1:-release}"   # release | debug | profile
BUNDLE="${2:-apk}"     # apk | appbundle

echo "==> Flutter pub get"
flutter pub get

echo "==> Drift code generation"
flutter pub run build_runner build --delete-conflicting-outputs

echo "==> Building Android $BUNDLE ($MODE)"
flutter build "$BUNDLE" "--$MODE"

if [[ "$BUNDLE" == "apk" ]]; then
    OUT="build/app/outputs/flutter-apk/app-$MODE.apk"
else
    OUT="build/app/outputs/bundle/${MODE}/app-${MODE}.aab"
fi

echo ""
echo "Done: $SCRIPT_DIR/$OUT"
echo "Size: $(du -sh "$OUT" | cut -f1)"
