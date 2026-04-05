#!/usr/bin/env bash

# Keep this file public so users can see the intended actions.
# The website reads manifest.json for machine-readable package URLs and execution metadata.

set -euo pipefail

APK_URL="https://raw.githubusercontent.com/notg700owner/g700-clock-weather-overlay/main/update/g700-clock-weather-release.apk"
APK_NAME="g700-clock-weather-release.apk"
PACKAGE="com.g700.clockweather"
OLD_PACKAGE="com.g700.automation"

echo "== Install =="
adb uninstall "$OLD_PACKAGE" >/dev/null 2>&1 || true
curl -fL "$APK_URL" -o "$APK_NAME"
adb install -r "$APK_NAME"
sleep 2

echo "== Grant / appops =="
adb shell pm grant "$PACKAGE" android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
adb shell pm grant "$PACKAGE" android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
adb shell pm grant "$PACKAGE" android.permission.POST_NOTIFICATIONS 2>/dev/null || true
adb shell pm grant "$PACKAGE" android.permission.ACCESS_BACKGROUND_LOCATION 2>/dev/null || true

adb shell appops set "$PACKAGE" ACCESS_BACKGROUND_LOCATION allow 2>/dev/null || true
adb shell appops set "$PACKAGE" POST_NOTIFICATION allow 2>/dev/null || true
adb shell appops set "$PACKAGE" REQUEST_INSTALL_PACKAGES allow 2>/dev/null || true
adb shell appops set "$PACKAGE" SYSTEM_ALERT_WINDOW allow 2>/dev/null || true

adb shell dumpsys deviceidle whitelist +"$PACKAGE" 2>/dev/null || true

echo "== Launch =="
adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
sleep 3

echo "== Verify =="
echo "[package]"
adb shell pm list packages | grep -F "$PACKAGE" || echo "NOT INSTALLED"

echo "[requested/granted permissions]"
adb shell dumpsys package "$PACKAGE" | grep -E "android.permission.(ACCESS_COARSE_LOCATION|ACCESS_FINE_LOCATION|ACCESS_BACKGROUND_LOCATION|POST_NOTIFICATIONS|REQUEST_INSTALL_PACKAGES|REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)|android.car.permission.CAR_EXTERIOR_ENVIRONMENT" || true

echo "[appops]"
adb shell appops get "$PACKAGE" 2>/dev/null | grep -E "ACCESS_BACKGROUND_LOCATION|POST_NOTIFICATION|REQUEST_INSTALL_PACKAGES|SYSTEM_ALERT_WINDOW" || echo "No matching appops shown"

echo "[receiver/service]"
adb shell dumpsys package "$PACKAGE" | grep -E "BootReceiver|AutomationForegroundService|MAIN|LAUNCHER" || true

echo "[process]"
adb shell pidof "$PACKAGE" || echo "Process not running"

echo "[activity/service snapshot]"
adb shell dumpsys activity services | grep -A 20 -B 5 "$PACKAGE" || true

echo "== Done =="
