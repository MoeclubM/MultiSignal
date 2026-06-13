import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../sessions/domain/serial_config.dart';
import '../domain/serial_connection.dart';
import '../domain/serial_device.dart';
import '../domain/serial_port_adapter.dart';

class MockSerialAdapter implements SerialPortAdapter {
  const MockSerialAdapter();

  @override
  Future<List<SerialDevice>> listDevices() async {
    return const [
      SerialDevice(
        id: 'mock://loopback',
        label: '模拟串口设备',
        manufacturer: 'MultiSignal',
        productName: 'Loopback',
      ),
    ];
  }

  @override
  Future<SerialConnection> connect({
    required SerialDevice device,
    required SerialConfig config,
  }) async {
    return MockSerialConnection(device: device, config: config);
  }
}

class MockSerialConnection implements SerialConnection {
  MockSerialConnection({required this.device, required this.config}) {
    var counter = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      counter++;
      final line = 't=$counter, value=${counter % 100}, port=${device.label}\n';
      _controller.add(Uint8List.fromList(utf8.encode(line)));
    });
  }

  final SerialDevice device;
  final SerialConfig config;
  final _controller = StreamController<Uint8List>.broadcast();
  Timer? _timer;

  @override
  Stream<Uint8List> get input => _controller.stream;

  @override
  Future<void> write(Uint8List bytes) async {}

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _controller.close();
  }
}
