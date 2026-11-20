#!/usr/bin/env bash
# Runs the smoke test on the Android emulator started by the CI action, and
# collects evidence (screenshots every few seconds, test log, app log).
# Exits with the test's result.
set -uo pipefail

export PATH="$PATH:${ANDROID_HOME:-$ANDROID_SDK_ROOT}/platform-tools"
export ORG_GRADLE_PROJECT_minSdk=26

APP_ID=com.intelisenselabs.halalpal
EVID="$GITHUB_WORKSPACE/evidence"
mkdir -p "$EVID"

adb wait-for-device
adb shell input keyevent 82 || true
adb logcat -c || true
DEVICE=$(adb devices | awk '/^emulator-/{print $1; exit}')
echo "Emulator: $DEVICE"
adb -s "$DEVICE" shell getprop ro.build.version.sdk > "$EVID/android_sdk.txt" || true

# flutter test installs the app; give it the camera permission the moment it
# exists, so the Scan screen takes the same path as on a phone.
(
  for _ in $(seq 1 900); do
    if adb -s "$DEVICE" shell pm list packages 2>/dev/null | grep -q "$APP_ID"; then
      if adb -s "$DEVICE" shell pm grant "$APP_ID" android.permission.CAMERA; then
        echo "camera permission granted $(date +%H:%M:%S)" >> "$EVID/events.txt"
        break
      fi
    fi
    sleep 2
  done
) &
GRANT_PID=$!

# A screenshot every 5 seconds, named with the time so it matches the log.
(
  while true; do
    adb -s "$DEVICE" exec-out screencap -p > "$EVID/shot_$(date +%H%M%S).png" 2>/dev/null
    sleep 5
  done
) &
SHOT_PID=$!

cd packages/smooth_app
flutter test integration_test/halalpal_smoke_test.dart -d "$DEVICE" 2>&1 | tee "$EVID/test.log"
RESULT=${PIPESTATUS[0]}

kill "$SHOT_PID" "$GRANT_PID" 2>/dev/null || true
adb -s "$DEVICE" logcat -d -s flutter:V AndroidRuntime:E > "$EVID/app_log.txt" || true
echo "test exit code: $RESULT" | tee -a "$EVID/events.txt"
exit "$RESULT"
