import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recording_feedback_service.g.dart';

/// UX feedback events during pose recording (client workout + coach reference).
enum RecordingFeedbackEvent {
  setupReady,
  countdownTick,
  countdownCancel,
  recordingStart,
  recordingStop,
  processingComplete,
  success,
  error,
}

/// Plays audio and haptic feedback during recording flows.
///
/// Uses preloaded [AudioPool]s with CC0 Kenney interface sounds under
/// `assets/sounds/`. Camera recording uses `enableAudio: false` — playback
/// does not conflict with the mic.
class RecordingFeedbackService {
  RecordingFeedbackService({this.enabled = true});

  /// When false, all feedback is suppressed. Wire to Settings / Hive later.
  bool enabled;

  /// Minimum form score (0–1) to play [RecordingFeedbackEvent.success] on client
  /// results; otherwise [RecordingFeedbackEvent.processingComplete] is used.
  static const double successScoreThreshold = 0.6;

  static const _assetPrefix = 'sounds/';

  static const _eventAssets = <RecordingFeedbackEvent, String>{
    RecordingFeedbackEvent.setupReady: '${_assetPrefix}setup_ready.wav',
    RecordingFeedbackEvent.countdownTick: '${_assetPrefix}countdown_tick.wav',
    RecordingFeedbackEvent.recordingStart: '${_assetPrefix}record_start.wav',
    RecordingFeedbackEvent.recordingStop: '${_assetPrefix}record_stop.wav',
    RecordingFeedbackEvent.processingComplete:
        '${_assetPrefix}processing_complete.wav',
    RecordingFeedbackEvent.success: '${_assetPrefix}success.wav',
    RecordingFeedbackEvent.error: '${_assetPrefix}error.wav',
  };

  final Map<String, AudioPool> _pools = {};
  Future<void>? _initFuture;
  bool _disposed = false;

  void play(RecordingFeedbackEvent event) {
    if (!enabled) return;

    unawaited(_ensureInitialized().then((_) => _playAsset(event)));
    _playHaptic(event);
  }

  Future<void> _ensureInitialized() {
    if (_disposed) return Future.value();
    return _initFuture ??= _initializePools();
  }

  Future<void> _initializePools() async {
    final uniqueAssets = _eventAssets.values.toSet();
    for (final asset in uniqueAssets) {
      _pools[asset] = await AudioPool.createFromAsset(
        path: asset,
        minPlayers: 1,
        maxPlayers: asset.contains('countdown_tick') ? 3 : 2,
        playerMode: PlayerMode.lowLatency,
      );
    }
  }

  Future<void> _playAsset(RecordingFeedbackEvent event) async {
    if (_disposed || event == RecordingFeedbackEvent.countdownCancel) return;

    final asset = _eventAssets[event];
    if (asset == null) return;

    final pool = _pools[asset];
    if (pool == null) return;

    try {
      await pool.start(volume: 0.85);
    } catch (_) {
      // Non-fatal: haptics still fire if audio fails.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    final pools = _pools.values.toList();
    _pools.clear();
    for (final pool in pools) {
      await pool.dispose();
    }
  }

  void _playHaptic(RecordingFeedbackEvent event) {
    switch (event) {
      case RecordingFeedbackEvent.setupReady:
        HapticFeedback.mediumImpact();
      case RecordingFeedbackEvent.countdownTick:
        HapticFeedback.lightImpact();
      case RecordingFeedbackEvent.countdownCancel:
        HapticFeedback.selectionClick();
      case RecordingFeedbackEvent.recordingStart:
        HapticFeedback.heavyImpact();
      case RecordingFeedbackEvent.recordingStop:
        HapticFeedback.mediumImpact();
      case RecordingFeedbackEvent.processingComplete:
        HapticFeedback.mediumImpact();
      case RecordingFeedbackEvent.success:
        HapticFeedback.mediumImpact();
      case RecordingFeedbackEvent.error:
        HapticFeedback.heavyImpact();
    }
  }
}

/// Singleton [RecordingFeedbackService] for recording screens.
@Riverpod(keepAlive: true)
RecordingFeedbackService recordingFeedbackService(Ref ref) {
  final service = RecordingFeedbackService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
}
