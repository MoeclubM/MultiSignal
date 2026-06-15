import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'session_repository.dart';
import '../domain/recording_session.dart';

final sessionTransferServiceProvider = Provider<SessionTransferService>((ref) {
  return SessionTransferService(
    repository: ref.watch(sessionRepositoryProvider),
  );
});

class SessionTransferService {
  const SessionTransferService({required SessionRepository repository})
    : _repository = repository;

  final SessionRepository _repository;

  Future<String?> exportSession(RecordingSession session) async {
    final targetRoot = await FilePicker.getDirectoryPath(dialogTitle: '选择导出目录');
    if (targetRoot == null) return null;
    final target = Directory(
      p.join(targetRoot, p.basename(session.directory.path)),
    );
    await _copyDirectory(session.directory, target);
    return target.path;
  }

  Future<RecordingSession> importSession() async {
    final sourcePath = await FilePicker.getDirectoryPath(dialogTitle: '选择会话目录');
    if (sourcePath == null) throw StateError('已取消导入');
    final source = Directory(sourcePath);
    final validation = await _repository.validateSessionDirectory(source);
    if (!validation.isValid) throw StateError(validation.message);

    final root = await _repository.recordingsRoot();
    final target = await _uniqueDirectory(
      Directory(p.join(root.path, p.basename(source.path))),
    );
    await _copyDirectory(source, target);
    final imported = await _repository.tryLoadSession(target);
    if (imported == null) throw StateError('导入后无法读取会话元数据');
    return imported;
  }

  Future<Directory> _uniqueDirectory(Directory desired) async {
    if (!await desired.exists()) return desired;
    for (var index = 1; index < 1000; index++) {
      final candidate = Directory('${desired.path}_$index');
      if (!await candidate.exists()) return candidate;
    }
    throw StateError('无法创建唯一导入目录');
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final name = p.basename(entity.path);
      final targetPath = p.join(target.path, name);
      if (entity is File) {
        await entity.copy(targetPath);
      } else if (entity is Directory) {
        await _copyDirectory(entity, Directory(targetPath));
      }
    }
  }
}
