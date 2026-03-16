import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../guidance.dart';

/// Bridges [TourNotifier] state to a spotlight overlay + [TourTooltip] UI.
///
/// Wrap any screen's body with this widget and pass a map of tour target keys
/// (matching the [TourStepModel.targetKey] strings) to [GlobalKey]s attached
/// to the widgets that should be highlighted.
///
/// ```dart
/// TourOrchestrator(
///   tourKeys: {
///     'home_todays_focus': _todaysFocusKey,
///     'home_weekly_progress': _weeklyProgressKey,
///   },
///   child: myScreenBody,
/// )
/// ```
class TourOrchestrator extends ConsumerStatefulWidget {
  const TourOrchestrator({
    super.key,
    required this.tourKeys,
    required this.child,
  });

  /// Maps [TourStepModel.targetKey] strings → the [GlobalKey] attached to
  /// that widget in the current screen.
  final Map<String, GlobalKey> tourKeys;

  /// The screen body to display underneath the spotlight overlay.
  final Widget child;

  @override
  ConsumerState<TourOrchestrator> createState() => _TourOrchestratorState();
}

class _TourOrchestratorState extends ConsumerState<TourOrchestrator>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  // Cached notifier so overlay callbacks don't access `ref` after unmount.
  late TourNotifier _tourNotifier;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tourNotifier = ref.read(tourProvider.notifier);
    ref.listen<TourState>(tourProvider, (previous, next) {
      _onTourStateChanged(next);
    });

    return widget.child;
  }

  // ---------------------------------------------------------------------------
  // State change handler
  // ---------------------------------------------------------------------------

  void _onTourStateChanged(TourState next) {
    if (next is TourActive) {
      // Only handle this tour if at least one of its steps targets a key
      // registered on this orchestrator. This prevents an orchestrator on a
      // background route (e.g. home screen still on the back-stack) from
      // consuming a tour intended for the foreground screen and prematurely
      // skipping it.
      final hasRelevantKey = next.steps.any(
        (step) => widget.tourKeys.containsKey(step.targetKey),
      );
      if (!hasRelevantKey) return;
      _showStep(next);
    } else {
      _removeOverlay();
    }
  }

  // ---------------------------------------------------------------------------
  // Overlay management
  // ---------------------------------------------------------------------------

  void _showStep(TourActive state) {
    final targetKey = widget.tourKeys[state.currentStep.targetKey];

    // Remove the old overlay (from a previous step) before inserting a new one.
    _removeOverlaySync();

    if (targetKey == null) {
      AppLogger.warning(
        'Tour step target "${state.currentStep.targetKey}" has no registered '
        'GlobalKey — skipping',
        tag: 'TourOrchestrator',
      );
      // Batch-skip: scan ahead to find the next step that has a registered key.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _skipToNextAvailableStep(state);
      });
      return;
    }

    // Wait for the frame to be painted so the target widget is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Scroll the target into view first, then wait for the scroll + layout.
      final scrolled = _scrollTargetIntoView(targetKey);
      if (scrolled) {
        // Wait for scroll animation to finish + one extra frame for layout.
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
      }

      final targetRect = _measureTarget(targetKey);
      if (targetRect == null) {
        AppLogger.warning(
          'Tour step target "${state.currentStep.targetKey}" not mounted — '
          'skipping',
          tag: 'TourOrchestrator',
        );
        if (!mounted) return;
        _skipToNextAvailableStep(state);
        return;
      }

      _overlayEntry = OverlayEntry(
        builder: (_) => _buildOverlayContent(state, targetRect),
      );
      Overlay.of(context).insert(_overlayEntry!);
      _animController.forward(from: 0);
    });
  }

  /// Scan forward from the current step to find the next step whose target key
  /// is registered in [widget.tourKeys]. If found, jump directly to it via
  /// [TourNotifier.goToStep]. Otherwise, complete the tour.
  ///
  /// This prevents the cascading one-by-one `advance()` callbacks that cause
  /// rapid-fire overlay insertions and `ref.read()` after unmount.
  void _skipToNextAvailableStep(TourActive state) {
    if (!mounted) return;
    int nextIndex = state.currentStepIndex + 1;
    while (nextIndex < state.steps.length) {
      final nextTargetKey = widget.tourKeys[state.steps[nextIndex].targetKey];
      if (nextTargetKey != null) break;
      AppLogger.warning(
        'Tour step target "${state.steps[nextIndex].targetKey}" has no '
        'registered GlobalKey — skipping',
        tag: 'TourOrchestrator',
      );
      nextIndex++;
    }
    if (nextIndex >= state.steps.length) {
      // All remaining steps are missing — complete the tour
      _tourNotifier.skip();
    } else {
      // Jump directly to the next available step
      _tourNotifier.goToStep(nextIndex);
    }
  }

  void _removeOverlay() {
    if (_overlayEntry == null) return;
    _animController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _removeOverlaySync() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ---------------------------------------------------------------------------
  // Measurement
  // ---------------------------------------------------------------------------

  /// Scroll the target widget into view. Returns `true` if a scroll was
  /// triggered and we should wait for it to finish before measuring.
  bool _scrollTargetIntoView(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return false;

    final scrollable = Scrollable.maybeOf(ctx);
    if (scrollable == null) return false;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      alignment: 0.5,
    );
    return true;
  }

  Rect? _measureTarget(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  // ---------------------------------------------------------------------------
  // Overlay content builder
  // ---------------------------------------------------------------------------

  Widget _buildOverlayContent(TourActive state, Rect targetRect) {
    final screen = MediaQuery.of(context).size;
    const padding = 8.0;
    const borderRadius = 12.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dimmed backdrop with cutout (covers full screen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _tourNotifier.skip(),
                child: CustomPaint(
                  size: screen,
                  painter: _SpotlightPainter(
                    targetRect: targetRect,
                    padding: padding,
                    borderRadius: borderRadius,
                  ),
                ),
              ),
            ),

            // Tooltip positioned near the target, respecting safe area
            Positioned(
              left: _tooltipLeft(targetRect, screen),
              top: _tooltipTop(targetRect, screen),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: TourTooltip(
                  step: state.currentStep,
                  stepIndex: state.currentStepIndex,
                  totalSteps: state.steps.length,
                  onNext: () => _tourNotifier.advance(),
                  onSkip: () => _tourNotifier.skip(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _tooltipLeft(Rect target, Size screen) {
    final center = target.center.dx - 140; // half of maxWidth (280)
    return center.clamp(16.0, screen.width - 296);
  }

  double _tooltipTop(Rect target, Size screen) {
    const gap = 12.0;
    const pad = 8.0;
    const tooltipHeight = 160.0;
    final safePadding = MediaQuery.of(context).padding;
    // Prefer below the target, but stay above the bottom nav bar
    final below = target.bottom + pad + gap;
    if (below + tooltipHeight + safePadding.bottom < screen.height) {
      return below;
    }
    // Otherwise above, but stay below the status bar
    final above = target.top - pad - gap - tooltipHeight;
    return above.clamp(safePadding.top + gap, screen.height - tooltipHeight);
  }
}

// ---------------------------------------------------------------------------
// Custom painter — semi-transparent fill with a transparent cutout
// ---------------------------------------------------------------------------

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.targetRect,
    required this.padding,
    required this.borderRadius,
  });

  final Rect targetRect;
  final double padding;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;

    final cutout = RRect.fromRectAndRadius(
      targetRect.inflate(padding),
      Radius.circular(borderRadius),
    );

    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(cutout)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect;
}
