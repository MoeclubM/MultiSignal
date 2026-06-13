# Android platform notes

Generate native Android files with:

```bash
flutter create . --platforms=android
```

Then add the required permissions and USB host features to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-feature android:name="android.hardware.usb.host" />
```

For USB serial auto-detection, create `android/app/src/main/res/xml/device_filter.xml` and wire it through the usb_serial package metadata. Add vendor/product IDs for target CH340, FTDI, CP210x, and CDC ACM devices used in deployment.
