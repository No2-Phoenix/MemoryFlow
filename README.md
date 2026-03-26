# MemoryFlow

MemoryFlow is a Flutter-based immersive photo story player.
It helps users turn photos, captions, and memory metadata into flowing visual stories with music.

Main project folder: `memoryflow/`

## Features

### Story creation and editing
- Create and edit stories with title, date, location, and caption.
- Pick a cover image and persist it locally.
- Read EXIF metadata (time/location when available).
- Adjust cover blur strength for each story.

### Immersive playback
- Full-screen story playback stage on Home.
- Text playback modes:
  - Lyrics flow
  - Subtitle style
  - Credits roll
  - Typewriter
- Global background music switch and custom music upload.
- Top meta line for date/location display.

### Overview and navigation
- Timeline overview of stories.
- Tap any story card to jump to that story.

### Data management
- Local persistent storage for stories and assets.
- One-click export/import for backup and migration.
- Delete current story or clear all user stories.

### Performance optimization
- Adaptive low-effects mode for lower-end devices.
- Reduced heavy visual effects under frame-pressure.
- Lightweight thumbnail rendering in overview for smoother scrolling.

## Tech stack

- Flutter `3.41.5` (recommended)
- Dart `3.11.x`
- Riverpod, GoRouter, Isar-like local persistence abstraction
- Android split APK build support

## Quick start

```bash
cd memoryflow
flutter pub get
flutter run
```

## Quality checks

```bash
cd memoryflow
flutter analyze
flutter test
```

## Android build

### Universal APK

```bash
cd memoryflow
flutter build apk --release
```

### Split APKs (recommended)

```bash
cd memoryflow
flutter build apk --release --split-per-abi
```

Build output:

`memoryflow/build/app/outputs/flutter-apk/`

- `app-arm64-v8a-release.apk` (most modern Android phones)
- `app-armeabi-v7a-release.apk` (older 32-bit phones)
- `app-x86_64-release.apk` (emulator / x86_64 devices)

## iOS note

- The repo includes a GitHub Actions iOS build workflow.
- App Store / distributable IPA still requires Apple signing assets.
- Without a paid Apple Developer account, only limited personal-device testing is generally possible.

## Project structure

```text
MemoryFlow/
- memoryflow/
  - lib/
    - core/                    # theme, router, storage, database
    - features/
      - home/                  # player stage, text modes, overview, settings
      - editor/                # story creator/editor
      - extensions/            # extra utility pages
    - shared/                  # reusable UI building blocks
  - assets/
  - android/
  - ios/
- .github/workflows/           # CI/CD
```

## Known notes

- Some photos do not include EXIF location data, so location may need manual input.
- File/media permission behavior differs by Android vendor ROM; verify permissions if picking files fails.
