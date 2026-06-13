import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import '../../sessions/domain/serial_sample.dart';
import '../application/playback_controller.dart';

class PlaybackPage extends ConsumerWidget {
  const PlaybackPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackControllerProvider(sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('同步回看')),
      body: playback.when(
        data: (state) => _PlaybackBody(state: state, sessionId: sessionId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: '无法打开会话',
          message: '$error',
        ),
      ),
    );
  }
}

class _PlaybackBody extends ConsumerWidget {
  const _PlaybackBody({required this.state, required this.sessionId});

  final PlaybackState state;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playbackControllerProvider(sessionId).notifier);
    final video = state.videoController;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final player = SectionCard(
              title: '视频',
              subtitle: state.session.meta.video.deviceLabel,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: video.value.aspectRatio == 0 ? 16 / 9 : video.value.aspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: VideoPlayer(video),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlaybackControls(controller: controller, video: video),
                ],
              ),
            );
            final serial = _SerialPanel(samples: state.currentSamples);
            if (!wide) {
              return Column(children: [player, const SizedBox(height: 20), serial]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: player),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: serial),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: '会话信息',
          child: Text(
            '平台：${state.session.meta.createdPlatform}\n'
            '开始：${state.session.meta.startedAt.toLocal()}\n'
            '串口：${state.session.meta.serial.portLabel ?? '未知'}\n'
            '日志样本：${state.timelineIndex.samples.length}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.controller, required this.video});

  final PlaybackController controller;
  final VideoPlayerController video;

  @override
  Widget build(BuildContext context) {
    final value = video.value;
    final duration = value.duration;
    final position = value.position > duration ? duration : value.position;

    return AnimatedBuilder(
      animation: video,
      builder: (context, _) {
        final current = video.value.position;
        final total = video.value.duration;
        return Column(
          children: [
            Slider(
              value: total.inMilliseconds == 0 ? 0 : current.inMilliseconds.clamp(0, total.inMilliseconds).toDouble(),
              max: total.inMilliseconds == 0 ? 1 : total.inMilliseconds.toDouble(),
              onChanged: (value) => controller.seek(Duration(milliseconds: value.round())),
            ),
            Row(
              children: [
                IconButton.filled(
                  onPressed: controller.playPause,
                  icon: Icon(video.value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 12),
                Text('${_formatDuration(position)} / ${_formatDuration(duration)}'),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SerialPanel extends StatelessWidget {
  const _SerialPanel({required this.samples});

  final List<SerialSample> samples;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: '同步串口数据',
      subtitle: '显示视频当前位置附近的数据窗口。',
      child: SizedBox(
        height: 420,
        child: samples.isEmpty
            ? Center(
                child: Text(
                  '当前位置没有串口数据',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            : ListView.separated(
                itemCount: samples.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final sample = samples[index];
                  final seconds = sample.elapsedUs / 1000000;
                  return ListTile(
                    dense: true,
                    title: Text(
                      sample.text.toString().trim().isEmpty ? sample.rawHex.toString() : sample.text.toString().trim(),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    subtitle: Text('${seconds.toStringAsFixed(3)}s · ${sample.source}'),
                  );
                },
              ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
