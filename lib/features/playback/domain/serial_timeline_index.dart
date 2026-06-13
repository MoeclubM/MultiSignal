import '../../sessions/domain/serial_sample.dart';

class SerialTimelineIndex {
  SerialTimelineIndex(List<SerialSample> samples) : samples = _sorted(samples);

  final List<SerialSample> samples;

  static List<SerialSample> _sorted(List<SerialSample> samples) {
    final sorted = [...samples]..sort((a, b) => a.elapsedUs.compareTo(b.elapsedUs));
    return List.unmodifiable(sorted);
  }

  List<SerialSample> window({
    required Duration position,
    Duration before = const Duration(seconds: 2),
    Duration after = const Duration(seconds: 1),
    int limit = 120,
  }) {
    if (samples.isEmpty) return const [];
    final centerUs = position.inMicroseconds;
    final startUs = centerUs - before.inMicroseconds;
    final endUs = centerUs + after.inMicroseconds;
    final startIndex = _lowerBound(startUs);
    final result = <SerialSample>[];

    for (var i = startIndex; i < samples.length; i++) {
      final sample = samples[i];
      if (sample.elapsedUs > endUs || result.length >= limit) break;
      result.add(sample);
    }

    return result;
  }

  SerialSample? nearest(Duration position) {
    if (samples.isEmpty) return null;
    final targetUs = position.inMicroseconds;
    final index = _lowerBound(targetUs);
    if (index == 0) return samples.first;
    if (index >= samples.length) return samples.last;
    final previous = samples[index - 1];
    final next = samples[index];
    return (targetUs - previous.elapsedUs).abs() <= (next.elapsedUs - targetUs).abs() ? previous : next;
  }

  int _lowerBound(int elapsedUs) {
    var low = 0;
    var high = samples.length;
    while (low < high) {
      final mid = low + ((high - low) >> 1);
      if (samples[mid].elapsedUs < elapsedUs) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}
