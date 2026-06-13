# Windows platform notes

Generate native Windows files with:

```bash
flutter create . --platforms=windows
```

Install the USB-UART device driver for your hardware if Windows does not expose it as a COM port. `flutter_libserialport` enumerates available COM ports through libserialport.
