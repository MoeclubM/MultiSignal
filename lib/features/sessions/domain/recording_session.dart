import 'dart:io';

import 'session_meta.dart';

class RecordingSession {
  const RecordingSession({
    required this.directory,
    required this.meta,
  });

  final Directory directory;
  final SessionMeta meta;

  File get videoFile => File('${directory.path}${Platform.pathSeparator}${meta.files.video}');

  File get serialLogFile => File('${directory.path}${Platform.pathSeparator}${meta.files.serialLog}');

  File get metaFile => File('${directory.path}${Platform.pathSeparator}${meta.files.meta}');
}
