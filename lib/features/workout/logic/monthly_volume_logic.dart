/// Pure logic for the Total Volume per Month card.
///
/// Zero Flutter dependencies — all functions operate on plain Dart types
/// so they can be tested without a widget tree.
library;

import 'package:intl/intl.dart';

import '../data/models/monthly_volume_model.dart';

/// Normalizes a list of monthly total-volume values to proportional bar
/// heights in the range [0.05, 1.0].
///
/// - All bars get at least 0.05 (a visible stub even for zero/null months).
/// - Heights are scaled relative to the maximum value in [volumes].
/// - Returns one [double] per input element, in the same order.
List<double> normalizeBarHeights(List<MonthlyVolume> volumes) {
  if (volumes.isEmpty) return const [];

  final maxVolume =
      volumes.fold(0.0, (max, v) => v.totalVolume > max ? v.totalVolume : max);

  if (maxVolume <= 0) {
    return List.filled(volumes.length, 0.05);
  }

  return volumes
      .map((v) => (v.totalVolume / maxVolume).clamp(0.05, 1.0))
      .toList();
}

/// Returns `true` when the percent change is meaningful enough to show.
///
/// Hides the pill for null (oldest month) or when the absolute change is
/// less than 3 % — tiny fluctuations aren't actionable.
bool shouldShowPercentChange(double? percentChange) {
  if (percentChange == null) return false;
  return percentChange.abs() >= 3.0;
}

/// Returns `true` when the session count is too low for a reliable average.
///
/// Fewer than 3 sessions in a month means one heavy day can skew the
/// number — the UI appends " · low confidence" to signal this.
bool isLowConfidence(int sessionCount) {
  return sessionCount < 3;
}

/// Formats a kilogram value with thousands separator.
///
/// | Input     | Output       |
/// |-----------|--------------|
/// | 1234.56   | "1,235 kg"   |
/// | 5000      | "5,000 kg"   |
/// | 0         | "0 kg"       |
String formatKg(double kg) {
  final fmt = NumberFormat('#,###');
  return '${fmt.format(kg.round())} kg';
}
