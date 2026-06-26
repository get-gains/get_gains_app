import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
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
/// Uses preloaded [AudioSource]s with CC0 Kenney interface sounds under
/// `assets/sounds/` via [flutter_soloud]. Camera recording uses
/// `enableAudio: false` — playback does not conflict with the mic.
class RecordingFeedbackService {
  RecordingFeedbackService({this.enabled = true});

  /// When false, all feedback is suppressed. Wire to Settings / Hive later.
  bool enabled;

  /// Minimum form score (0–1) to play [RecordingFeedbackEvent.success] on client
  /// results; otherwise [RecordingFeedbackEvent.processingComplete] is used.
  static const double successScoreThreshold = 0.6;

  static const _eventAssets = <RecordingFeedbackEvent, String>{
    RecordingFeedbackEvent.setupReady: 'assets/sounds/setup_ready.wav',
    RecordingFeedbackEvent.countdownTick: 'assets/sounds/countdown_tick.wav',
    RecordingFeedbackEvent.recordingStart: 'assets/sounds/record_start.wav',
    RecordingFeedbackEvent.recordingStop: 'assets/sounds/record_stop.wav',
    RecordingFeedbackEvent.processingComplete:
        'assets/sounds/processing_complete.wav',
    RecordingFeedbackEvent.success: 'assets/sounds/success.wav',
    RecordingFeedbackEvent.error: 'assets/sounds/error.wav',
  };

  final SoLoud _soloud = SoLoud.instance;
  final Map<String, AudioSource> _sources = {};
  Future<void>? _initFuture;
  bool _disposed = false;

  void play(RecordingFeedbackEvent event) {
    if (!enabled) return;

    unawaited(_ensureInitialized().then((_) => _playAsset(event)));
    _playHaptic(event);
  }

  Future<void> _ensureInitialized() {
    if (_disposed) return Future.value();
    return _initFuture ??= _initializeSources();
  }

  Future<void> _initializeSources() async {
    if (!_soloud.isInitialized) {
      await _soloud.init();
    }

    final uniqueAssets = _eventAssets.values.toSet();
    for (final asset in uniqueAssets) {
      _sources[asset] = await _soloud.loadAsset(asset);
    }
  }

  Future<void> _playAsset(RecordingFeedbackEvent event) async {
    if (_disposed || event == RecordingFeedbackEvent.countdownCancel) return;

    final asset = _eventAssets[event];
    if (asset == null) return;

    final source = _sources[asset];
    if (source == null) return;

    try {
      _soloud.play(source, volume: 0.85);
    } catch (_) {
      // Non-fatal: haptics still fire if audio fails.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    final sources = _sources.values.toList();
    _sources.clear();
    for (final source in sources) {
      await _soloud.disposeSource(source);
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
