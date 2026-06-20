/// Monthly Training Insight Model
///
/// Server response for `GET /api/stats/monthly-insight?month=YYYY-MM`.
/// Contains normalized avg volume/session, trend %, 6-month sparkline,
/// and top exercise weight improvements.
class MonthlyInsight {
  final String month;
  final double avgVolumePerSession;
  final int? percentChange;
  final double totalVolumeKg;
  final int totalSessions;
  final List<double?> sparkline;
  final List<double> sparklineVolumes;
  final List<int> sparklineSessions;
  final List<ExerciseImprovement> exerciseImprovements;

  const MonthlyInsight({
    required this.month,
    required this.avgVolumePerSession,
    this.percentChange,
    required this.totalVolumeKg,
    required this.totalSessions,
    required this.sparkline,
    required this.sparklineVolumes,
    required this.sparklineSessions,
    required this.exerciseImprovements,
  });

  factory MonthlyInsight.fromJson(Map<String, dynamic> json) {
    return MonthlyInsight(
      month: json['month'] as String,
      avgVolumePerSession: (json['avgVolumePerSession'] as num).toDouble(),
      percentChange: json['percentChange'] as int?,
      totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
      totalSessions: (json['totalSessions'] as num).toInt(),
      sparkline: (json['sparkline'] as List<dynamic>?)
              ?.map((v) => v == null ? null : (v as num).toDouble())
              .toList() ??
          const [],
      sparklineVolumes: (() {
        final raw = json['sparklineVolumes'];
        if (raw is List) {
          return raw.map((v) => (v as num).toDouble()).toList();
        }
        return <double>[];
      })(),
      sparklineSessions: (() {
        final raw = json['sparklineSessions'];
        if (raw is List) {
          return raw.map((v) => (v as num).toInt()).toList();
        }
        return <int>[];
      })(),
      exerciseImprovements:
          (json['exerciseImprovements'] as List<dynamic>?)
                  ?.map((e) =>
                      ExerciseImprovement.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              const [],
    );
  }

  bool get hasActivity => totalSessions > 0;

  /// e.g. "210 kg/session"
  String get volumeDisplay => '${avgVolumePerSession.round()} kg/session';

  /// e.g. "+12%" or "−5%" or null if no previous data
  String? get trendDisplay {
    if (percentChange == null) return null;
    if (percentChange! > 0) return '+$percentChange%';
    return '$percentChange%';
  }

  bool get trendIsPositive => (percentChange ?? 0) > 0;
}

/// A single exercise with weight improvement vs previous month.
class ExerciseImprovement {
  final String exerciseName;
  final double currentAvgWeight;
  final double previousAvgWeight;
  final int percentChange;

  const ExerciseImprovement({
    required this.exerciseName,
    required this.currentAvgWeight,
    required this.previousAvgWeight,
    required this.percentChange,
  });

  factory ExerciseImprovement.fromJson(Map<String, dynamic> json) {
    return ExerciseImprovement(
      exerciseName: json['exerciseName'] as String,
      currentAvgWeight: (json['currentAvgWeight'] as num).toDouble(),
      previousAvgWeight: (json['previousAvgWeight'] as num).toDouble(),
      percentChange: (json['percentChange'] as num).toInt(),
    );
  }

  /// e.g. "+8%" 
  String get changeDisplay => '+$percentChange%';

  /// e.g. "52 → 56 kg"
  String get weightRange =>
      '${previousAvgWeight.round()} → ${currentAvgWeight.round()} kg';
}
