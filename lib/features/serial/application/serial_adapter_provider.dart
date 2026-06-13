import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/android_usb_serial_adapter.dart';
import '../data/desktop_serial_adapter.dart';
import '../data/mock_serial_adapter.dart';
import '../domain/serial_port_adapter.dart';

final serialPortAdapterProvider = Provider<SerialPortAdapter>((ref) {
  if (Platform.isAndroid) return const AndroidUsbSerialAdapter();
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return const DesktopSerialAdapter();
  }
  return const MockSerialAdapter();
});
