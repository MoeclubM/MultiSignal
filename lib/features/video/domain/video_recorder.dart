import 'dart:io';

import 'package:flutter/widgets.dart';

import 'video_device.dart';

abstract class VideoRecorder {
  Future<List<VideoDevice>> listDevices();

  Future<void> initialize(VideoDevice device);

  Widget buildPreview();

  Future<void> startRecording();

  Future<File> stopRecording({required File outputFile});

  Future<void> dispose();
}
