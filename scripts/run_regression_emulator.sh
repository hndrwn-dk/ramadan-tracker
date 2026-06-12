#!/usr/bin/env bash
# Run emulator regression tests with a seeded Ramadan + Syawal simulation.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> flutter pub get"
flutter pub get

echo "==> Unit regression (seeder + layout)"
flutter test test/regression_seeder_test.dart test/regression_layout_test.dart --reporter expanded

DEVICE="${REGRESSION_DEVICE:-}"
if [ -z "$DEVICE" ]; then
  DEVICE="$(flutter devices 2>/dev/null | grep -E 'emulator-[0-9]+' -o | head -1 || true)"
fi
if [ -z "$DEVICE" ]; then
  DEVICE="$(flutter devices 2>/dev/null | awk -F'•' '/android/ { gsub(/ /, "", $2); print $2; exit }' || true)"
fi

if [ -z "$DEVICE" ]; then
  echo ""
  echo "ERROR: No Android emulator/device found."
  echo "Start an AVD, then rerun. Or set REGRESSION_DEVICE=emulator-5554"
  exit 1
fi

PKG=com.tursinalabs.ramadan.tracker

echo "==> Integration regression on device: $DEVICE"

if command -v adb >/dev/null 2>&1; then
  echo "==> Clearing app data for clean seeded run"
  adb -s "$DEVICE" shell pm clear "$PKG" 2>/dev/null || true
  adb -s "$DEVICE" shell am force-stop "$PKG" 2>/dev/null || true
  adb -s "$DEVICE" shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
  adb -s "$DEVICE" shell pm grant "$PKG" android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
  adb -s "$DEVICE" shell pm grant "$PKG" android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
fi

flutter test integration_test/regression_emulator_test.dart \
  -d "$DEVICE" \
  --dart-define=REGRESSION_SEED=true \
  --reporter expanded

echo "==> Regression finished OK"
