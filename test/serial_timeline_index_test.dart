import 'package:flutter_test/flutter_test.dart';
import 'package:multisignal/features/playback/domain/serial_timeline_index.dart';
import 'package:multisignal/features/sessions/domain/serial_sample.dart';

void main() {
  test('SerialTimelineIndex returns samples around playback position', () {
    final samples = [
      _sample(0, 'a'),
      _sample(1000000, 'b'),
      _sample(2000000, 'c'),
      _sample(4000000, 'd'),
    ];
    final index = SerialTimelineIndex(samples);

    final window = index.window(
      position: const Duration(seconds: 2),
      before: const Duration(milliseconds: 500),
      after: const Duration(milliseconds: 500),
    );

    expect(window.map((sample) => sample.text), ['c']);
    expect(index.nearest(const Duration(milliseconds: 1200))?.text, 'b');
  });
}

SerialSample _sample(int elapsedUs, String text) {
  return SerialSample(
    elapsedUs: elapsedUs,
    wallTime: DateTime.utc(2026),
    source: 'test',
    rawHex: '',
    text: text,
  );
}
