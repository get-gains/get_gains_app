import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/utils/logger.dart';

part 'video_frame_extractor.g.dart';

/// Wraps `ffmpeg_kit_flutter_new` to extract JPEG frames from a recorded video
/// at a target FPS. Used by both coach_pose and client_pose after switching
/// from `startImageStream()` (lossy) to `startVideoRecording()`.
@Riverpod(keepAlive: true)
VideoFrameExtractor videoFrameExtractor(Ref ref) {
  return VideoFrameExtractor();
}

class VideoFrameExtractor {
  /// Create a temp directory for extracted frames.
  Future<String> createTempFrameDir(String prefix) async {
    final tmpRoot = await getTemporaryDirectory();
    final dir = Directory(
      '${tmpRoot.path}/pose_frames/${prefix}_${DateTime.now().millisecondsSinceEpoch}',
    );
    await dir.create(recursive: true);
    return dir.path;
  }

  /// Extract JPEG frames from [videoPath] at [targetFps].
  ///
  /// Returns a sorted list of frame [File]s in the output directory.
  /// Throws [FrameExtractionException] if ffmpeg exits with a non-success code.
  Future<List<File>> extractFrames({
    required String videoPath,
    required int targetFps,
    required String outputDirPath,
  }) async {
    final outputPattern = '$outputDirPath/frame_%06d.jpg';
    final command =
        '-y -i "$videoPath" -vf fps=$targetFps -q:v 2 "$outputPattern"';

    AppLogger.info(
      'Starting frame extraction: fps=$targetFps',
      tag: 'VideoFrameExtractor',
    );

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      AppLogger.error(
        'FFmpeg extraction failed (rc=${returnCode?.getValue()})',
        tag: 'VideoFrameExtractor',
      );
      throw FrameExtractionException(
        'FFmpeg exited with code ${returnCode?.getValue()}: $logs',
      );
    }

    final dir = Directory(outputDirPath);
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.jpg'))
        .cast<File>()
        .toList();

    files.sort((a, b) => a.path.compareTo(b.path));

    AppLogger.info(
      'Extracted ${files.length} frames',
      tag: 'VideoFrameExtractor',
    );

    return files;
  }

  /// Delete extracted frame files and their parent directory.
  Future<void> cleanup(List<File> frames) async {
    if (frames.isEmpty) return;

    final parentDir = frames.first.parent;
    try {
      await parentDir.delete(recursive: true);
      AppLogger.info(
        'Cleaned up frame directory: ${parentDir.path}',
        tag: 'VideoFrameExtractor',
      );
    } catch (e) {
      AppLogger.warning(
        'Failed to cleanup frame directory: $e',
        tag: 'VideoFrameExtractor',
      );
    }
  }
}

/// Exception thrown when FFmpeg frame extraction fails.
class FrameExtractionException implements Exception {
  FrameExtractionException(this.message);
  final String message;

  @override
  String toString() => 'FrameExtractionException: $message';
}
