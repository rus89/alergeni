#!/usr/bin/env bash
# ABOUTME: Shell script that automates Play Store screenshot capture across 3 Android emulators.
# ABOUTME: Manages AVD lifecycle: boot, capture, shutdown. Writes PNGs to assets/screenshots/raw/.

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
SYSTEM_IMAGE="system-images;android-34;google_apis;arm64-v8a"

avd_name_for() {
  case "$1" in
    phone)     echo "screenshot_phone" ;;
    tablet_7)  echo "screenshot_tablet_7" ;;
    tablet_10) echo "screenshot_tablet_10" ;;
  esac
}

# ---------------------------------------------------------------------------
# --setup: create AVDs idempotently
# ---------------------------------------------------------------------------
cmd_setup() {
  echo "NOTE: The system image must be installed before creating AVDs. Run:"
  echo "  sdkmanager \"${SYSTEM_IMAGE}\""
  echo ""

  avdmanager list avd | grep -q "screenshot_phone" || \
    avdmanager create avd -n "screenshot_phone" -k "${SYSTEM_IMAGE}" -d "pixel_7"

  avdmanager list avd | grep -q "screenshot_tablet_7" || \
    avdmanager create avd -n "screenshot_tablet_7" -k "${SYSTEM_IMAGE}" -d "Nexus 7 2013"

  avdmanager list avd | grep -q "screenshot_tablet_10" || \
    avdmanager create avd -n "screenshot_tablet_10" -k "${SYSTEM_IMAGE}" -d "pixel_tablet"

  echo "AVD setup complete."
}

# ---------------------------------------------------------------------------
# Pre-flight checks: API reachability and off-season warning
# ---------------------------------------------------------------------------
preflight_checks() {
  if ! curl -s --max-time 5 "http://77.46.150.200/api/opendata/locations/" -o /dev/null; then
    echo "WARNING: API endpoint is unreachable. Screenshots may show error states."
  fi

  local month
  month=$(printf '%d' "$(date +%m)")
  if [ "$month" -eq 10 ] || [ "$month" -eq 11 ] || [ "$month" -eq 12 ] || [ "$month" -eq 1 ]; then
    echo "WARNING: Current month is off-season. The app may show the off-season dialog."
  fi
}

# ---------------------------------------------------------------------------
# Run screenshot capture for a single device key (phone | tablet_7 | tablet_10)
# ---------------------------------------------------------------------------
run_device() {
  local device_key="$1"
  local avd_name
  avd_name=$(avd_name_for "$device_key")
  local device_name="$device_key"

  echo ""
  echo "=== Processing device: ${device_name} (AVD: ${avd_name}) ==="

  # Boot emulator in background; save PID for cleanup trap.
  # Assumes no other emulators are running — head -1 picks the first emulator serial,
  # which will be this one if the machine is otherwise idle.
  emulator -avd "${avd_name}" &
  local EMULATOR_PID=$!

  # Kill the emulator process if the script exits early (set -e or signal).
  # The trap is removed after a clean shutdown below.
  trap "kill $EMULATOR_PID 2>/dev/null || true" EXIT

  # Poll until an emulator-XXXX serial appears in adb devices (2-minute timeout).
  # adb wait-for-device returns for any transport (including non-emulator devices),
  # so we poll for an emulator serial directly.
  local DEVICE_ID=""
  local appear_waited=0
  while [ -z "$DEVICE_ID" ]; do
    sleep 3
    appear_waited=$((appear_waited + 3))
    DEVICE_ID=$(adb devices | grep 'emulator-' | head -1 | awk '{print $1}')
    if [ "$appear_waited" -ge 120 ] && [ -z "$DEVICE_ID" ]; then
      echo "ERROR: Emulator did not appear in adb devices within 2 minutes"
      exit 1
    fi
  done

  echo "Detected emulator: ${DEVICE_ID}. Waiting for full Android boot..."

  # Wait for Android to finish booting (sys.boot_completed = 1), 5-minute timeout.
  local waited=0
  until adb -s "$DEVICE_ID" shell getprop sys.boot_completed 2>/dev/null | grep -q '1'; do
    sleep 3
    waited=$((waited + 3))
    if [ "$waited" -ge 300 ]; then
      echo "ERROR: Emulator ${DEVICE_ID} did not boot within 5 minutes"
      adb -s "$DEVICE_ID" emu kill 2>/dev/null || true
      exit 1
    fi
  done

  echo "Device ${DEVICE_ID} fully booted. Running flutter drive..."

  # Run the screenshot driver test with the device name injected via env var.
  # --no-enable-impeller: convertFlutterSurfaceToImage() (required for screenshots)
  # does not work with Impeller — must use the Skia backend for this run.
  SCREENSHOT_DEVICE_NAME="$device_name" flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/screenshot_test.dart \
    --no-enable-impeller \
    -d "$DEVICE_ID"

  echo "flutter drive complete. Shutting down ${DEVICE_ID}..."

  # Gracefully shut down the emulator and wait for it to disappear from adb, 60-second timeout.
  adb -s "$DEVICE_ID" emu kill
  local shutdown_waited=0
  until ! adb devices | grep -q "$DEVICE_ID"; do
    sleep 2
    shutdown_waited=$((shutdown_waited + 2))
    if [ "$shutdown_waited" -ge 60 ]; then
      echo "WARNING: Emulator ${DEVICE_ID} did not stop within 60 seconds, continuing"
      break
    fi
  done

  # Clean shutdown completed; remove the emergency exit trap.
  trap - EXIT

  echo "Device ${DEVICE_ID} stopped."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local arg="${1:-}"

  if [ "$arg" = "--setup" ]; then
    cmd_setup
    exit 0
  fi

  preflight_checks

  if [ -z "$arg" ]; then
    # Default: run all devices
    run_device "phone"
    run_device "tablet_7"
    run_device "tablet_10"
  elif [ "$arg" = "phone" ] || [ "$arg" = "tablet_7" ] || [ "$arg" = "tablet_10" ]; then
    run_device "$arg"
  else
    echo "Usage: $0 [--setup | phone | tablet_7 | tablet_10]"
    echo "  (no argument) — runs all three devices"
    exit 1
  fi

  echo ""
  echo "Screenshot capture complete."
}

main "$@"
