import 'dart:math' as math;

import '../../../core/utils/logger.dart';
import '../../coach_pose/data/models/feature_frame_model.dart';
import '../data/models/body_segment.dart';
import '../data/models/models.dart';

/// Compares client's recorded form against coach's reference form using
/// Dynamic Time Warping (DTW) on extracted joint angle features.
///
/// DTW handles different movement speeds by finding the optimal alignment
/// between two time series, giving a similarity score independent of tempo.
class FormComparisonService {
  FormComparisonService();

  /// Compare client frames against reference (coach) frames.
  ///
  /// Returns a [ComparisonResultModel] with:
  /// - overallScore (0.0 - 1.0, higher = better match)
  /// - segmentScores per tracked angle
  /// - corrections for angles that deviate significantly
  ComparisonResultModel compare({
    required String exerciseFormId,
    required List<FeatureFrame> referenceFrames,
    required List<FeatureFrame> clientFrames,
    required String cameraAngle,
    String? workoutSessionId,
    String? routineExerciseId,
    double? avgLandmarkConfidence,
  }) {
    AppLogger.info(
      'Starting form comparison: ${referenceFrames.length} ref frames, '
      '${clientFrames.length} client frames',
      tag: 'FormComparison',
    );

    if (referenceFrames.isEmpty || clientFrames.isEmpty) {
      return ComparisonResultModel(
        exerciseFormId: exerciseFormId,
        workoutSessionId: workoutSessionId,
        routineExerciseId: routineExerciseId,
        overallScore: 0.0,
        segmentScores: defaultSegmentScores(),
        corrections: [],
        cameraAngle: cameraAngle,
        durationMs: 0,
        frameRate: 0,
        totalFrames: clientFrames.length,
        avgLandmarkConfidence: avgLandmarkConfidence,
      );
    }

    // Defensive guard: trim client frames to reference length (US3).
    // Callers should already trim, but this ensures DTW is always bounded.
    if (clientFrames.length > referenceFrames.length) {
      AppLogger.warning(
        'Client frames (${clientFrames.length}) exceed reference '
        '(${referenceFrames.length}) — trimming to reference length',
        tag: 'FormComparison',
      );
      clientFrames = clientFrames.sublist(0, referenceFrames.length);
    }

    // Collect all angle names present in both sequences
    final refAngles = _collectAngleNames(referenceFrames);
    final clientAngles = _collectAngleNames(clientFrames);
    final commonAngles = refAngles.intersection(clientAngles);

    if (commonAngles.isEmpty) {
      AppLogger.warning(
        'No common angles between reference and client',
        tag: 'FormComparison',
      );
      return ComparisonResultModel(
        exerciseFormId: exerciseFormId,
        workoutSessionId: workoutSessionId,
        routineExerciseId: routineExerciseId,
        overallScore: 0.0,
        segmentScores: defaultSegmentScores(),
        corrections: [],
        cameraAngle: cameraAngle,
        durationMs: _computeDurationMs(clientFrames),
        frameRate: _computeFrameRate(clientFrames),
        totalFrames: clientFrames.length,
        avgLandmarkConfidence: avgLandmarkConfidence,
      );
    }

    // Compute DTW score per angle with OOV-aware alignment
    final angleScores = <String, double>{};
    final angleCoverage = <String, double>{};
    final corrections = <CorrectionModel>[];

    /// Minimum coverage ratio for an angle to be included in scoring.
    const minCoverageRatio = 0.30;

    for (final angleName in commonAngles) {
      // Build aligned series: only frames where BOTH sides have the angle
      final aligned = _alignedSeries(referenceFrames, clientFrames, angleName);
      angleCoverage[angleName] = aligned.coverage;

      // Drop angles with insufficient coverage
      if (aligned.coverage < minCoverageRatio) {
        AppLogger.info(
          'Dropping angle $angleName: coverage ${(aligned.coverage * 100).toStringAsFixed(0)}% < ${(minCoverageRatio * 100).toStringAsFixed(0)}%',
          tag: 'FormComparison',
        );
        continue;
      }

      if (aligned.ref.length < 2 || aligned.client.length < 2) continue;

      // Drop angles where the reference barely moves — these carry no
      // coaching signal and inflate scores when both sides are near-static.
      // In production, detectRelevantAngles handles this upstream; this
      // gate is defense-in-depth for direct compare() calls and tests.
      final refROM =
          aligned.ref.reduce(math.max) - aligned.ref.reduce(math.min);
      const minRefRom = 5.0; // degrees
      if (refROM < minRefRom) {
        AppLogger.info(
          'Dropping angle $angleName: refROM ${refROM.toStringAsFixed(1)}° < $minRefRom°',
          tag: 'FormComparison',
        );
        continue;
      }

      final smoothedRef = _smooth(aligned.ref);
      final smoothedClient = _smooth(aligned.client);

      final (dtwDistance, pathLength) = _dtw(smoothedRef, smoothedClient);

      // Mean angular deviation per aligned frame pair
      final meanDev = pathLength > 0 ? dtwDistance / pathLength : 180.0;

      // --- Fix C: Tighter score mapping (4°/30° moderate) ---
      final adjustedDev = math.max(0.0, meanDev - 4.0);
      final baseScore = (1.0 - adjustedDev / 30.0).clamp(0.0, 1.0);

      // --- Fix B: Bidirectional ROM penalty ---
      // Penalises when the client's range-of-motion deviates significantly
      // from the reference in either direction (too much or too little movement).
      // refROM already computed above for the minRefRom gate.
      final clientROM =
          aligned.client.reduce(math.max) - aligned.client.reduce(math.min);
      final romRatio = refROM > 1.0 ? clientROM / refROM : 1.0;
      final romDeviation = (romRatio - 1.0).abs();
      // Tolerance: ±60% ROM difference is acceptable (covers natural variation).
      // Beyond that, ramp penalty over next 1.4 units to a max of 50% reduction.
      const romTolerance = 0.6;
      const romRampRange = 1.4;
      const maxRomPenalty = 0.5;
      final romPenalty = romDeviation <= romTolerance
          ? 0.0
          : ((romDeviation - romTolerance) / romRampRange).clamp(0.0, 1.0) *
                maxRomPenalty;
      final romFactor = 1.0 - romPenalty;

      // --- Fix D: Shift-invariant Pearson correlation factor ---
      // Catches pattern mismatch that DTW masks by warping. Uses peak
      // cross-correlation: finds the temporal lag that maximizes Pearson,
      // so correct form with a phase offset still scores high while wrong
      // exercises can't be salvaged by any shift.
      final pearsonR = _peakCrossCorrelation(smoothedRef, smoothedClient);
      final correlationFactor = pearsonR.clamp(0.0, 1.0);
      // strong-pattern (r≈1) → ×1.0, no-pattern (r≈0) → ×0.5, anti-pattern → ×0.5
      final pearsonMultiplier = 0.5 + 0.5 * correlationFactor;

      final score = (baseScore * romFactor * pearsonMultiplier).clamp(0.0, 1.0);
      angleScores[angleName] = score;

      // Ship 1 diagnostics: per-angle breakdown for tuning
      AppLogger.info(
        '[DIAG] angle=$angleName | meanDev=${meanDev.toStringAsFixed(2)}° '
        '| adjustedDev=${adjustedDev.toStringAsFixed(2)}° | baseScore=${(baseScore * 100).toStringAsFixed(1)}% '
        '| romRatio=${romRatio.toStringAsFixed(2)} | romFactor=${romFactor.toStringAsFixed(2)} '
        '| pearsonR=${pearsonR.toStringAsFixed(3)} | pearsonMul=${pearsonMultiplier.toStringAsFixed(2)} '
        '| finalScore=${(score * 100).toStringAsFixed(1)}% '
        '| coverage=${(aligned.coverage * 100).toStringAsFixed(0)}% '
        '| refROM=${refROM.toStringAsFixed(1)}° | clientROM=${clientROM.toStringAsFixed(1)}° '
        '| pathLen=$pathLength | dtwDist=${dtwDistance.toStringAsFixed(1)}',
        tag: 'FormComparison',
      );

      // Generate correction if score is below threshold
      if (score < 0.7) {
        final avgDev = meanDev;
        final maxDev = _maxDeviation(smoothedRef, smoothedClient);
        final direction = _inferDirection(aligned.ref, aligned.client);
        final segment = _angleToSegment(angleName).name;

        corrections.add(
          CorrectionModel(
            angleName: angleName,
            segment: segment,
            avgDeviation: avgDev,
            maxDeviation: maxDev,
            direction: direction,
            message: _generateCorrectionMessage(angleName, direction, avgDev),
          ),
        );
      }
    }

    // Aggregate per-angle scores into body-segment scores
    final segmentScores = _aggregateSegmentScores(angleScores);

    // --- Fix F: Coverage-weighted overall score ---
    // Angles with higher coverage (more visible frames) contribute more.
    final double overallScore;
    if (angleScores.isEmpty) {
      overallScore = 0.0;
      // All angles dropped — tell the user why
      corrections.add(
        CorrectionModel(
          angleName: 'visibility',
          segment: BodySegment.FULL_BODY.name,
          avgDeviation: 0,
          maxDeviation: 0,
          direction: 'insufficient_visibility',
          message:
              'Could not see enough of your body to assess form. '
              'Make sure your full body is in frame.',
        ),
      );
    } else {
      double weightedSum = 0;
      double weightSum = 0;
      for (final entry in angleScores.entries) {
        final w = angleCoverage[entry.key] ?? 1.0;
        weightedSum += entry.value * w;
        weightSum += w;
      }
      overallScore = weightSum > 0 ? weightedSum / weightSum : 0.0;
    }

    // Ship 1 diagnostics: summary of all angle scores
    AppLogger.info(
      '[DIAG] === COMPARISON SUMMARY === '
      '| angles scored: ${angleScores.length} '
      '| overall: ${(overallScore * 100).toStringAsFixed(1)}% '
      '| angle scores: ${angleScores.entries.map((e) => '${e.key}=${(e.value * 100).toStringAsFixed(1)}%').join(', ')}',
      tag: 'FormComparison',
    );

    final result = ComparisonResultModel(
      exerciseFormId: exerciseFormId,
      workoutSessionId: workoutSessionId,
      routineExerciseId: routineExerciseId,
      overallScore: overallScore,
      segmentScores: segmentScores,
      corrections: corrections,
      cameraAngle: cameraAngle,
      durationMs: _computeDurationMs(clientFrames),
      frameRate: _computeFrameRate(clientFrames),
      totalFrames: clientFrames.length,
      avgLandmarkConfidence: avgLandmarkConfidence,
      angleCoverage: angleCoverage,
    );

    AppLogger.info(
      'Comparison complete: overall=${(overallScore * 100).toStringAsFixed(1)}%, '
      '${corrections.length} corrections',
      tag: 'FormComparison',
    );

    return result;
  }

