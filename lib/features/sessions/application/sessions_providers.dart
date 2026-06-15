import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/serial_log_writer.dart';
import '../data/session_repository.dart';
import '../domain/recording_session.dart';
import '../domain/serial_sample.dart';

final sessionsProvider = FutureProvider<List<RecordingSession>>((ref) async {
  return ref.watch(sessionRepositoryProvider).listSessions();
});

final sessionByIdProvider = FutureProvider.family<RecordingSession?, String>((
  ref,
  sessionId,
) async {
  return ref.watch(sessionRepositoryProvider).findById(sessionId);
});

final serialSamplesProvider = FutureProvider.family<List<SerialSample>, File>((
  ref,
  file,
) async {
  return const SerialLogReader().read(file);
});
