import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock/clock_service.dart';
import '../../serial/application/serial_adapter_provider.dart';
import '../../serial/domain/serial_connection.dart';
import '../../serial/domain/serial_device.dart';
import '../../serial/domain/serial_port_adapter.dart';
import '../../sessions/data/serial_log_writer.dart';
import '../../sessions/data/session_repository.dart';
import '../../sessions/domain/serial_sample.dart';
import '../../sessions/domain/session_status.dart';
import '../../video/application/video_recorder_provider.dart';
import '../../video/domain/video_device.dart';
import '../../video/domain/video_recorder.dart';
import '../domain/recording_state.dart';

final recordingControllerProvider =
    NotifierProvider<RecordingController, RecordingState>(
      RecordingController.new,
    );

class RecordingController extends Notifier<RecordingState> {
  late final SerialPortAdapter _serialAdapter;
  late final VideoRecorder _videoRecorder;
  late final SessionRepository _sessionRepository;
  late final ClockService _clock;

  SerialConnection? _serialConnection;
  SerialLogWriter? _logWriter;
  StreamSubscription? _serialSubscription;
  Timer? _elapsedTimer;
  int? _recordingStartUs;

  @override
  RecordingState build() {
    _serialAdapter = ref.watch(serialPortAdapterProvider);
    _videoRecorder = ref.watch(videoRecorderProvider);
    _sessionRepository = ref.watch(sessionRepositoryProvider);
    _clock = ref.watch(clockServiceProvider);
    ref.onDispose(() => unawaited(_cleanup()));
    Future.microtask(refreshDevices);
    return const RecordingState();
  }

  Future<void> refreshDevices() async {
    try {
      final serialDevices = await _serialAdapter.listDevices();
      final videoDevices = await _videoRecorder.listDevices();
      // Re-validate the previously selected devices: a device that disappeared
      // (USB unplugged, camera in use) must not stay selected, otherwise the
      // dropdown in the UI ends up pointing at a non-existent item.
      final currentSerial = state.selectedSerialDevice;
      final currentVideo = state.selectedVideoDevice;
      final resolvedSerial = currentSerial == null
          ? (serialDevices.isNotEmpty ? serialDevices.first : null)
          : serialDevices.cast<SerialDevice?>().firstWhere(
              (d) => d?.id == currentSerial.id,
              orElse: () => null,
            );
      final resolvedVideo = currentVideo == null
          ? (videoDevices.isNotEmpty ? videoDevices.first : null)
          : videoDevices.cast<VideoDevice?>().firstWhere(
              (d) => d?.id == currentVideo.id,
              orElse: () => null,
            );
      state = state.copyWith(
        serialDevices: serialDevices,
        videoDevices: videoDevices,
        selectedSerialDevice: resolvedSerial,
        selectedVideoDevice: resolvedVideo,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        errorMessage: '设备刷新失败：$error',
      );
    }
  }

  Future<void> selectSerialDevice(String id) async {
    final matches = state.serialDevices.where((device) => device.id == id);
    state = state.copyWith(
      selectedSerialDevice: matches.isEmpty ? null : matches.first,
    );
  }

  Future<void> selectVideoDevice(String id) async {
    final matches = state.videoDevices.where((device) => device.id == id);
    final device = matches.isEmpty ? null : matches.first;
    state = state.copyWith(selectedVideoDevice: device);
    if (device != null) {
      await _videoRecorder.initialize(device);
      state = state.copyWith(errorMessage: null);
    }
  }

  Future<void> initializeSelectedVideo() async {
    final device = state.selectedVideoDevice;
    if (device == null) return;
    await _videoRecorder.initialize(device);
  }

