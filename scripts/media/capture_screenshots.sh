#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_PATH="${PROJECT_PATH:-$ROOT_DIR/ZoneClock.xcodeproj}"
SCHEME="${SCHEME:-ZoneClock}"
APP_BUNDLE_ID="${APP_BUNDLE_ID:-ai.e6.zonesync}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.build/media-derived}"
CAPTURE_DELAY="${CAPTURE_DELAY:-5}"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
OUTPUT_ROOT="${OUTPUT_ROOT:-$ROOT_DIR/screenshots/generated/$TIMESTAMP}"
IPHONE_OUTPUT="$OUTPUT_ROOT/iphone-6.9"
IPAD_OUTPUT="$OUTPUT_ROOT/ipad-13"

mkdir -p "$IPHONE_OUTPUT" "$IPAD_OUTPUT"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

prepare_project() {
  if [[ -f "$ROOT_DIR/project.yml" ]]; then
    require_command xcodegen
    xcodegen generate --spec "$ROOT_DIR/project.yml" >/dev/null
  fi

  if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "Could not find project at $PROJECT_PATH" >&2
    exit 1
  fi
}

find_udid_by_names() {
  local names=("$@")
  local devices
  devices="$(xcrun simctl list devices available)"

  for name in "${names[@]}"; do
    local line
    line="$(printf '%s\n' "$devices" | rg -F "$name (" | head -n 1 || true)"
    if [[ -n "$line" ]]; then
      printf '%s\n' "$line" | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/'
      return 0
    fi
  done

  return 1
}

boot_and_prepare_device() {
  local udid="$1"

  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$udid" -b

  xcrun simctl ui "$udid" appearance light >/dev/null 2>&1 || true
  xcrun simctl status_bar "$udid" override \
    --time 9:41 \
    --batteryState charged \
    --batteryLevel 100 \
    --cellularMode active \
    --cellularBars 4 \
    --wifiMode active \
    --wifiBars 3 >/dev/null 2>&1 || true
}

build_app_once() {
  local destination_udid="$1"

  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$destination_udid" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    build >/dev/null

  APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/ZoneClock.app"
  if [[ ! -d "$APP_PATH" ]]; then
    echo "Built app not found at $APP_PATH" >&2
    exit 1
  fi
}

launch_and_capture() {
  local udid="$1"
  local screen="$2"
  local output_file="$3"
  local reset_flag="$4"

  xcrun simctl terminate "$udid" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true

  if [[ "$reset_flag" == "yes" ]]; then
    xcrun simctl launch "$udid" "$APP_BUNDLE_ID" -media-mode -media-reset -media-tab "$screen" >/dev/null
  else
    xcrun simctl launch "$udid" "$APP_BUNDLE_ID" -media-mode -media-tab "$screen" >/dev/null
  fi

  sleep "$CAPTURE_DELAY"
  xcrun simctl io "$udid" screenshot "$output_file" >/dev/null
  echo "Captured $output_file"
}

capture_device_set() {
  local udid="$1"
  local output_dir="$2"

  xcrun simctl uninstall "$udid" "$APP_BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl install "$udid" "$APP_PATH" >/dev/null

  local first_run="yes"

  launch_and_capture "$udid" "home" "$output_dir/01-timeline.png" "$first_run"
  first_run="no"
  launch_and_capture "$udid" "add-person" "$output_dir/02-add-person.png" "$first_run"
  launch_and_capture "$udid" "teams" "$output_dir/03-teams.png" "$first_run"
  launch_and_capture "$udid" "edit-person" "$output_dir/04-edit-person.png" "$first_run"
  launch_and_capture "$udid" "timezone-picker" "$output_dir/05-timezone-picker.png" "$first_run"
}

cleanup_status_bar() {
  local udid="$1"
  xcrun simctl status_bar "$udid" clear >/dev/null 2>&1 || true
}

main() {
  require_command xcrun
  require_command xcodebuild
  require_command rg
  prepare_project

  local iphone_udid
  local ipad_udid

  iphone_udid="$(find_udid_by_names \
    "iPhone 16 Pro Max" \
    "iPhone 15 Pro Max" \
    "iPhone 14 Pro Max")" || {
      echo "Could not find an available iPhone Pro Max simulator." >&2
      exit 1
    }

  ipad_udid="$(find_udid_by_names \
    "iPad Pro 13-inch (M4)" \
    "iPad Pro (13-inch) (M4)" \
    "iPad Pro (12.9-inch) (6th generation)")" || {
      echo "Could not find an available iPad Pro simulator." >&2
      exit 1
    }

  echo "Using iPhone UDID: $iphone_udid"
  echo "Using iPad UDID:   $ipad_udid"

  boot_and_prepare_device "$iphone_udid"
  boot_and_prepare_device "$ipad_udid"

  build_app_once "$iphone_udid"

  capture_device_set "$iphone_udid" "$IPHONE_OUTPUT"
  capture_device_set "$ipad_udid" "$IPAD_OUTPUT"

  cleanup_status_bar "$iphone_udid"
  cleanup_status_bar "$ipad_udid"

  echo
  echo "Screenshots generated at:"
  echo "- $IPHONE_OUTPUT"
  echo "- $IPAD_OUTPUT"
}

main "$@"
