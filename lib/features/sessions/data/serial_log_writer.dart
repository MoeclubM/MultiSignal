import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

import '../domain/serial_sample.dart';

class SerialLogWriter {
  SerialLogWriter(this.file, {Duration? flushInterval})
    : _flushInterval = flushInterval ?? const Duration(seconds: 2);

  final File file;
  final Duration _flushInterval;

  IOSink? _sink;
  Timer? _flushTimer;
  bool _closed = false;

  Future<void> open() async {
    await file.parent.create(recursive: true);
    _sink = file.openWrite();
    _sink!.writeln(csv.encode([header]));
    // Flush periodically so a crash or OS kill does not lose the entire
    // recording: the OS file buffer can otherwise retain megabytes of samples
    // that never reach disk.
    _flushTimer = Timer.periodic(_flushInterval, (_) => unawaited(flush()));
  }

  Future<void> add(SerialSample sample) async {
    final sink = _sink;
    if (sink == null) {
      throw StateError('SerialLogWriter is not open.');
    }
    sink.writeln(csv.encode([sample.toCsvRow()]));
  }

  /// Writes any buffered samples to disk without closing the file.
  Future<void> flush() async {
    final sink = _sink;
    if (sink == null) return;
    try {
      await sink.flush();
    } catch (_) {
      // Ignore transient flush errors; the next tick or close() will retry.
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _flushTimer?.cancel();
    _flushTimer = null;
    final sink = _sink;
    _sink = null;
    await sink?.flush();
    await sink?.close();
  }

  static const header = [
    'elapsed_us',
    'wall_time_iso',
    'source',
    'raw_hex',
    'text',
  ];
}

class SerialLogReader {
  const SerialLogReader();

  Future<List<SerialSample>> read(File file) async {
    if (!await file.exists()) return const [];
    final content = await file.readAsString(encoding: utf8);
    if (content.trim().isEmpty) return const [];
    final rows = csv.decode(content);
    return rows
        .skip(1)
        .where((row) => row.length >= 4)
        .map(SerialSample.fromCsvRow)
        .toList();
  }
}
