import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final clockServiceProvider = Provider<ClockService>((ref) => ClockService());

class ClockService {
  final Stopwatch _stopwatch = Stopwatch()..start();

  DateTime wallNow() => DateTime.now().toUtc();

  int monotonicNowUs() => _elapsedToUs(_stopwatch.elapsed);

  RecordingClockSnapshot snapshot() => RecordingClockSnapshot(
    wallTime: wallNow(),
    monotonicUs: monotonicNowUs(),
  );

  int elapsedSinceUs(int monotonicStartUs) {
    return max(0, monotonicNowUs() - monotonicStartUs);
  }

  int _elapsedToUs(Duration duration) => duration.inMicroseconds;
}

class RecordingClockSnapshot {
  const RecordingClockSnapshot({
    required this.wallTime,
    required this.monotonicUs,
  });

  final DateTime wallTime;
  final int monotonicUs;
}
