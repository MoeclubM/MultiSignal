import 'dart:typed_data';

abstract class SerialConnection {
  Stream<Uint8List> get input;

  Future<void> write(Uint8List bytes);

  Future<void> close();
}
