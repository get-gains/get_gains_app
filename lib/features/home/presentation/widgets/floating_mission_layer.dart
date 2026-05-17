// lib/features/home/presentation/widgets/floating_mission_layer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/home/data/services/floating_mission_position_store.dart';
import '../../../../features/home/presentation/providers/floating_mission_provider.dart';
import 'floating_mission_badge.dart';

/// Overlay layer that renders up to 3 floating mission badges.
///
/// Positioned as a [Stack] child above the scroll view so badges are
/// not consumed by the scrollable. Renders nothing when there are
/// no in-progress missions.
///
/// @param screenSize Full screen dimensions for safe-area clamping.
/// @param bottomNavHeight Bottom nav height for badge clamping.
/// @param topInset Top safe-area inset.
class FloatingMissionLayer extends ConsumerStatefulWidget {
  const FloatingMissionLayer({
    super.key,
    required this.screenSize,
    required this.bottomNavHeight,
    required this.topInset,
  });

  final Size screenSize;
  final double bottomNavHeight;
  final double topInset;

  @override
  ConsumerState<FloatingMissionLayer> createState() =>
      _FloatingMissionLayerState();
}

class _FloatingMissionLayerState extends ConsumerState<FloatingMissionLayer> {
  final Set<String> _hiddenToday = {};

  @override
  Widget build(BuildContext context) {
    final missionAsync = ref.watch(floatingMissionsProvider);

    return missionAsync.when(
      data: (missions) {
        final visible = missions
            .where((m) => !_hiddenToday.contains(m.id))
            .toList();

        if (visible.isEmpty) return const SizedBox.shrink();

        return FutureBuilder<List<Offset>>(
          future: _loadPositions(visible.map((m) => m.id).toList()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final offsets = snapshot.data!;

            return Stack(
              children: [
                for (var i = 0; i < visible.length; i++)
                  FloatingMissionBadge(
                    key: ValueKey(visible[i].id),
                    mission: visible[i],
                    initialOffset: offsets[i],
                    screenSize: widget.screenSize,
                    bottomNavHeight: widget.bottomNavHeight,
                    topInset: widget.topInset,
                    onHide: () => setState(() => _hiddenToday.add(visible[i].id)),
                  ),
              ],
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<List<Offset>> _loadPositions(List<String> ids) async {
    final store = ref.read(floatingMissionPositionStoreProvider);
    final offsets = <Offset>[];
    final defaults = _defaultOffsets(ids.length);

    for (var i = 0; i < ids.length; i++) {
      final saved = await store.loadPosition(ids[i]);
      if (saved != null) {
        offsets.add(Offset(saved.$1, saved.$2));
      } else {
        offsets.add(defaults[i]);
      }
    }
    return offsets;
  }

  /// Default corner offsets so badges don't overlap on first launch.
  List<Offset> _defaultOffsets(int count) {
    final w = widget.screenSize.width;
    return [
      Offset(w - 56, 160),
      Offset(w - 56, 240),
      Offset(w - 56, 320),
    ].take(count).toList();
  }
}
