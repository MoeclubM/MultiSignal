# Linux platform notes

Generate native Linux files with:

```bash
flutter create . --platforms=linux
```

Make sure the user has permission to access serial devices, for example by joining the distribution-specific `dialout`, `uucp`, or `tty` group. Desktop camera recording may require GStreamer and V4L2 runtime packages depending on the camera plugin backend.
