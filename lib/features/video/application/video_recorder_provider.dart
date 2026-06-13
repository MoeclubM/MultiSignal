import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camera_video_recorder.dart';
import '../domain/video_recorder.dart';

final videoRecorderProvider = Provider<VideoRecorder>((ref) {
  final recorder = CameraVideoRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});