  /// Classic DTW algorithm with Sakoe-Chiba band — returns (accumulated distance, path length).
  ///
  /// [bandRatio] constrains warping to ±(bandRatio × max(n, m)) cells around
  /// the diagonal, preventing unbounded tempo warping.
  (double, int) _dtw(List<double> s, List<double> t, {double bandRatio = 0.2}) {
    final n = s.length;
    final m = t.length;
    final band = math.max(1, (math.max(n, m) * bandRatio).ceil());
    final dtw = List.generate(
      n + 1,
      (_) => List.filled(m + 1, double.infinity),
    );
    final pathLen = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    dtw[0][0] = 0;

    for (int i = 1; i <= n; i++) {
      final jStart = math.max(1, i - band);
      final jEnd = math.min(m, i + band);
      for (int j = jStart; j <= jEnd; j++) {
        final cost = (s[i - 1] - t[j - 1]).abs();
        final prevs = [
          dtw[i - 1][j], // insertion
          dtw[i][j - 1], // deletion
          dtw[i - 1][j - 1], // match
        ];
        final minPrev = prevs.reduce(math.min);
        dtw[i][j] = cost + minPrev;

        // Track path length through the same predecessor
        if (minPrev == dtw[i - 1][j - 1]) {
          pathLen[i][j] = pathLen[i - 1][j - 1] + 1;
        } else if (minPrev == dtw[i - 1][j]) {
          pathLen[i][j] = pathLen[i - 1][j] + 1;
        } else {
          pathLen[i][j] = pathLen[i][j - 1] + 1;
        }
      }
    }

    return (dtw[n][m], pathLen[n][m]);
  }

