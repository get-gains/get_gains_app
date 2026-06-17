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
/// Phase 1 uses [SystemSound] + [HapticFeedback] (no extra dependencies).
///
/// ## Phase 2 — migrate to audioplayers
///
/// When custom sound assets are ready:
///
/// 1. Add `audioplayers: ^6.7.1` to pubspec.yaml.
/// 2. Register assets under `assets/sounds/`:
///    - `countdown_tick.wav`
///    - `record_start.wav`
///    - `record_stop.wav`
///    - `success.wav`
///    - `error.wav`
/// 3. Add an `init()` method that preloads [AudioPool]s:
///    ```dart
///    _tickPool = await AudioPool.createFromAsset(
///      path: 'sounds/countdown_tick.wav',
///      minPlayers: 1,
///      maxPlayers: 3,
///      playerMode: PlayerMode.lowLatency,
///    );
///    ```
/// 4. Replace `_playSystemSound` calls with `await pool.start(volume: 0.8)`.
/// 5. Keep this public API (`play(event)`) unchanged so screens need no edits.
/// 6. Call `dispose()` on pools when the service is torn down.
///
/// Use short mono `.wav` files (~50–200 ms), 44.1 or 48 kHz, under 100 KB each.
/// Camera recording uses `enableAudio: false` — playback does not conflict with mic.
class RecordingFeedbackService {
  RecordingFeedbackService({this.enabled = true});

  /// When false, all feedback is suppressed. Wire to Settings / Hive later.
  bool enabled;

  /// Minimum form score (0–1) to play [RecordingFeedbackEvent.success] on client
  /// results; otherwise [RecordingFeedbackEvent.processingComplete] is used.
  static const double successScoreThreshold = 0.6;

  void play(RecordingFeedbackEvent event) {
    if (!enabled) return;

    _playSystemSound(event);
    _playHaptic(event);
  }

  void _playSystemSound(RecordingFeedbackEvent event) {
    final sound = switch (event) {
      RecordingFeedbackEvent.setupReady => SystemSoundType.alert,
      RecordingFeedbackEvent.countdownTick => SystemSoundType.click,
      RecordingFeedbackEvent.countdownCancel => null,
      RecordingFeedbackEvent.recordingStart => SystemSoundType.alert,
      RecordingFeedbackEvent.recordingStop => SystemSoundType.click,
      RecordingFeedbackEvent.processingComplete => SystemSoundType.alert,
      RecordingFeedbackEvent.success => SystemSoundType.alert,
      RecordingFeedbackEvent.error => SystemSoundType.alert,
    };
    if (sound != null) {
      SystemSound.play(sound);
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
  return RecordingFeedbackService();
}
