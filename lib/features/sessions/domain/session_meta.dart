import 'serial_config.dart';
import 'session_status.dart';

class SessionMeta {
  const SessionMeta({
    required this.schemaVersion,
    required this.sessionId,
    required this.createdPlatform,
    required this.startedAt,
    required this.monotonicStartUs,
    required this.video,
    required this.serial,
    required this.files,
    required this.status,
    this.endedAt,
    this.videoStartOffsetUs = 0,
    this.errorMessage,
  });

  final int schemaVersion;
  final String sessionId;
  final String createdPlatform;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int monotonicStartUs;
  final int videoStartOffsetUs;
  final VideoMeta video;
  final SerialConfig serial;
  final SessionFiles files;
  final SessionStatus status;
  final String? errorMessage;

  SessionMeta copyWith({
    DateTime? endedAt,
    int? videoStartOffsetUs,
    VideoMeta? video,
    SerialConfig? serial,
    SessionFiles? files,
    SessionStatus? status,
    String? errorMessage,
  }) {
    return SessionMeta(
      schemaVersion: schemaVersion,
      sessionId: sessionId,
      createdPlatform: createdPlatform,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      monotonicStartUs: monotonicStartUs,
      videoStartOffsetUs: videoStartOffsetUs ?? this.videoStartOffsetUs,
      video: video ?? this.video,
      serial: serial ?? this.serial,
      files: files ?? this.files,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'sessionId': sessionId,
    'createdPlatform': createdPlatform,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'endedAt': endedAt?.toUtc().toIso8601String(),
    'monotonicStartUs': monotonicStartUs,
    'videoStartOffsetUs': videoStartOffsetUs,
    'video': video.toJson(),
    'serial': serial.toJson(),
    'files': files.toJson(),
    'status': status.name,
    'errorMessage': errorMessage,
  };

  factory SessionMeta.fromJson(Map<String, Object?> json) {
    return SessionMeta(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      sessionId: json['sessionId'] as String,
      createdPlatform: json['createdPlatform'] as String? ?? 'unknown',
      startedAt: DateTime.parse(json['startedAt'] as String).toUtc(),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String).toUtc(),
      monotonicStartUs: json['monotonicStartUs'] as int? ?? 0,
      videoStartOffsetUs: json['videoStartOffsetUs'] as int? ?? 0,
      video: VideoMeta.fromJson((json['video'] as Map).cast<String, Object?>()),
      serial: SerialConfig.fromJson(
        (json['serial'] as Map).cast<String, Object?>(),
      ),
      files: SessionFiles.fromJson(
        (json['files'] as Map).cast<String, Object?>(),
      ),
      status: SessionStatus.fromJson(json['status'] as String? ?? 'error'),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

class VideoMeta {
  const VideoMeta({required this.fileName, this.deviceLabel, this.resolution});

  final String fileName;
  final String? deviceLabel;
  final String? resolution;

  Map<String, Object?> toJson() => {
    'fileName': fileName,
    'deviceLabel': deviceLabel,
    'resolution': resolution,
  };

  factory VideoMeta.fromJson(Map<String, Object?> json) {
    return VideoMeta(
      fileName: json['fileName'] as String? ?? 'video.mp4',
      deviceLabel: json['deviceLabel'] as String?,
      resolution: json['resolution'] as String?,
    );
  }
}

class SessionFiles {
  const SessionFiles({
    required this.video,
    required this.serialLog,
    required this.meta,
  });

  final String video;
  final String serialLog;
  final String meta;

  Map<String, Object?> toJson() => {
    'video': video,
    'serialLog': serialLog,
    'meta': meta,
  };

  factory SessionFiles.fromJson(Map<String, Object?> json) {
    return SessionFiles(
      video: json['video'] as String? ?? 'video.mp4',
      serialLog: json['serialLog'] as String? ?? 'serial_log.csv',
      meta: json['meta'] as String? ?? 'session_meta.json',
    );
  }
}