  /// Sliding-window average smoother to reduce frame-to-frame jitter.
  List<double> _smooth(List<double> series, {int window = 3}) {
    if (series.length <= window) return series;
    final half = window ~/ 2;
    return List.generate(series.length, (i) {
      final start = math.max(0, i - half);
      final end = math.min(series.length, i + half + 1);
      double sum = 0;
      for (int k = start; k < end; k++) {
        sum += series[k];
      }
      return sum / (end - start);
    });
  }

  Set<String> _collectAngleNames(List<FeatureFrame> frames) {
    final names = <String>{};
    for (final f in frames) {
      names.addAll(f.angles.keys);
    }
    return names;
  }

  List<double> _extractAngleSeries(List<FeatureFrame> frames, String name) {
    return frames
        .where((f) => f.angles.containsKey(name))
        .map((f) => f.angles[name]!)
        .toList();
  }

  /// Build aligned series for [angleName]: only frames where BOTH ref and
  /// client have the angle are kept. Returns the paired lists and the
  /// coverage ratio (frames available / max sequence length).
  ({List<double> ref, List<double> client, double coverage}) _alignedSeries(
    List<FeatureFrame> refFrames,
    List<FeatureFrame> clientFrames,
    String angleName,
  ) {
    final n = math.min(refFrames.length, clientFrames.length);
    final r = <double>[];
    final c = <double>[];
    for (var i = 0; i < n; i++) {
      final a = refFrames[i].angles[angleName];
      final b = clientFrames[i].angles[angleName];
      if (a != null && b != null) {
        r.add(a);
        c.add(b);
      }
    }
    return (ref: r, client: c, coverage: n > 0 ? r.length / n : 0.0);
  }

