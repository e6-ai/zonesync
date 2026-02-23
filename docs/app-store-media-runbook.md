# App Store Media Runbook

## Prerequisites

- Xcode + iOS simulators (iPhone Pro Max + iPad Pro 13")
- `ffmpeg` and `ffprobe` in `PATH`
- `xcodegen` in `PATH` (scripts regenerate `ZoneClock.xcodeproj` from `project.yml`)

## 1. Generate screenshots

```bash
./scripts/media/capture_screenshots.sh
```

Output folder:

- `screenshots/generated/<timestamp>/iphone-6.9`
- `screenshots/generated/<timestamp>/ipad-13`

Generated screenshots:

1. `01-timeline.png`
2. `02-add-person.png`
3. `03-teams.png`
4. `04-edit-person.png`
5. `05-timezone-picker.png`

## 2. Generate app preview videos

```bash
./scripts/media/record_app_previews.sh
```

Output folder:

- `videos/generated/<timestamp>/iphone-6.9/zoneclock-app-preview.mp4`
- `videos/generated/<timestamp>/ipad-13/zoneclock-app-preview.mp4`

Default duration is 28 seconds. Override with:

```bash
VIDEO_DURATION_SECONDS=25 ./scripts/media/record_app_previews.sh
```

## 3. Sync latest generated media to appstore upload folder

```bash
./scripts/media/sync_latest_to_appstore.sh
```

This copies the most recent screenshot/video outputs into `appstore/media` using stable upload filenames.

## 4. How media mode works

The scripts launch the app with simulator-only arguments:

- `-media-mode`
- `-media-tab <home|add-person|teams|edit-person|timezone-picker>`
- `-media-video` (auto screen transitions for preview recordings)
- `-media-reset` (wipe and reseed demo data)

This creates deterministic demo data and stable capture surfaces for App Store assets.
