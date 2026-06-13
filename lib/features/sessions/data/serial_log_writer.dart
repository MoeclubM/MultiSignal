import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

import '../domain/serial_sample.dart';

class SerialLogWriter {
  SerialLogWriter(this.file);

  final File file;
  IOSink? _sink;

  Future<void> open() async {
    await file.parent.create(recursive: true);
    _sink = file.openWrite();
    _sink!.writeln(const ListToCsvConverter().convert([header]));
  }

  Future<void> add(SerialSample sample) async {
    final sink = _sink;
    if (sink == null) {
      throw StateError('SerialLogWriter is not open.');
    }
    sink.writeln(const ListToCsvConverter().convert([sample.toCsvRow()]));
  }

  Future<void> close() async {
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
    final rows = const CsvToListConverter(eol: '\n').convert(content);
    return rows.skip(1).where((row) => row.length >= 4).map(SerialSample.fromCsvRow).toList();
  }
}