  double _maxDeviation(List<double> ref, List<double> client) {
    double maxDev = 0;
    final len = math.min(ref.length, client.length);
    for (int i = 0; i < len; i++) {
      maxDev = math.max(maxDev, (ref[i] - client[i]).abs());
    }
    return maxDev;
  }

  String _inferDirection(List<double> ref, List<double> client) {
    final len = math.min(ref.length, client.length);
    double totalDiff = 0;
    for (int i = 0; i < len; i++) {
      totalDiff += client[i] - ref[i];
    }
    final avgDiff = totalDiff / len;

    if (avgDiff > 5) return 'too_extended';
    if (avgDiff < -5) return 'too_shallow';
    return 'inconsistent';
  }

  /// Maps an angle name to its body segment enum value.
  BodySegment _angleToSegment(String angleName) {
    if (angleName.contains('Knee') || angleName.contains('Ankle')) {
      return angleName.startsWith('left')
          ? BodySegment.LEFT_LEG
          : BodySegment.RIGHT_LEG;
    }
    if (angleName.contains('Hip')) return BodySegment.TORSO;
    if (angleName.contains('Elbow') || angleName.contains('Shoulder')) {
      return angleName.startsWith('left')
          ? BodySegment.LEFT_ARM
          : BodySegment.RIGHT_ARM;
    }
    if (angleName.contains('torso')) return BodySegment.TORSO;
    return BodySegment.FULL_BODY;
  }

  /// Returns a default segment scores map with 0.0 for all segments.
  static Map<String, double> defaultSegmentScores() {
    return {for (final segment in BodySegment.values) segment.name: 0.0};
  }

  /// Aggregates per-angle scores into body-segment scores.
  ///
  /// Groups each angle score by its [BodySegment] via [_angleToSegment],
  /// computes the arithmetic mean per segment, and adds a [BodySegment.FULL_BODY]
  /// entry as the mean of all individual angle scores.
  ///
  /// Always returns all [BodySegment] keys — the server's Zod schema
  /// requires every key to be present.
  Map<String, double> _aggregateSegmentScores(Map<String, double> angleScores) {
    if (angleScores.isEmpty) return defaultSegmentScores();

    // Group angle scores by body segment
    final groups = <BodySegment, List<double>>{};
    for (final entry in angleScores.entries) {
      final segment = _angleToSegment(entry.key);
      // Skip FULL_BODY from grouping — it's computed separately
      if (segment == BodySegment.FULL_BODY) continue;
      groups.putIfAbsent(segment, () => []).add(entry.value);
    }

    final result = <String, double>{};

    // Ensure every BodySegment key is present (the server's Zod schema
    // requires all BodySegmentEnum keys in segmentScores). Segments without
    // matching angles default to 0.0.
    for (final segment in BodySegment.values) {
      if (segment == BodySegment.FULL_BODY) continue;
      final scores = groups[segment];
      result[segment.name] = scores != null && scores.isNotEmpty
          ? scores.reduce((a, b) => a + b) / scores.length
          : 0.0;
    }

    // FULL_BODY = mean of all individual angle scores
    result[BodySegment.FULL_BODY.name] =
        angleScores.values.reduce((a, b) => a + b) / angleScores.length;

    return result;
  }

