import '../../sessions/domain/serial_config.dart';
import 'serial_connection.dart';
import 'serial_device.dart';

abstract class SerialPortAdapter {
  Future<List<SerialDevice>> listDevices();

  Future<SerialConnection> connect({
    required SerialDevice device,
    required SerialConfig config,
  });
}
