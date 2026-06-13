import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_card.dart';
import '../application/sessions_providers.dart';
import '../data/session_transfer_service.dart';
import '../domain/recording_session.dart';
import '../domain/session_status.dart';

class SessionsPage extends ConsumerWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史会话'),
        actions: [
          IconButton(
            tooltip: '导入会话',
            onPressed: () => context.go('/sessions/import'),
            icon: const Icon(Icons.drive_folder_upload_outlined),
          ),
          IconButton(
            tooltip: '刷新',
            onPressed: () => ref.invalidate(sessionsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: sessions.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.video_library_outlined,
              title: '还没有录制会话',
              message: '完成一次录制后，会话会显示在这里。也可以导入手机端复制过来的会话目录。',
              action: FilledButton.icon(
                onPressed: () => context.go('/record'),
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('开始录制'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) => _SessionTile(session: items[index]),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: items.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: '读取会话失败',
          message: '$error',
        ),
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final RecordingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = session.meta;
    final theme = Theme.of(context);
    final duration = meta.endedAt == null ? null : meta.endedAt!.difference(meta.startedAt);

    return SectionCard(
      title: meta.startedAt.toLocal().toString().split('.').first,
      subtitle: '${meta.createdPlatform} · ${_statusLabel(meta.status)} · ${duration == null ? '未知时长' : _formatDuration(duration)}',
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'export') {
            try {
              final path = await ref.read(sessionTransferServiceProvider).exportSession(session);
              if (path != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导出到 $path')));
              }
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败：$error')));
              }
            }
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'export', child: Text('导出会话')),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/sessions/${meta.sessionId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.play_arrow),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.video.deviceLabel ?? '未知摄像头'),
                    const SizedBox(height: 4),
                    Text(
                      meta.serial.portLabel ?? '未知串口',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

String _statusLabel(SessionStatus status) {
  return switch (status) {
    SessionStatus.completed => '已完成',
    SessionStatus.interrupted => '未完整结束',
    SessionStatus.error => '异常',
  };
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
