import 'dart:async';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart' as usb;

import '../../sessions/domain/serial_config.dart';
import '../domain/serial_connection.dart';
import '../domain/serial_device.dart';
import '../domain/serial_port_adapter.dart';

class AndroidUsbSerialAdapter implements SerialPortAdapter {
  const AndroidUsbSerialAdapter();

  @override
  Future<List<SerialDevice>> listDevices() async {
    final devices = await usb.UsbSerial.listDevices();
    return devices
        .map(
          (device) => SerialDevice(
            id: device.deviceId.toString(),
            label: device.productName ?? device.deviceName,
            manufacturer: device.manufacturerName,
            productName: device.productName,
          ),
        )
        .toList();
  }

  @override
  Future<SerialConnection> connect({
    required SerialDevice device,
    required SerialConfig config,
  }) async {
    final devices = await usb.UsbSerial.listDevices();
    final matched = devices.firstWhere(
      (candidate) => candidate.deviceId.toString() == device.id,
      orElse: () => throw StateError('找不到串口设备：${device.label}'),
    );
    final port = await matched.create();
    if (port == null) throw StateError('无法创建 USB 串口：${device.label}');
    final opened = await port.open();
    if (!opened) throw StateError('无法打开 USB 串口：${device.label}');

    await port.setDTR(true);
    await port.setRTS(true);
    await port.setPortParameters(
      config.baudRate,
      _androidDataBits(config.dataBits),
      _androidStopBits(config.stopBits),
      _androidParity(config.parity),
    );

    return AndroidUsbSerialConnection(port);
  }

  int _androidDataBits(int dataBits) {
    return switch (dataBits) {
      5 => usb.UsbPort.DATABITS_5,
      6 => usb.UsbPort.DATABITS_6,
      7 => usb.UsbPort.DATABITS_7,
      _ => usb.UsbPort.DATABITS_8,
    };
  }

  int _androidStopBits(int stopBits) {
    return switch (stopBits) {
      2 => usb.UsbPort.STOPBITS_2,
      15 => usb.UsbPort.STOPBITS_1_5,
      _ => usb.UsbPort.STOPBITS_1,
    };
  }

  int _androidParity(String parity) {
    return switch (parity.toLowerCase()) {
      'odd' => usb.UsbPort.PARITY_ODD,
      'even' => usb.UsbPort.PARITY_EVEN,
      'mark' => usb.UsbPort.PARITY_MARK,
      'space' => usb.UsbPort.PARITY_SPACE,
      _ => usb.UsbPort.PARITY_NONE,
    };
  }
}

class AndroidUsbSerialConnection implements SerialConnection {
  AndroidUsbSerialConnection(this._port);

  final usb.UsbPort _port;

  @override
  Stream<Uint8List> get input => _port.inputStream ?? const Stream.empty();

  @override
  Future<void> write(Uint8List bytes) => _port.write(bytes);

  @override
  Future<void> close() => _port.close();
}
