import 'package:flutter_test/flutter_test.dart';
import 'package:multisignal/features/recorder/domain/recording_state.dart';
import 'package:multisignal/features/serial/domain/serial_device.dart';
import 'package:multisignal/features/video/domain/video_device.dart';

void main() {
  group('RecordingState.copyWith', () {
    test('clears nullable selected device fields when null is passed', () {
      final initial = const RecordingState().copyWith(
        selectedSerialDevice: const SerialDevice(id: 'serial-1', label: 'COM1'),
        selectedVideoDevice: const VideoDevice(id: 'video-1', label: 'Cam'),
        errorMessage: 'boom',
      );

      expect(initial.selectedSerialDevice?.id, 'serial-1');
      expect(initial.selectedVideoDevice?.id, 'video-1');
      expect(initial.errorMessage, 'boom');

      // Passing null must explicitly clear, not preserve, these fields.
      final cleared = initial.copyWith(
        selectedSerialDevice: null,
        selectedVideoDevice: null,
        errorMessage: null,
      );

      expect(cleared.selectedSerialDevice, isNull);
      expect(cleared.selectedVideoDevice, isNull);
      expect(cleared.errorMessage, isNull);
    });

    test('preserves nullable fields when they are omitted', () {
      final initial = const RecordingState().copyWith(
        selectedSerialDevice: const SerialDevice(id: 'serial-1', label: 'COM1'),
        errorMessage: 'boom',
      );

      // Other fields change, but the omitted nullable ones are preserved.
      final updated = initial.copyWith(receivedBytes: 123, recentText: 'hello');

      expect(updated.selectedSerialDevice?.id, 'serial-1');
      expect(updated.errorMessage, 'boom');
      expect(updated.receivedBytes, 123);
      expect(updated.recentText, 'hello');
    });
  });
}
