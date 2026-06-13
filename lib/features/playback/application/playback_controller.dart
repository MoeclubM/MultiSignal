import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../sessions/data/serial_log_writer.dart';
import '../../sessions/data/session_repository.dart';
import '../../sessions/domain/recording_session.dart';
import '../../sessions/domain/serial_sample.dart';
import '../domain/serial_timeline_index.dart';

final playbackControllerProvider = AsyncNotifierProvider.family<PlaybackController, PlaybackState, String>(
  PlaybackController.new,
);

class PlaybackState {
  const PlaybackState({
    required this.session,
    required this.videoController,
    required this.timelineIndex,
    this.currentSamples = const [],
  });

  final RecordingSession session;
  final VideoPlayerController videoController;
  final SerialTimelineIndex timelineIndex;
  final List<SerialSample> currentSamples;

  PlaybackState copyWith({List<SerialSample>? currentSamples}) {
    return PlaybackState(
      session: session,
      videoController: videoController,
      timelineIndex: timelineIndex,
      currentSamples: currentSamples ?? this.currentSamples,
    );
  }
}

class PlaybackController extends FamilyAsyncNotifier<PlaybackState, String> {
  Timer? _timer;
  VideoPlayerController? _videoController;

  @override
  Future<PlaybackState> build(String arg) async {
    ref.onDispose(() => unawaited(_dispose()));
    final session = await ref.watch(sessionRepositoryProvider).findById(arg);
    if (session == null) throw StateError('找不到会话：$arg');
    if (!await session.videoFile.exists()) throw StateError('视频文件不存在：${session.videoFile.path}');

    final samples = await const SerialLogReader().read(session.serialLogFile);
    final timeline = SerialTimelineIndex(samples);
    final videoController = VideoPlayerController.file(session.videoFile);
    _videoController = videoController;
    await videoController.initialize();

    _timer = Timer.periodic(const Duration(milliseconds: 150), (_) => _syncSamples());
    return PlaybackState(
      session: session,
      videoController: videoController,
      timelineIndex: timeline,
      currentSamples: timeline.window(position: Duration.zero),
    );
  }

  Future<void> playPause() async {
    final value = state.valueOrNull;
    if (value == null) return;
    if (value.videoController.value.isPlaying) {
      await value.videoController.pause();
    } else {
      await value.videoController.play();
    }
    _syncSamples();
  }

  Future<void> seek(Duration position) async {
    final value = state.valueOrNull;
    if (value == null) return;
    await value.videoController.seekTo(position);
    _syncSamples();
  }

  void _syncSamples() {
    final value = state.valueOrNull;
    if (value == null) return;
    final position = value.videoController.value.position;
    state = AsyncData(value.copyWith(currentSamples: value.timelineIndex.window(position: position)));
  }

  Future<void> _dispose() async {
    _timer?.cancel();
    await _videoController?.dispose();
  }
}
