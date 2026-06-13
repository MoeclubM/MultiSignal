import 'dart:convert';
import 'dart:typed_data';

class SerialSample {
  const SerialSample({
    required this.elapsedUs,
    required this.wallTime,
    required this.source,
    required this.rawHex,
    required this.text,
  });

  final int elapsedUs;
  final DateTime wallTime;
  final String source;
  final String rawHex;
  final String text;

  factory SerialSample.fromBytes({
    required int elapsedUs,
    required DateTime wallTime,
    required String source,
    required Uint8List bytes,
  }) {
    return SerialSample(
      elapsedUs: elapsedUs,
      wallTime: wallTime,
      source: source,
      rawHex: bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' '),
      text: utf8.decode(bytes, allowMalformed: true),
    );
  }

  List<Object?> toCsvRow() => [
        elapsedUs,
        wallTime.toUtc().toIso8601String(),
        source,
        rawHex,
        text,
      ];

  factory SerialSample.fromCsvRow(List<dynamic> row) {
    return SerialSample(
      elapsedUs: int.tryParse(row[0].toString()) ?? 0,
      wallTime: DateTime.tryParse(row[1].toString()) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      source: row[2].toString(),
      rawHex: row[3].toString(),
      text: row.length > 4 ? row[4].toString() : '',
    );
  }
}
