// ──────────────────────────────────────────────────────────
// Unified Session Data Models (display-only, server-sourced)
// ──────────────────────────────────────────────────────────

/// A single performed set in the unified detail view.
class UnifiedSet {
  const UnifiedSet({
    required this.id,
    required this.setNumber,
    required this.repsCompleted,
    this.weightKg,
    this.rpe,
  });

  final String id;
  final int setNumber;
  final int repsCompleted;
  final double? weightKg;

  /// Rate of Perceived Exertion (only available for coach sessions).
  final double? rpe;

  double get volume => repsCompleted * (weightKg ?? 0);

  factory UnifiedSet.fromJson(Map<String, dynamic> json) => UnifiedSet(
        id: json['id'] as String,
        setNumber: (json['setNumber'] as num).toInt(),
        repsCompleted: (json['repsCompleted'] as num).toInt(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        rpe: (json['rpe'] as num?)?.toDouble(),
      );
}

/// A group of sets for a single exercise.
class UnifiedExerciseGroup {
  const UnifiedExerciseGroup({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.totalVolumeKg,
  });

  final String exerciseId;
  final String exerciseName;
  final List<UnifiedSet> sets;
  final double totalVolumeKg;

  int get totalReps => sets.fold(0, (s, e) => s + e.repsCompleted);

  /// The heaviest weight used in this exercise (null if no weight).
  double? get maxWeightKg {
    final weights = sets
        .map((s) => s.weightKg ?? 0.0)
        .where((w) => w > 0)
        .toList();
    if (weights.isEmpty) return null;
    return weights.reduce((a, b) => a > b ? a : b);
  }

  factory UnifiedExerciseGroup.fromJson(Map<String, dynamic> json) =>
      UnifiedExerciseGroup(
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        sets: (json['sets'] as List)
            .map((s) => UnifiedSet.fromJson(s as Map<String, dynamic>))
            .toList(),
        totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
      );
}

/// Full unified session detail — works for both coach and standalone sessions.
class UnifiedSessionDetail {
  const UnifiedSessionDetail({
    required this.id,
    required this.source,
    required this.routineName,
    this.programName,
    required this.startedAt,
    this.completedAt,
    this.durationMinutes,
    this.notes,
    required this.exercises,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolumeKg,
  });

  final String id;

  /// 'coach' or 'standalone'
  final String source;

  final String routineName;
  final String? programName;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationMinutes;
  final String? notes;
  final List<UnifiedExerciseGroup> exercises;
  final int totalSets;
  final int totalReps;
  final double totalVolumeKg;

  bool get isCoach => source == 'coach';
  bool get isCompleted => completedAt != null;

  String get durationDisplay {
    if (durationMinutes == null) return '—';
    final h = durationMinutes! ~/ 60;
    final m = durationMinutes! % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  factory UnifiedSessionDetail.fromJson(Map<String, dynamic> json) =>
      UnifiedSessionDetail(
        id: json['id'] as String,
        source: json['source'] as String,
        routineName: json['routineName'] as String,
        programName: json['programName'] as String?,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
        notes: json['notes'] as String?,
        exercises: (json['exercises'] as List)
            .map((e) => UnifiedExerciseGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalSets: (json['totalSets'] as num).toInt(),
        totalReps: (json['totalReps'] as num).toInt(),
        totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
      );
}
