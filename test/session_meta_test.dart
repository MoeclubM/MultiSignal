import 'package:flutter_test/flutter_test.dart';
import 'package:multisignal/features/sessions/domain/serial_config.dart';
import 'package:multisignal/features/sessions/domain/session_meta.dart';
import 'package:multisignal/features/sessions/domain/session_status.dart';

void main() {
  test('SessionMeta round-trips JSON', () {
    final meta = SessionMeta(
      schemaVersion: 1,
      sessionId: 'session-1',
      createdPlatform: 'android',
      startedAt: DateTime.utc(2026, 6, 13, 9),
      endedAt: DateTime.utc(2026, 6, 13, 10),
      monotonicStartUs: 100,
      videoStartOffsetUs: 12,
      video: const VideoMeta(
        fileName: 'video.mp4',
        deviceLabel: 'Camera',
        resolution: 'high',
      ),
      serial: const SerialConfig.defaults().copyWith(portLabel: 'COM3'),
      files: const SessionFiles(
        video: 'video.mp4',
        serialLog: 'serial_log.csv',
        meta: 'session_meta.json',
      ),
      status: SessionStatus.completed,
    );

    final decoded = SessionMeta.fromJson(meta.toJson());

    expect(decoded.sessionId, meta.sessionId);
    expect(decoded.createdPlatform, 'android');
    expect(decoded.video.fileName, 'video.mp4');
    expect(decoded.serial.baudRate, 115200);
    expect(decoded.status, SessionStatus.completed);
  });
}
