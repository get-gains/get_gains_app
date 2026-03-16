import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/form_recording_provider.dart';

/// Recording control bar with start/stop and timer.
class RecordingControls extends StatelessWidget {
  const RecordingControls({
    super.key,
    required this.state,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelCountdown,
  });

  final FormRecordingState state;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelCountdown;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface1Dark.withValues(alpha: 0.95)
            : AppColors.cardLight.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recording instructions (setup phase only)
            if (state.phase == RecordingPhase.setupGuidance) ...[
              _RecordingInstructions(isDark: isDark),
              const SizedBox(height: 12),
            ],

            // Timer display during recording
            if (state.isRecording) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(state.recordingDurationMs),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    state.phase == RecordingPhase.recording
                        ? 'Recording… (analyzed when you stop)'
                        : '${state.frameCount} frames',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Main action button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.phase == RecordingPhase.setupGuidance)
                  _RecordButton(
                    enabled: state.canStartRecording,
                    isRecording: false,
                    onPressed: onStartRecording,
                    isDark: isDark,
                  )
                else if (state.isCountingDown)
                  _RecordButton(
                    enabled: true,
                    isRecording: false,
                    onPressed: onCancelCountdown,
                    isDark: isDark,
                    isCountdown: true,
                  )
                else if (state.isRecording)
                  _RecordButton(
                    enabled: true,
                    isRecording: true,
                    onPressed: onStopRecording,
                    isDark: isDark,
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Hint text
            Text(
              state.isRecording
                  ? 'Tap to stop recording'
                  : state.isCountingDown
                  ? 'Recording starts in ${state.countdownSeconds}s — tap to cancel'
                  : state.canStartRecording
                  ? 'All checks passed — starting soon...'
                  : 'Complete all setup checks to begin',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final seconds = ms ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

/// Compact instructions card shown during setup to guide the coach on what
/// to do when recording their form.
class _RecordingInstructions extends StatelessWidget {
  const _RecordingInstructions({required this.isDark});
  final bool isDark;

  static const _tips = [
    (Icons.repeat_one, 'Perform the exercise at a slow, controlled pace'),
    (Icons.accessibility_new, 'Keep your whole body visible in the frame'),
    (Icons.phone_android, 'Prop up or mount your phone keep it steady'),
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final iconColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tips_and_updates, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              'Recording Tips',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final (icon, text) in _tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.enabled,
    required this.isRecording,
    required this.onPressed,
    required this.isDark,
    this.isCountdown = false,
  });

  final bool enabled;
  final bool isRecording;
  final VoidCallback onPressed;
  final bool isDark;
  final bool isCountdown;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.3),
            width: 4,
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isRecording || isCountdown ? 28 : 56,
            height: isRecording || isCountdown ? 28 : 56,
            decoration: BoxDecoration(
              color: isCountdown
                  ? (enabled
                        ? Colors.orange
                        : Colors.orange.withValues(alpha: 0.3))
                  : (enabled ? Colors.red : Colors.red.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(
                isRecording || isCountdown ? 6 : 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
