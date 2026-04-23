import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Application Logger
///
/// Centralized logging utility with log levels and conditional debug output.
///
/// Local console logging only happens in debug mode.
enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();

  static const String _tag = 'GetGains';

  static void debug(String message, {String? tag, Object? error}) {
    _log(LogLevel.debug, message, tag: tag, error: error);
  }

  static void info(String message, {String? tag, Object? error}) {
    _log(LogLevel.info, message, tag: tag, error: error);
  }

  static void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Capture an exception for local logging (e.g. critical paths).
  static Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? tag,
    Map<String, dynamic>? extras,
  }) async {
    error(
      'Exception captured: $exception'
      '${extras != null && extras.isNotEmpty ? ' | $extras' : ''}',
      tag: tag,
      error: exception,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logTag = tag ?? _tag;

    if (kDebugMode) {
      _logLocal(level, message, logTag, error, stackTrace);
    }
  }

  static void _logLocal(
    LogLevel level,
    String message,
    String logTag,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final prefix = _getLevelPrefix(level);
    final errorInfo = error != null ? '\nError: $error' : '';
    final stackInfo = stackTrace != null ? '\nStack: $stackTrace' : '';
    final fullMessage = '$prefix $message$errorInfo$stackInfo';

    // Print to terminal/console for visibility
    // ignore: avoid_print
    print('[$logTag] $fullMessage');

    // Also log to DevTools
    developer.log(
      fullMessage,
      name: logTag,
      level: _getLevelValue(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _getLevelPrefix(LogLevel level) {
    return switch (level) {
      LogLevel.debug => '🐛 [DEBUG]',
      LogLevel.info => 'ℹ️ [INFO]',
      LogLevel.warning => '⚠️ [WARN]',
      LogLevel.error => '❌ [ERROR]',
    };
  }

  static int _getLevelValue(LogLevel level) {
    return switch (level) {
      LogLevel.debug => 500,
      LogLevel.info => 800,
      LogLevel.warning => 900,
      LogLevel.error => 1000,
    };
  }
}
