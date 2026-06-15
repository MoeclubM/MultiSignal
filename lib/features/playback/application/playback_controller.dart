import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../sessions/data/serial_log_writer.dart';
import '../../sessions/data/session_repository.dart';
import '../../sessions/domain/recording_session.dart';
import '../../sessions/domain/serial_sample.dart';
import '../domain/serial_timeline_index.dart';

class PlaybackBundle {
  const PlaybackBundle({
    required this.session,
    required this.videoController,
    required this.timelineIndex,
  });

  final RecordingSession session;
  final VideoPlayerController videoController;
  final SerialTimelineIndex timelineIndex;

  List<SerialSample> samplesAt(Duration position) {
    return timelineIndex.window(position: position);
  }
}

final playbackBundleProvider = FutureProvider.autoDispose
    .family<PlaybackBundle, String>((ref, sessionId) async {
      final session = await ref
          .watch(sessionRepositoryProvider)
          .findById(sessionId);
      if (session == null) {
        throw StateError('找不到会话：$sessionId');
      }
      if (!await session.videoFile.exists()) {
        throw StateError('视频文件不存在：${session.videoFile.path}');
      }

      final samples = await const SerialLogReader().read(session.serialLogFile);
      final timeline = SerialTimelineIndex(samples);
      final videoController = VideoPlayerController.file(session.videoFile);
      ref.onDispose(videoController.dispose);
      await videoController.initialize();

      return PlaybackBundle(
        session: session,
        videoController: videoController,
        timelineIndex: timeline,
      );
    });
