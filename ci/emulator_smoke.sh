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

# Animations must be ON: the motion is what is being tested.
for k in window_animation_scale transition_animation_scale animator_duration_scale; do
  adb -s "$DEVICE" shell settings put global $k 1.0
done
echo "animation scales: $(adb -s "$DEVICE" shell settings get global animator_duration_scale) $(adb -s "$DEVICE" shell settings get global transition_animation_scale)" >> "$EVID/events.txt"

# A screen recording of the test itself (so the motion can be checked frame
# by frame). It starts once the app is running, in 170-second pieces.
(
  until grep -q "SMOKE" "$EVID/test.log" 2>/dev/null; do sleep 1; done
  echo "recording started $(date +%H:%M:%S)" >> "$EVID/events.txt"
  for i in 1 2 3 4; do
    adb -s "$DEVICE" shell screenrecord --time-limit 170 --size 540x1170 "/sdcard/rec_$i.mp4"
  done
) &
REC_PID=$!

cd packages/smooth_app
flutter test integration_test/halalpal_smoke_test.dart -d "$DEVICE" 2>&1 | tee "$EVID/test.log"
RESULT=${PIPESTATUS[0]}

kill "$SHOT_PID" "$GRANT_PID" "$REC_PID" 2>/dev/null || true
# Stop the recorder cleanly so the video file is complete, then collect it.
adb -s "$DEVICE" shell "pkill -SIGINT screenrecord" || true
sleep 4
adb -s "$DEVICE" pull /sdcard/ "$EVID/recordings" >/dev/null 2>&1 || true
rm -rf "$EVID/recordings/Android" 2>/dev/null || true
adb -s "$DEVICE" logcat -d -s flutter:V AndroidRuntime:E > "$EVID/app_log.txt" || true
echo "test exit code: $RESULT" | tee -a "$EVID/events.txt"
exit "$RESULT"
