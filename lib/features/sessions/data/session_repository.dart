import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/clock/clock_service.dart';
import '../../../core/platform/platform_label.dart';
import '../domain/recording_session.dart';
import '../domain/serial_config.dart';
import '../domain/session_meta.dart';
import '../domain/session_status.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(clock: ref.watch(clockServiceProvider));
});

class SessionRepository {
  SessionRepository({required ClockService clock}) : _clock = clock;

  final ClockService _clock;
  static const _uuid = Uuid();

  Future<Directory> recordingsRoot() async {
    final support = await getApplicationSupportDirectory();
    final root = Directory(p.join(support.path, 'recordings'));
    await root.create(recursive: true);
    return root;
  }

  Future<RecordingSession> createSession({
    required SerialConfig serialConfig,
    String? videoDeviceLabel,
    String? resolution,
  }) async {
    final snapshot = _clock.snapshot();
    final id = _uuid.v4();
    final nameTime = DateFormat(
      'yyyyMMdd_HHmmss',
    ).format(snapshot.wallTime.toLocal());
    final shortId = id.substring(0, 8);
    final directory = Directory(
      p.join((await recordingsRoot()).path, 'session_${nameTime}_$shortId'),
    );
    await directory.create(recursive: true);

    final meta = SessionMeta(
      schemaVersion: 1,
      sessionId: id,
      createdPlatform: currentPlatformLabel(),
      startedAt: snapshot.wallTime,
      monotonicStartUs: snapshot.monotonicUs,
      video: VideoMeta(
        fileName: 'video.mp4',
        deviceLabel: videoDeviceLabel,
        resolution: resolution,
      ),
      serial: serialConfig,
      files: const SessionFiles(
        video: 'video.mp4',
        serialLog: 'serial_log.csv',
        meta: 'session_meta.json',
      ),
      status: SessionStatus.interrupted,
    );

    final session = RecordingSession(directory: directory, meta: meta);
    await saveMeta(session);
    return session;
  }

  Future<void> saveMeta(RecordingSession session, {SessionMeta? meta}) async {
    final effectiveMeta = meta ?? session.meta;
    const encoder = JsonEncoder.withIndent('  ');
    await session.metaFile.writeAsString(
      encoder.convert(effectiveMeta.toJson()),
    );
  }

  Future<RecordingSession> updateSessionMeta(
    RecordingSession session,
    SessionMeta meta,
  ) async {
    final updated = RecordingSession(directory: session.directory, meta: meta);
    await saveMeta(updated);
    return updated;
  }

  Future<List<RecordingSession>> listSessions() async {
    final root = await recordingsRoot();
    final entries = await root
        .list()
        .where((entity) => entity is Directory)
        .cast<Directory>()
        .toList();
    final sessions = <RecordingSession>[];

    for (final directory in entries) {
      final loaded = await tryLoadSession(directory);
      if (loaded != null) sessions.add(loaded);
    }

    sessions.sort((a, b) => b.meta.startedAt.compareTo(a.meta.startedAt));
    return sessions;
  }

  Future<RecordingSession?> findById(String sessionId) async {
    final sessions = await listSessions();
    for (final session in sessions) {
      if (session.meta.sessionId == sessionId) return session;
    }
    return null;
  }

  Future<RecordingSession?> tryLoadSession(Directory directory) async {
    final metaFile = File(p.join(directory.path, 'session_meta.json'));
    if (!await metaFile.exists()) return null;
    try {
      final json =
          jsonDecode(await metaFile.readAsString()) as Map<String, Object?>;
      final meta = SessionMeta.fromJson(json);
      return RecordingSession(directory: directory, meta: meta);
    } catch (_) {
      return null;
    }
  }

  Future<SessionValidationResult> validateSessionDirectory(
    Directory directory,
  ) async {
    final session = await tryLoadSession(directory);
    if (session == null) {
      return const SessionValidationResult(false, '缺少或无法解析 session_meta.json');
    }
    if (!await session.videoFile.exists()) {
      return const SessionValidationResult(false, '缺少 video.mp4');
    }
    if (!await session.serialLogFile.exists()) {
      return const SessionValidationResult(false, '缺少 serial_log.csv');
    }
    return const SessionValidationResult(true, '会话文件完整');
  }
}

class SessionValidationResult {
  const SessionValidationResult(this.isValid, this.message);

  final bool isValid;
  final String message;
}
