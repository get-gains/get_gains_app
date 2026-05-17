// lib/features/home/presentation/widgets/floating_mission_badge.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/gains_coins/data/models/mission_list_item_model.dart';
import '../../../../features/home/data/services/floating_mission_position_store.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';

const double _badgeSize = 64.0;
const double _badgeRadius = _badgeSize / 2;

/// A draggable floating badge representing a single in-progress mission.
///
/// Lifecycle:
/// - Idle: slow vertical drift + pulse via explicit animation controllers.
/// - Long-press start: scale 1.1, intensified shadow, haptic.
/// - Drag: follows pointer; persists final position to Hive on release.
/// - Tap: navigates to mission detail screen.
/// - Long-press hold >1 s: context menu (open, hide today, view all).
///
/// @param mission Mission to display.
/// @param initialOffset Starting position (restored from Hive or default).
/// @param screenSize Available screen dimensions for clamping.
/// @param bottomNavHeight Height of the bottom nav bar for safe-area clamping.
/// @param onHide Called when the user chooses "Hide for today".
class FloatingMissionBadge extends ConsumerStatefulWidget {
  const FloatingMissionBadge({
    super.key,
    required this.mission,
    required this.initialOffset,
    required this.screenSize,
    required this.bottomNavHeight,
    required this.topInset,
    this.onHide,
  });

  final MissionListItemModel mission;
  final Offset initialOffset;
  final Size screenSize;
  final double bottomNavHeight;
  final double topInset;
  final VoidCallback? onHide;

  @override
  ConsumerState<FloatingMissionBadge> createState() =>
      _FloatingMissionBadgeState();
}

class _FloatingMissionBadgeState extends ConsumerState<FloatingMissionBadge>
    with TickerProviderStateMixin {
  late Offset _position;
  bool _isDragging = false;
  bool _isPressed = false;

  late final AnimationController _driftController;
  late final AnimationController _pulseController;
  late final Animation<double> _driftAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _position = widget.initialOffset;

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _driftAnim = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _driftController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _driftController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Offset _clampToSafeArea(Offset pos) {
    const minX = 24.0 + _badgeRadius;
    const minY = 96.0 + _badgeRadius;
    final maxX = widget.screenSize.width - 24 - _badgeRadius;
    final maxY =
        widget.screenSize.height - widget.bottomNavHeight - 24 - _badgeRadius;

    return Offset(
      pos.dx.clamp(minX, maxX),
      pos.dy.clamp(minY, maxY),
    );
  }

  void _onTap() {
    context.push('/missions/${widget.mission.id}');
  }

  void _onLongPressHold() {
    HapticFeedback.mediumImpact();
    _showContextMenu();
  }

  void _showContextMenu() {
    showAppBottomSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              widget.mission.title,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open mission'),
            onTap: () {
              Navigator.pop(ctx);
              _onTap();
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: const Text('Hide for today'),
            onTap: () {
              Navigator.pop(ctx);
              ref
                  .read(floatingMissionPositionStoreProvider)
                  .hideForToday(widget.mission.id);
              widget.onHide?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('View all missions'),
            onTap: () {
              Navigator.pop(ctx);
              context.push(AppRoutes.missions);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.mission.goalToReach > 0
        ? (widget.mission.displayProgress / widget.mission.goalToReach)
            .clamp(0.0, 1.0)
        : 0.0;

    return Positioned(
      left: _position.dx - _badgeRadius,
      top: _position.dy - _badgeRadius,
      child: AnimatedBuilder(
        animation: Listenable.merge([_driftAnim, _pulseAnim]),
        builder: (context, child) {
          final drift = _isDragging ? 0.0 : _driftAnim.value;
          final pulse = _isDragging ? 1.1 : (_isPressed ? 1.05 : _pulseAnim.value);

          return Transform.translate(
            offset: Offset(0, drift),
            child: Transform.scale(
              scale: pulse,
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: _onTap,
          onLongPress: _onLongPressHold,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: LongPressDraggable<String>(
            data: widget.mission.id,
            delay: const Duration(milliseconds: 500),
            onDragStarted: () {
              HapticFeedback.lightImpact();
              setState(() => _isDragging = true);
            },
            onDragEnd: (details) {
              setState(() {
                _isDragging = false;
                _position = _clampToSafeArea(
                  details.offset + const Offset(_badgeRadius, _badgeRadius),
                );
              });
              ref
                  .read(floatingMissionPositionStoreProvider)
                  .savePosition(widget.mission.id, _position.dx, _position.dy);
            },
            onDraggableCanceled: (_, __) {
              setState(() => _isDragging = false);
            },
            feedback: _BadgeContent(
              ratio: ratio,
              mission: widget.mission,
              isPressed: true,
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _BadgeContent(ratio: ratio, mission: widget.mission),
            ),
            child: _BadgeContent(ratio: ratio, mission: widget.mission),
          ),
        ),
      ),
    );
  }
}

class _BadgeContent extends StatelessWidget {
  const _BadgeContent({
    required this.ratio,
    required this.mission,
    this.isPressed = false,
  });

  final double ratio;
  final MissionListItemModel mission;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _badgeSize,
      height: _badgeSize,
      child: CustomPaint(
        painter: _ProgressRingPainter(progress: ratio),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface2Dark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isPressed ? 0.5 : 0.3),
                  blurRadius: isPressed ? 16 : 8,
                  spreadRadius: isPressed ? 2 : 0,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.flag_rounded,
                color: AppColors.primaryDark,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final trackPaint = Paint()
      ..color = AppColors.surface3Dark
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = AppColors.primaryDark
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}
