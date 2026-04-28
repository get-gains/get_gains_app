import 'package:flutter/material.dart';

import '../../../../core/utils/logger.dart';

/// Full-screen dimming overlay with a rounded-rect cutout around a target widget.
///
/// Uses [Overlay] to render above all other content. The cutout is painted via
/// [CustomPainter] with an inverted clip. Taps outside the cutout and the
/// [child] widget trigger [onDismiss].
class SpotlightOverlay extends StatefulWidget {
  const SpotlightOverlay({
    super.key,
    required this.targetKey,
    required this.child,
    required this.onDismiss,
    this.padding = 8.0,
    this.borderRadius = 12.0,
  });

  /// [GlobalKey] attached to the widget to highlight.
  final GlobalKey targetKey;

  /// Widget to position near the cutout (typically a [TourTooltip]).
  final Widget child;

  /// Called when the user taps outside the cutout / child or the target is
  /// not mounted.
  final VoidCallback onDismiss;

  /// Extra padding around the target bounds for the cutout.
  final double padding;

  /// Corner radius of the cutout rectangle.
  final double borderRadius;

  @override
  State<SpotlightOverlay> createState() => SpotlightOverlayState();
}

class SpotlightOverlayState extends State<SpotlightOverlay>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  Rect? _targetRect;

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
    hide();
    _animController.dispose();
    super.dispose();
  }

  /// Measure the target widget and show the overlay.
  void show() {
    _targetRect = _measureTarget();
    if (_targetRect == null) {
      AppLogger.warning(
        'SpotlightOverlay: target key not mounted, skipping',
        tag: 'SpotlightOverlay',
      );
      widget.onDismiss();
      return;
    }

    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();
  }

  /// Animate out and remove the overlay.
  Future<void> hide() async {
    if (_overlayEntry == null) return;
    await _animController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Re-measure and rebuild for a new target (e.g. step change).
  void updateTarget() {
    _targetRect = _measureTarget();
    _overlayEntry?.markNeedsBuild();
  }

  Rect? _measureTarget() {
    final ctx = widget.targetKey.currentContext;
    if (ctx == null) return null;

    // Scroll target into view first if needed.
    final scrollable = Scrollable.maybeOf(ctx);
    if (scrollable != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.5,
      );
    }

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  Widget _buildOverlay() {
    final screen = MediaQuery.of(context).size;
    final rect = _targetRect;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dimmed backdrop with cutout
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: CustomPaint(
                  size: screen,
                  painter: _SpotlightPainter(
                    targetRect: rect,
                    padding: widget.padding,
                    borderRadius: widget.borderRadius,
                  ),
                ),
              ),
            ),

            // Tooltip positioned near the target
            if (rect != null)
              Positioned(
                left: _tooltipLeft(rect, screen),
                top: _tooltipTop(rect, screen),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 280),
                  child: widget.child,
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _tooltipLeft(Rect target, Size screen) {
    // Center tooltip horizontally on target, clamped to screen edges.
    final center = target.center.dx - 140; // half of maxWidth (280)
    return center.clamp(16.0, screen.width - 296);
  }

  double _tooltipTop(Rect target, Size screen) {
    const gap = 12.0;
    final pad = widget.padding;
    // Prefer below the target
    final below = target.bottom + pad + gap;
    if (below + 160 < screen.height) return below;
    // Otherwise above
    return target.top - pad - gap - 160;
  }

  @override
  Widget build(BuildContext context) {
    // This widget is invisible in the tree — rendering goes through Overlay.
    return const SizedBox.shrink();
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

  final Rect? targetRect;
  final double padding;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;

    if (targetRect == null) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }

    final cutout = RRect.fromRectAndRadius(
      targetRect!.inflate(padding),
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
