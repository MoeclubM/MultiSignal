# macOS platform notes

Generate native macOS files with:

```bash
flutter create . --platforms=macos
```

After generation, add camera and microphone usage descriptions to the macOS entitlements/Info.plist files as required by Flutter camera plugins. Serial access depends on devices exposed under `/dev/cu.*` or `/dev/tty.*`.
