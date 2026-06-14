import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/section_card.dart';
import '../../video/application/video_recorder_provider.dart';
import '../application/recording_controller.dart';
import '../domain/recording_state.dart';

class RecorderPage extends ConsumerWidget {
  const RecorderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recordingControllerProvider);
    final controller = ref.read(recordingControllerProvider.notifier);
    final videoRecorder = ref.watch(videoRecorderProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('同步录制'),
        actions: [
          IconButton(
            tooltip: '刷新设备',
            onPressed: state.isRecording ? null : controller.refreshDevices,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final preview = AspectRatio(
                aspectRatio: 16 / 9,
                child: videoRecorder.buildPreview(),
              );
              final controls = _RecorderControls(state: state);
              if (!wide) {
                return Column(
                  children: [
                    preview,
                    const SizedBox(height: 16),
                    controls,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: preview),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: controls),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '采集状态',
            subtitle: '视频与串口数据使用统一单调时钟记录。',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(label: '状态', value: _phaseLabel(state.phase)),
                _MetricChip(label: '时长', value: _formatDuration(state.elapsed)),
                _MetricChip(label: '接收块', value: '${state.receivedChunks}'),
                _MetricChip(label: '接收字节', value: '${state.receivedBytes}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '最近串口数据',
            child: SelectableText(
              state.recentText.isEmpty ? '尚未接收数据' : state.recentText,
              style: theme.textTheme.bodyLarge?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 20),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.phase == RecordingPhase.preparing || state.phase == RecordingPhase.stopping
            ? null
            : state.isRecording
                ? controller.stop
                : controller.start,
        icon: Icon(state.isRecording ? Icons.stop : Icons.fiber_manual_record),
        label: Text(state.isRecording ? '停止录制' : '开始录制'),
      ),
    );
  }
}

class _RecorderControls extends ConsumerWidget {
  const _RecorderControls({required this.state});

  final RecordingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(recordingControllerProvider.notifier);

    return SectionCard(
      title: '设备配置',
      subtitle: '连接 USB 转串口设备，并选择用于录制的摄像头。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            // Use `value` (controlled) instead of `initialValue` so the dropdown
            // tracks the selected device as it changes on rescan. Guard against
            // a value not present in [items] to avoid an assertion failure.
            value: _selectableValue(
              state.selectedSerialDevice?.id,
              state.serialDevices.map((device) => device.id),
            ),
            decoration: const InputDecoration(labelText: '串口设备'),
            items: [
              for (final device in state.serialDevices)
                DropdownMenuItem(
                  value: device.id,
                  child: Text(device.label),
                ),
            ],
            onChanged: state.isRecording || state.serialDevices.isEmpty
                ? null
                : (value) {
                    if (value != null) controller.selectSerialDevice(value);
                  },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectableValue(
              state.selectedVideoDevice?.id,
              state.videoDevices.map((device) => device.id),
            ),
            decoration: const InputDecoration(labelText: '摄像头'),
            items: [
              for (final device in state.videoDevices)
                DropdownMenuItem(
                  value: device.id,
                  child: Text(device.label),
                ),
            ],
            onChanged: state.isRecording || state.videoDevices.isEmpty
                ? null
                : (value) {
                    if (value != null) controller.selectVideoDevice(value);
                  },
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: state.serialConfig.baudRate.toString(),
            enabled: false,
            decoration: const InputDecoration(
              labelText: '波特率',
              helperText: 'MVP 默认 115200，后续可扩展为可编辑配置。',
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: state.isRecording ? null : controller.refreshDevices,
            icon: const Icon(Icons.usb),
            label: const Text('重新扫描设备'),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label：$value'),
    );
  }
}

String _phaseLabel(RecordingPhase phase) {
  return switch (phase) {
    RecordingPhase.idle => '待机',
    RecordingPhase.preparing => '准备中',
    RecordingPhase.recording => '录制中',
    RecordingPhase.stopping => '停止中',
    RecordingPhase.completed => '已完成',
    RecordingPhase.error => '异常',
  };
}

/// Returns [id] only if it exists among the [availableIds]; otherwise `null`.
/// Prevents `DropdownButtonFormField` from asserting that its value is present
/// in the items list after a rescan removes the selected device.
String? _selectableValue(String? id, Iterable<String> availableIds) {
  if (id == null) return null;
  return availableIds.contains(id) ? id : null;
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
