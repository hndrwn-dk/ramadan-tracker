#!/usr/bin/env bash
# Capture notification/R8-related logcat lines for the R8 optimization device test.
# Usage (from repo root): ./scripts/notif-watch.sh
set -euo pipefail

mkdir -p artifacts/test
LOG="artifacts/test/logcat-$(date +%Y%m%d-%H%M%S).log"

echo "Writing to $LOG (Ctrl-C to stop)"
adb logcat -v time | grep --line-buffered -iE \
  "Gson path failed|JSONObject fallback|Notification shown via Gson path|Missing type parameter|flutterlocalnotifications" \
  | tee -a "$LOG"
