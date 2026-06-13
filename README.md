# MultiSignal

MultiSignal is a Flutter VideoSerial Recorder MVP for synchronized video recording and USB serial data capture on Android and desktop platforms.

## MVP scope

- Android and desktop-oriented Flutter app structure.
- Unified session format: `video.mp4`, `serial_log.csv`, `session_meta.json`.
- Camera-based video recording abstraction.
- Android USB serial and desktop serial adapter abstraction.
- Session list, synchronized playback, import, and export flows.

## Local setup

This repository contains Flutter source and platform placeholders. If Flutter SDK is not installed or not on PATH, install Flutter first, then run:

```bash
flutter create . --platforms=android,windows,macos,linux
flutter pub get
flutter run
```

After native platform files are generated, review Android USB/camera permissions and desktop serial driver requirements for your target hardware.
