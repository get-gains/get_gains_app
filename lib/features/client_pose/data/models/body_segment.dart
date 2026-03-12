/// Body segment categories matching the server's `BodySegmentEnum`.
///
/// Used to aggregate per-angle form scores into segment-level scores
/// for submission via `POST /pose/results`.
enum BodySegment {
  HEAD_NECK,
  LEFT_ARM,
  RIGHT_ARM,
  TORSO,
  LEFT_LEG,
  RIGHT_LEG,
  FULL_BODY,
}