  Future<void> start() async {
    if (state.isRecording) return;
    final serialDevice = state.selectedSerialDevice;
    final videoDevice = state.selectedVideoDevice;
    if (serialDevice == null) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        errorMessage: '请先选择串口设备',
      );
      return;
    }
    if (videoDevice == null) {
      state = state.copyWith(
        phase: RecordingPhase.error,
        errorMessage: '请先选择摄像头',
      );
      return;
    }

    state = state.copyWith(
      phase: RecordingPhase.preparing,
      elapsed: Duration.zero,
      receivedBytes: 0,
      receivedChunks: 0,
      recentText: '',
      errorMessage: null,
    );

    try {
      await _videoRecorder.initialize(videoDevice);
      final session = await _sessionRepository.createSession(
        serialConfig: state.serialConfig.copyWith(
          portLabel: serialDevice.label,
        ),
        videoDeviceLabel: videoDevice.label,
        resolution: 'high',
      );
      _logWriter = SerialLogWriter(session.serialLogFile);
      await _logWriter!.open();
      _serialConnection = await _serialAdapter.connect(
        device: serialDevice,
        config: state.serialConfig,
      );

      _recordingStartUs = _clock.monotonicNowUs();
      await _videoRecorder.startRecording();

      _serialSubscription = _serialConnection!.input.listen(
        (bytes) async {
          final startUs = _recordingStartUs;
          if (startUs == null) return;
          final sample = SerialSample.fromBytes(
            elapsedUs: _clock.elapsedSinceUs(startUs),
            wallTime: _clock.wallNow(),
            source: serialDevice.label,
            bytes: bytes,
          );
          await _logWriter?.add(sample);
          state = state.copyWith(
            receivedBytes: state.receivedBytes + bytes.length,
            receivedChunks: state.receivedChunks + 1,
            recentText: sample.text.trim().isEmpty
                ? sample.rawHex
                : sample.text.trim(),
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          state = state.copyWith(
            phase: RecordingPhase.error,
            errorMessage: '串口读取异常：$error',
          );
        },
      );

      _elapsedTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        final startUs = _recordingStartUs;
        if (startUs == null) return;
        state = state.copyWith(
          elapsed: Duration(microseconds: _clock.elapsedSinceUs(startUs)),
        );
      });

      state = state.copyWith(phase: RecordingPhase.recording, session: session);
    } catch (error) {
      await _stopInternals();
      state = state.copyWith(
        phase: RecordingPhase.error,
        errorMessage: '开始录制失败：$error',
      );
    }
  }

  Future<void> stop() async {
    if (!state.isRecording) return;
    state = state.copyWith(phase: RecordingPhase.stopping);
    final session = state.session;
    try {
      if (session != null) {
        await _videoRecorder.stopRecording(outputFile: session.videoFile);
      }
      await _stopInternals();
      if (session != null) {
        final updatedMeta = session.meta.copyWith(
          endedAt: _clock.wallNow(),
          status: SessionStatus.completed,
        );
        final updatedSession = await _sessionRepository.updateSessionMeta(
          session,
          updatedMeta,
        );
        state = state.copyWith(
          phase: RecordingPhase.completed,
          session: updatedSession,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          phase: RecordingPhase.completed,
          errorMessage: null,
        );
      }
    } catch (error) {
      if (session != null) {
        final updatedMeta = session.meta.copyWith(
          endedAt: _clock.wallNow(),
          status: SessionStatus.error,
          errorMessage: error.toString(),
        );
        await _sessionRepository.updateSessionMeta(session, updatedMeta);
      }
      await _stopInternals();
      state = state.copyWith(
        phase: RecordingPhase.error,
        errorMessage: '停止录制失败：$error',
      );
    }
  }

  Future<void> _stopInternals() async {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    await _serialSubscription?.cancel();
    _serialSubscription = null;
    await _serialConnection?.close();
    _serialConnection = null;
    await _logWriter?.close();
    _logWriter = null;
    _recordingStartUs = null;
  }

  Future<void> _cleanup() async {
    await _stopInternals();
    await _videoRecorder.dispose();
  }
}
