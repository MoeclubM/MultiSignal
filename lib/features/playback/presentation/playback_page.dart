import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import '../../sessions/domain/serial_sample.dart';
import '../application/playback_controller.dart';

class PlaybackPage extends ConsumerStatefulWidget {
  const PlaybackPage({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends ConsumerState<PlaybackPage> {
  Timer? _syncTimer;
  PlaybackBundle? _bundle;
  List<SerialSample> _samples = const [];

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _startSync(PlaybackBundle bundle) {
    _syncTimer?.cancel();
    _bundle = bundle;
    void tick() {
      if (!mounted || _bundle == null) return;
      setState(() {
        _samples = _bundle!.samplesAt(bundle.videoController.value.position);
      });
    }

    tick();
    _syncTimer = Timer.periodic(
      const Duration(milliseconds: 150),
      (_) => tick(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackBundleProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('同步回看')),
      body: playback.when(
        data: (bundle) {
          // Start the sync timer exactly once per bundle. Using a post-frame
          // callback inside build() would re-run it on every rebuild (each tick
          // triggers setState), churning timers at frame rate.
          if (!identical(_bundle, bundle)) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _startSync(bundle),
            );
          }
          return _PlaybackBody(bundle: bundle, samples: _samples);
        },
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

class _PlaybackBody extends StatelessWidget {
  const _PlaybackBody({required this.bundle, required this.samples});

  final PlaybackBundle bundle;
  final List<SerialSample> samples;

  @override
  Widget build(BuildContext context) {
    final video = bundle.videoController;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final player = SectionCard(
              title: '视频',
              subtitle: bundle.session.meta.video.deviceLabel,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: video.value.aspectRatio == 0
                        ? 16 / 9
                        : video.value.aspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: VideoPlayer(video),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlaybackControls(video: video),
                ],
              ),
            );
            final serial = _SerialPanel(samples: samples);
            if (!wide) {
              return Column(
                children: [player, const SizedBox(height: 20), serial],
              );
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
            '平台：${bundle.session.meta.createdPlatform}\n'
            '开始：${bundle.session.meta.startedAt.toLocal()}\n'
            '串口：${bundle.session.meta.serial.portLabel ?? '未知'}\n'
            '日志样本：${bundle.timelineIndex.samples.length}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.video});

  final VideoPlayerController video;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: video,
      builder: (context, _) {
        final current = video.value.position;
        final total = video.value.duration;
        final safeMax = total.inMilliseconds == 0
            ? 1.0
            : total.inMilliseconds.toDouble();
        final safeValue = total.inMilliseconds == 0
            ? 0.0
            : current.inMilliseconds.clamp(0, total.inMilliseconds).toDouble();

        return Column(
          children: [
            Slider(
              value: safeValue,
              max: safeMax,
              onChanged: (value) =>
                  video.seekTo(Duration(milliseconds: value.round())),
            ),
            Row(
              children: [
                IconButton.filled(
                  onPressed: () {
                    if (video.value.isPlaying) {
                      video.pause();
                    } else {
                      video.play();
                    }
                  },
                  icon: Icon(
                    video.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
                const SizedBox(width: 12),
                Text('${_formatDuration(current)} / ${_formatDuration(total)}'),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : ListView.separated(
                itemCount: samples.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final sample = samples[index];
                  final seconds = sample.elapsedUs / 1000000;
                  final title = sample.text.trim().isEmpty
                      ? sample.rawHex
                      : sample.text.trim();
                  return ListTile(
                    dense: true,
                    title: Text(
                      title,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    subtitle: Text(
                      '${seconds.toStringAsFixed(3)}s · ${sample.source}',
                    ),
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
