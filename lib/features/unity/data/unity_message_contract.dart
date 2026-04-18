import 'dart:convert';

/// Flutter–Unity message contract.
///
/// Shared constants and format so Flutter and Unity agree on
/// game object names, method names, and message structure.
/// Keep this in sync with the Unity project.
class UnityMessageContract {
  UnityMessageContract._();

  /// Game object in the Unity scene that receives Flutter messages.
  /// Must have a script with public void MethodName(string message) methods.
  static const String gameObjectName = 'FlutterUnityBridge';

  /// Method: set rotation speed (message = speed string, e.g. "50").
  static const String methodSetRotationSpeed = 'SetRotationSpeed';

  /// Method: re-apply Cosmetic framing (restores close-up after user pans away).
  /// Message: "" (empty string — ignored by Unity).
  static const String methodResetCosmeticView = 'ResetCosmeticView';

  /// Method: switch camera view mode.
  /// Message: "WORKOUT" | "COSMETIC"
  ///   WORKOUT  — full-figure framing, wide orbit limits (default for pose/recording screens).
  ///   COSMETIC — upper-body close-up, front-facing, tighter zoom for accessory inspection.
  /// Send immediately after scene_loaded, before LoadEquippedCosmetics or LoadPoseFrames.
  static const String methodSetCameraViewMode = 'SetCameraViewMode';

  /// Method: receive custom string from Flutter (message = arbitrary string).
  static const String methodOnMessageFromFlutter = 'OnMessageFromFlutter';

  /// Method: receive JSON from Flutter (message = JSON string).
  static const String methodOnJsonFromFlutter = 'OnJsonFromFlutter';

  // ── Pose / Skeleton methods ──────────────────────────────────────

  /// Load a full set of landmark frames into Unity for playback.
  /// Message: JSON string with format:
  /// ```json
  /// {
  ///   "frames": [
  ///     { "timestampMs": 0, "landmarks": { "LEFT_SHOULDER": { "x": 0.5, "y": 0.3, "z": 0.1 }, ... } },
  ///     ...
  ///   ],
  ///   "fps": 15,
  ///   "loop": true
  /// }
  /// ```
  static const String methodLoadPoseFrames = 'LoadPoseFrames';

  /// Play/resume the loaded pose animation.
  static const String methodPlayPose = 'PlayPose';

  /// Pause the pose animation.
  static const String methodPausePose = 'PausePose';

  /// Seek to a specific frame index. Message = index string, e.g. "42".
  static const String methodSeekPoseFrame = 'SeekPoseFrame';

  /// Set the skeleton color. Message = hex string, e.g. "#00FFFF".
  static const String methodSetSkeletonColor = 'SetSkeletonColor';

  /// Set camera angle in Unity scene.
  /// Message = one of: "FRONT", "SIDE_LEFT", "SIDE_RIGHT", "REAR",
  ///                     "ANGLE_45_LEFT", "ANGLE_45_RIGHT"
  static const String methodSetCameraAngle = 'SetCameraAngle';

  /// Debug / tuning for humanoid pose vs landmarks. Message: JSON, e.g.
  /// `{"swapArmLandmarks":true,"forceShowStickFigure":true,"invertArmDepthZ":true,"invertHeadDepthZ":true}`
  static const String methodSetPoseDebugOptions = 'SetPoseDebugOptions';

  /// Defaults for [methodSetPoseDebugOptions] (inline 3D card, fullscreen preview, reset).
  static const bool defaultPoseDebugSwapArmLandmarks = true;
  static const bool defaultPoseDebugForceStickFigure = false;
  static const bool defaultPoseDebugInvertArmDepthZ = true;
  static const bool defaultPoseDebugInvertHeadDepthZ = true;

  /// JSON payload built from [defaultPoseDebugSwapArmLandmarks], etc.
  static String defaultPoseDebugOptionsPayload() => jsonEncode({
        'swapArmLandmarks': defaultPoseDebugSwapArmLandmarks,
        'forceShowStickFigure': defaultPoseDebugForceStickFigure,
        'invertArmDepthZ': defaultPoseDebugInvertArmDepthZ,
        'invertHeadDepthZ': defaultPoseDebugInvertHeadDepthZ,
      });

  // ── Events from Unity ────────────────────────────────────────────

  /// Message type sent from Unity when the scene has finished loading.
  /// Flutter uses this to show the Unity view and enable send buttons.
  static const String unityEventSceneLoaded = 'scene_loaded';

  /// Message type sent from Unity when pose frames finish loading.
  static const String unityEventPoseReady = 'pose_ready';

  /// Message type sent from Unity on each frame during playback.
  /// Format: "frame_update:<index>"
  static const String unityEventFrameUpdate = 'frame_update';

  // ── Cosmetic methods ──────────────────────────────────────────

  /// Load and apply all currently equipped cosmetics to the character model.
  /// Message: JSON string with format:
  /// ```json
  /// {
  ///   "cosmetics": [
  ///     { "category": "HEADWEAR", "assetRef": "headwear_flame_headband" },
  ///     { "category": "TOP", "assetRef": "top_iron_tank" }
  ///   ]
  /// }
  /// ```
  static const String methodLoadEquippedCosmetics = 'LoadEquippedCosmetics';

  /// Temporarily preview a cosmetic item (for shop browsing). Does NOT persist.
  /// Message: JSON string with format:
  /// ```json
  /// {
  ///   "category": "HEADWEAR",
  ///   "assetRef": "headwear_viking_helm",
  ///   "showOnly": true
  /// }
  /// ```
  static const String methodPreviewCosmetic = 'PreviewCosmetic';

  /// Revert to the actual equipped state after previewing.
  /// Message: "" (empty string)
  static const String methodClearPreview = 'ClearPreview';

  // ── Cosmetic events from Unity ───────────────────────────────

  /// Confirms that cosmetics have been applied to the character.
  static const String unityEventCosmeticsLoaded = 'cosmetics_loaded';

  /// Confirms a preview cosmetic has been applied.
  static const String unityEventCosmeticPreviewReady = 'cosmetic_preview_ready';

  /// Optional: Unity can send JSON. Suggested keys for consistency.
  static const String jsonKeyType = 'type';
  static const String jsonKeyPayload = 'payload';
  static const String jsonKeyTimestamp = 'ts';
}
