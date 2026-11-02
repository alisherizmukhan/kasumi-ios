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

# iPhone Duo has two displays (inner and outer); simctl then needs --display.
# Ask once which displays exist: "id:name" pairs, empty on single-display devices.
DISPLAYS=$(xcrun simctl io "$UDID" screenshot /tmp/kasumi-probe.png 2>&1 \
  | sed -nE 's/.*--display=([0-9]+)[[:space:]]+([^[:space:]]+).*/\1:\2/p' || true)
echo "displays: ${DISPLAYS:-single}"

for screen in $SCREENS; do
  xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" -demoScreen "$screen"
  sleep 9
  if [ -z "$DISPLAYS" ]; then
    xcrun simctl io "$UDID" screenshot "$OUT/$screen.png"
  else
    for display in $DISPLAYS; do
      xcrun simctl io "$UDID" screenshot --display="${display%%:*}" "$OUT/$screen-${display#*:}.png" || true
    done
  fi
  echo "captured $screen"
done
