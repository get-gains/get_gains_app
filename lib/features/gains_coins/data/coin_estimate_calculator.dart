import 'dart:math';

import 'models/coin_estimate_model.dart';

/// Offline Coin Estimate Calculator
///
/// Pure Dart utility that mirrors the server coin calculation formula
/// for local estimation when offline (R-007).
///
/// Formula: (sets × COINS_PER_SET × accuracyMultiplier) + completionBonus + durationBonus + streakBonus
///
/// Estimates are clearly labeled as approximate — the server is the
/// sole authority on actual coin awards (FR-007).
class CoinEstimateCalculator {
  CoinEstimateCalculator._();

  // ── Default economy config values (mirrors server defaults) ──

  static const int _coinsPerSet = 3;
  static const int _completionBonus = 10;
  static const int _streakBonusPerDay = 2;
  static const int _streakBonusCap = 20;

  static const List<({int minMinutes, int bonus})> _durationBonusTiers = [
    (minMinutes: 60, bonus: 15),
    (minMinutes: 45, bonus: 8),
    (minMinutes: 30, bonus: 3),
  ];

  static const List<({double min, String label, double multiplier})>
  _accuracyTiers = [
    (min: 0.95, label: 'Perfect', multiplier: 1.7),
    (min: 0.85, label: 'Great', multiplier: 1.3),
    (min: 0.70, label: 'Good', multiplier: 1.0),
    (min: 0.50, label: 'Fair', multiplier: 0.8),
    (min: 0.0, label: 'Low', multiplier: 0.5),
  ];

  /// Calculate an estimated coin reward for a completed session.
  ///
  /// Parameters:
  /// - [setsCompleted]: Number of performed sets in the session (exact, known locally)
  /// - [sessionDurationMin]: Session duration in minutes (exact, from startedAt to completedAt)
  /// - [avgAccuracy]: Average overallScore from FormComparisonResults (0.0–1.0).
  ///   If no form data is available locally, pass 1.0 as default.
  /// - [streakDays]: Current streak value from cached weekly stats. Pass 0 if unknown.
  static CoinEstimateModel estimate({
    required int setsCompleted,
    required int sessionDurationMin,
    double avgAccuracy = 1.0,
    int streakDays = 0,
  }) {
    // Resolve accuracy tier (top-down matching, first qualifying tier)
    final accuracyTier = _resolveAccuracyTier(avgAccuracy);

    // Calculate components
    final setCoins = (setsCompleted * _coinsPerSet * accuracyTier.multiplier)
        .round();
    final durationBonus = _resolveDurationBonus(sessionDurationMin);
    final streakBonus = min(streakDays * _streakBonusPerDay, _streakBonusCap);
    final total = setCoins + _completionBonus + durationBonus + streakBonus;

    return CoinEstimateModel(
      estimatedTotal: total,
      setCoins: setCoins,
      accuracyMultiplier: accuracyTier.multiplier,
      accuracyLabel: accuracyTier.label,
      completionBonus: _completionBonus,
      durationBonus: durationBonus,
      streakBonus: streakBonus,
      streakValue: streakDays,
      setsCompleted: setsCompleted,
      sessionDurationMin: sessionDurationMin,
      isEstimate: true,
    );
  }

  /// Resolve accuracy tier from average overallScore.
  static ({double multiplier, String label}) _resolveAccuracyTier(
    double avgAccuracy,
  ) {
    for (final tier in _accuracyTiers) {
      if (avgAccuracy >= tier.min) {
        return (multiplier: tier.multiplier, label: tier.label);
      }
    }
    // Fallback (should not happen if 0.0 tier exists)
    return (multiplier: 0.5, label: 'Low');
  }

  /// Resolve duration bonus from session length in minutes.
  static int _resolveDurationBonus(int durationMin) {
    for (final tier in _durationBonusTiers) {
      if (durationMin >= tier.minMinutes) {
        return tier.bonus;
      }
    }
    return 0;
  }
}