  String _generateCorrectionMessage(
    String angleName,
    String direction,
    double avgDev,
  ) {
    final anglePretty = angleName
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (m) => ' ${m.group(0)!.toLowerCase()}',
        )
        .trim();

    return switch (direction) {
      'too_extended' =>
        'Your $anglePretty is too extended by ~${avgDev.toStringAsFixed(0)}°. Try to match the coach\'s range.',
      'too_shallow' =>
        'Your $anglePretty is too shallow by ~${avgDev.toStringAsFixed(0)}°. Try deeper movement.',
      _ =>
        'Your $anglePretty movement pattern differs from the coach by ~${avgDev.toStringAsFixed(0)}°.',
    };
  }

  int _computeDurationMs(List<FeatureFrame> frames) {
    if (frames.length < 2) return 0;
    return frames.last.timestampMs - frames.first.timestampMs;
  }

  int _computeFrameRate(List<FeatureFrame> frames) {
    if (frames.length < 2) return 0;
    final durationS = _computeDurationMs(frames) / 1000.0;
    if (durationS <= 0) return 0;
    return (frames.length / durationS).round();
  }

  /// Pearson correlation coefficient between two same-length series.
  ///
  /// Returns a value in [-1, 1]. Special cases:
  /// - Both series constant (zero variance) → 1.0 (identical "no movement" pattern)
  /// - One series constant, the other varies → 0.0 (pattern mismatch)
  double _pearsonCorrelation(List<double> a, List<double> b) {
    final n = math.min(a.length, b.length);
    if (n < 2) return 0.0;

    double sumA = 0, sumB = 0;
    for (int i = 0; i < n; i++) {
      sumA += a[i];
      sumB += b[i];
    }
    final meanA = sumA / n;
    final meanB = sumB / n;

    double covAB = 0, varA = 0, varB = 0;
    for (int i = 0; i < n; i++) {
      final da = a[i] - meanA;
      final db = b[i] - meanB;
      covAB += da * db;
      varA += da * da;
      varB += db * db;
    }

    final aIsConst = varA < 1e-10;
    final bIsConst = varB < 1e-10;
    if (aIsConst && bIsConst) return 1.0; // both static = perfect match
    if (aIsConst || bIsConst) return 0.0; // one moves, other doesn't

    return covAB / math.sqrt(varA * varB);
  }

  /// Shift-invariant peak cross-correlation.
  ///
  /// Tries all lags in [-maxShift, +maxShift] and returns the highest
  /// Pearson r found. This makes the correlation immune to temporal
  /// offsets — correct form that is phase-shifted still scores high,
  /// while a genuinely different pattern can't be rescued by any shift.
  double _peakCrossCorrelation(List<double> a, List<double> b, {int? maxLag}) {
    final n = math.min(a.length, b.length);
    if (n < 4) return 0.0;

    final maxShift = maxLag ?? math.min(n ~/ 3, 30);
    double bestR = -1.0;

    for (int lag = -maxShift; lag <= maxShift; lag++) {
      final aStart = math.max(0, lag);
      final bStart = math.max(0, -lag);
      final len = math.min(n - aStart, n - bStart);
      if (len < 4) continue;

      final aSlice = a.sublist(aStart, aStart + len);
      final bSlice = b.sublist(bStart, bStart + len);
      final r = _pearsonCorrelation(aSlice, bSlice);
      if (r > bestR) bestR = r;
    }

    return bestR;
  }
}
