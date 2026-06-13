import '../../serial/domain/serial_device.dart';
import '../../sessions/domain/recording_session.dart';
import '../../sessions/domain/serial_config.dart';
import '../../video/domain/video_device.dart';

enum RecordingPhase {
  idle,
  preparing,
  recording,
  stopping,
  completed,
  error;
}

class RecordingState {
  const RecordingState({
    this.phase = RecordingPhase.idle,
    this.serialDevices = const [],
    this.videoDevices = const [],
    this.serialConfig = const SerialConfig.defaults(),
    this.elapsed = Duration.zero,
    this.receivedBytes = 0,
    this.receivedChunks = 0,
    this.recentText = '',
    this.session,
    this.selectedSerialDevice,
    this.selectedVideoDevice,
    this.errorMessage,
  });

  final RecordingPhase phase;
  final List<SerialDevice> serialDevices;
  final List<VideoDevice> videoDevices;
  final SerialConfig serialConfig;
  final Duration elapsed;
  final int receivedBytes;
  final int receivedChunks;
  final String recentText;
  final RecordingSession? session;
  final SerialDevice? selectedSerialDevice;
  final VideoDevice? selectedVideoDevice;
  final String? errorMessage;

  bool get isRecording => phase == RecordingPhase.recording;

  RecordingState copyWith({
    RecordingPhase? phase,
    List<SerialDevice>? serialDevices,
    List<VideoDevice>? videoDevices,
    SerialConfig? serialConfig,
    Duration? elapsed,
    int? receivedBytes,
    int? receivedChunks,
    String? recentText,
    RecordingSession? session,
    SerialDevice? selectedSerialDevice,
    VideoDevice? selectedVideoDevice,
    String? errorMessage,
  }) {
    return RecordingState(
      phase: phase ?? this.phase,
      serialDevices: serialDevices ?? this.serialDevices,
      videoDevices: videoDevices ?? this.videoDevices,
      serialConfig: serialConfig ?? this.serialConfig,
      elapsed: elapsed ?? this.elapsed,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      receivedChunks: receivedChunks ?? this.receivedChunks,
      recentText: recentText ?? this.recentText,
      session: session ?? this.session,
      selectedSerialDevice: selectedSerialDevice ?? this.selectedSerialDevice,
      selectedVideoDevice: selectedVideoDevice ?? this.selectedVideoDevice,
      errorMessage: errorMessage,
    );
  }
}
