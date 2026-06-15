import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../domain/video_device.dart';
import '../domain/video_recorder.dart';

class CameraVideoRecorder implements VideoRecorder {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];

  @override
  Future<List<VideoDevice>> listDevices() async {
    _cameras = await availableCameras();
    return [
      for (var i = 0; i < _cameras.length; i++)
        VideoDevice(id: i.toString(), label: _cameraLabel(_cameras[i], i)),
    ];
  }

  @override
  Future<void> initialize(VideoDevice device) async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    if (_cameras.isEmpty) {
      throw StateError('未发现可用摄像头');
    }
    final index = int.tryParse(device.id) ?? 0;
    final description = _cameras[index.clamp(0, _cameras.length - 1)];
    final previous = _controller;
    _controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
    );
    await previous?.dispose();
    await _controller!.initialize();
  }

  @override
  Widget buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const _VideoPlaceholder(message: '摄像头尚未初始化');
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: CameraPreview(controller),
    );
  }

  @override
  Future<void> startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('摄像头尚未初始化');
    }
    if (controller.value.isRecordingVideo) return;
    await controller.startVideoRecording();
  }

  @override
  Future<File> stopRecording({required File outputFile}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('摄像头尚未初始化');
    }
    if (!controller.value.isRecordingVideo) return outputFile;
    final recorded = await controller.stopVideoRecording();
    await outputFile.parent.create(recursive: true);
    return File(recorded.path).copy(outputFile.path);
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  String _cameraLabel(CameraDescription camera, int index) {
    final name = camera.name.trim();
    if (name.isNotEmpty) return name;
    return switch (camera.lensDirection) {
      CameraLensDirection.front => '前置摄像头 ${index + 1}',
      CameraLensDirection.back => '后置摄像头 ${index + 1}',
      CameraLensDirection.external => '外接摄像头 ${index + 1}',
    };
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(message, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
