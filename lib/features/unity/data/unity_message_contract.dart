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

  /// Method: receive custom string from Flutter (message = arbitrary string).
  static const String methodOnMessageFromFlutter = 'OnMessageFromFlutter';

  /// Method: receive JSON from Flutter (message = JSON string).
  static const String methodOnJsonFromFlutter = 'OnJsonFromFlutter';

  /// Message type sent from Unity when the scene has finished loading.
  /// Flutter uses this to show the Unity view and enable send buttons.
  static const String unityEventSceneLoaded = 'scene_loaded';

  /// Optional: Unity can send JSON. Suggested keys for consistency.
  static const String jsonKeyType = 'type';
  static const String jsonKeyPayload = 'payload';
  static const String jsonKeyTimestamp = 'ts';
}
