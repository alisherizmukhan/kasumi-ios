#!/bin/bash
# Launches the app on each demo screen and saves a simulator screenshot.
# Usage: scripts/screenshots.sh <simulator-udid> <output-dir>
set -euo pipefail

UDID="$1"
OUT="${2:-screenshots}"
APP="build/Build/Products/Debug-iphonesimulator/Kasumi.app"
BUNDLE_ID="com.alisherizmukhan.Kasumi"
SCREENS="onboarding auth home preset create library detail profile store purchased paywall billing settings"

mkdir -p "$OUT"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4 || true
xcrun simctl ui "$UDID" appearance dark || true
xcrun simctl install "$UDID" "$APP"

for screen in $SCREENS; do
  xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" -demoScreen "$screen"
  sleep 9
  xcrun simctl io "$UDID" screenshot "$OUT/$screen.png"
  echo "captured $screen"
done
