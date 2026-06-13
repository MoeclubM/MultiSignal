import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/section_card.dart';
import '../application/sessions_providers.dart';
import '../data/session_transfer_service.dart';

class ImportSessionPage extends ConsumerStatefulWidget {
  const ImportSessionPage({super.key});

  @override
  ConsumerState<ImportSessionPage> createState() => _ImportSessionPageState();
}

class _ImportSessionPageState extends ConsumerState<ImportSessionPage> {
  bool _isImporting = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入会话')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            title: '从文件夹导入',
            subtitle: '选择包含 video.mp4、serial_log.csv、session_meta.json 的会话文件夹。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('可将 Android 手机录制的整个会话目录通过 USB 数据线、文件管理器或云盘复制到电脑，然后在这里导入。'),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isImporting ? null : _import,
                  icon: _isImporting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.folder_open),
                  label: Text(_isImporting ? '导入中...' : '选择会话文件夹'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _import() async {
    setState(() {
      _isImporting = true;
      _message = null;
    });
    try {
      final session = await ref.read(sessionTransferServiceProvider).importSession();
      ref.invalidate(sessionsProvider);
      if (!mounted) return;
      context.go('/sessions/${session.meta.sessionId}');
    } catch (error) {
      setState(() => _message = '导入失败：$error');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}
