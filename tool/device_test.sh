#!/usr/bin/env bash
# Runs the integration test on a connected device or running emulator, twice:
#   1. with the runtime permissions revoked -> the plugin must return null
#   2. with the runtime permissions granted -> the plugin must return JSON matching the contract
#
# Usage: tool/device_test.sh [device-id]      (device id as printed by `adb devices`)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
app_id="com.specure.nettest.cell_info_example"
permissions=(ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION READ_PHONE_STATE)

device="${1:-$(adb devices | awk 'NR > 1 && $2 == "device" { print $1; exit }')}"
if [[ -z "$device" ]]; then
  echo "No device found. Connect one or start an emulator (flutter emulators --launch <id>)." >&2
  exit 1
fi
echo "==> Using device $device"

# $1 = granted | denied: the permission state the test must find, so a pass can never
# silently check the wrong half of the contract.
run_test() {
  # --no-uninstall: by default `flutter test` removes the app afterwards, and with it the grants.
  (cd "$root/example" && flutter test integration_test -d "$device" --no-uninstall \
    --dart-define=EXPECT_PERMISSIONS="$1")
}

is_granted() {
  adb -s "$device" shell dumpsys package "$app_id" | grep -q "android.permission.$1: granted=true"
}

echo "==> Pass 1: permissions revoked"
for permission in "${permissions[@]}"; do
  # Fails harmlessly when the app is not installed yet (a fresh install has no permissions).
  adb -s "$device" shell pm revoke "$app_id" "android.permission.$permission" >/dev/null 2>&1 || true
done
run_test denied

echo "==> Pass 2: permissions granted"
for permission in "${permissions[@]}"; do
  adb -s "$device" shell pm grant "$app_id" "android.permission.$permission"
  # `adb shell pm grant` exits with 0 even when it fails, so check the result.
  if ! is_granted "$permission"; then
    echo "Could not grant $permission to $app_id on $device" >&2
    exit 1
  fi
done
run_test granted

echo "==> Device checks passed (the example app stays installed with permissions granted)"
