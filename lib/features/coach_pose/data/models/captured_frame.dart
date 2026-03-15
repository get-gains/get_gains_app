import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Raw camera frame data captured during recording.
///
/// Used for coach form recording: we capture frames without running MLKit
/// during recording, then process them in batch after stop so FPS equals
/// camera output (e.g. 30 FPS) regardless of device speed.
///
/// Bytes are copied synchronously from [CameraImage] so the camera can
/// recycle its buffers.
class CapturedFrame {
  const CapturedFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.rotationDegrees,
    required this.format,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;
  /// Sensor rotation: 0, 90, 180, or 270.
  final int rotationDegrees;
  /// 'nv21', 'bgra8888', or 'yuv420'.
  final String format;

  /// Copy a [CameraImage] into a [CapturedFrame] synchronously.
  /// Call this from the camera stream callback with no await so the
  /// camera buffer is not recycled before the copy completes.
  static CapturedFrame fromCameraImage(
    CameraImage image,
    int rotationDegrees,
  ) {
    final String format;
    final Uint8List bytes;

    if (image.format.group == ImageFormatGroup.nv21 ||
        image.format.group == ImageFormatGroup.bgra8888) {
      format = image.format.group == ImageFormatGroup.nv21 ? 'nv21' : 'bgra8888';
      bytes = Uint8List.fromList(image.planes.first.bytes);
    } else if (image.format.group == ImageFormatGroup.yuv420) {
      format = 'yuv420';
      final allBytes = image.planes.fold<List<int>>(
        [],
        (prev, plane) => prev..addAll(plane.bytes),
      );
      bytes = Uint8List.fromList(allBytes);
    } else {
      format = 'nv21';
      bytes = Uint8List.fromList(image.planes.first.bytes);
    }

    return CapturedFrame(
      bytes: bytes,
      width: image.width,
      height: image.height,
      bytesPerRow: image.planes.first.bytesPerRow,
      rotationDegrees: rotationDegrees,
      format: format,
    );
  }
}
