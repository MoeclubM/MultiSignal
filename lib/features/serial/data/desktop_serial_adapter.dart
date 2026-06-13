import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

import '../../sessions/domain/serial_config.dart';
import '../domain/serial_connection.dart';
import '../domain/serial_device.dart';
import '../domain/serial_port_adapter.dart';

class DesktopSerialAdapter implements SerialPortAdapter {
  const DesktopSerialAdapter();

  @override
  Future<List<SerialDevice>> listDevices() async {
    return SerialPort.availablePorts
        .map(
          (name) => SerialDevice(
            id: name,
            label: name,
          ),
        )
        .toList();
  }

  @override
  Future<SerialConnection> connect({
    required SerialDevice device,
    required SerialConfig config,
  }) async {
    final port = SerialPort(device.id);
    if (!port.openReadWrite()) {
      final error = SerialPort.lastError;
      throw StateError('无法打开串口 ${device.label}: $error');
    }

    final portConfig = SerialPortConfig()
      ..baudRate = config.baudRate
      ..bits = config.dataBits
      ..stopBits = config.stopBits
      ..parity = _desktopParity(config.parity);
    port.config = portConfig;

    return DesktopSerialConnection(port);
  }

  int _desktopParity(String parity) {
    return switch (parity.toLowerCase()) {
      'odd' => SerialPortParity.odd,
      'even' => SerialPortParity.even,
      'mark' => SerialPortParity.mark,
      'space' => SerialPortParity.space,
      _ => SerialPortParity.none,
    };
  }
}

class DesktopSerialConnection implements SerialConnection {
  DesktopSerialConnection(this._port) : _reader = SerialPortReader(_port);

  final SerialPort _port;
  final SerialPortReader _reader;

  @override
  Stream<Uint8List> get input => _reader.stream;

  @override
  Future<void> write(Uint8List bytes) async {
    _port.write(bytes);
  }

  @override
  Future<void> close() async {
    _reader.close();
    _port.close();
    _port.dispose();
  }
}
