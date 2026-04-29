// lib/features/home/data/services/floating_mission_position_store.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'floating_mission_position_store.g.dart';

const String _boxName = 'floating_missions_box';

/// Hive-backed store for floating mission badge positions and hide-until timestamps.
///
/// Opens its own Hive box on first access — no main.dart wiring needed.
@Riverpod(keepAlive: true)
FloatingMissionPositionStore floatingMissionPositionStore(Ref ref) {
  return FloatingMissionPositionStore();
}

class FloatingMissionPositionStore {
  Box<dynamic>? _box;

  Future<Box<dynamic>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<dynamic>(_boxName);
    return _box!;
  }

  /// Returns the saved [dx, dy] for [missionId], or null if not yet saved.
  Future<(double, double)?> loadPosition(String missionId) async {
    final box = await _getBox();
    final raw = box.get('pos_$missionId');
    if (raw is! List || raw.length < 2) return null;
    return ((raw[0] as num).toDouble(), (raw[1] as num).toDouble());
  }

  /// Persists the badge position for [missionId].
  Future<void> savePosition(String missionId, double dx, double dy) async {
    final box = await _getBox();
    await box.put('pos_$missionId', [dx, dy]);
  }

  /// Returns true if [missionId] badge is hidden until a future time today.
  Future<bool> isHiddenToday(String missionId) async {
    final box = await _getBox();
    final raw = box.get('hide_$missionId');
    if (raw is! String) return false;
    final until = DateTime.tryParse(raw);
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  /// Hides the badge for [missionId] until the end of the current day.
  Future<void> hideForToday(String missionId) async {
    final box = await _getBox();
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    await box.put('hide_$missionId', endOfDay.toIso8601String());
  }
}
