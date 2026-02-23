#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APPSTORE_MEDIA_DIR="$ROOT_DIR/appstore/media"
SCREENSHOT_ROOT="$ROOT_DIR/screenshots/generated"
VIDEO_ROOT="$ROOT_DIR/videos/generated"

if [[ ! -d "$SCREENSHOT_ROOT" || ! -d "$VIDEO_ROOT" ]]; then
  echo "Could not find generated screenshots/videos. Run capture scripts first." >&2
  exit 1
fi

LATEST_SCREENSHOT_DIR="$(find "$SCREENSHOT_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
LATEST_VIDEO_DIR="$(find "$VIDEO_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"

if [[ -z "${LATEST_SCREENSHOT_DIR:-}" || -z "${LATEST_VIDEO_DIR:-}" ]]; then
  echo "Could not find generated screenshots/videos. Run capture scripts first." >&2
  exit 1
fi

mkdir -p "$APPSTORE_MEDIA_DIR"

cp "$LATEST_SCREENSHOT_DIR/iphone-6.9/01-timeline.png" "$APPSTORE_MEDIA_DIR/iphone-01-timeline.png"
cp "$LATEST_SCREENSHOT_DIR/iphone-6.9/02-add-person.png" "$APPSTORE_MEDIA_DIR/iphone-02-add-person.png"
cp "$LATEST_SCREENSHOT_DIR/iphone-6.9/03-teams.png" "$APPSTORE_MEDIA_DIR/iphone-03-teams.png"
cp "$LATEST_SCREENSHOT_DIR/iphone-6.9/04-edit-person.png" "$APPSTORE_MEDIA_DIR/iphone-04-edit-person.png"
cp "$LATEST_SCREENSHOT_DIR/iphone-6.9/05-timezone-picker.png" "$APPSTORE_MEDIA_DIR/iphone-05-timezone-picker.png"

cp "$LATEST_SCREENSHOT_DIR/ipad-13/01-timeline.png" "$APPSTORE_MEDIA_DIR/ipad-01-timeline.png"
cp "$LATEST_SCREENSHOT_DIR/ipad-13/02-add-person.png" "$APPSTORE_MEDIA_DIR/ipad-02-add-person.png"
cp "$LATEST_SCREENSHOT_DIR/ipad-13/03-teams.png" "$APPSTORE_MEDIA_DIR/ipad-03-teams.png"
cp "$LATEST_SCREENSHOT_DIR/ipad-13/04-edit-person.png" "$APPSTORE_MEDIA_DIR/ipad-04-edit-person.png"
cp "$LATEST_SCREENSHOT_DIR/ipad-13/05-timezone-picker.png" "$APPSTORE_MEDIA_DIR/ipad-05-timezone-picker.png"

cp "$LATEST_VIDEO_DIR/iphone-6.9/zoneclock-app-preview.mp4" "$APPSTORE_MEDIA_DIR/iphone-app-preview.mp4"
cp "$LATEST_VIDEO_DIR/ipad-13/zoneclock-app-preview.mp4" "$APPSTORE_MEDIA_DIR/ipad-app-preview.mp4"

echo "Synced latest media to $APPSTORE_MEDIA_DIR"
