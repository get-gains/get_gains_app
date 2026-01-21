import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Application Logger
///
/// Centralized logging utility with log levels and conditional debug output.
/// Only logs in debug mode to prevent information leakage in production.
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

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;

    final prefix = _getLevelPrefix(level);
    final logTag = tag ?? _tag;
    final errorInfo = error != null ? '\nError: $error' : '';
    final stackInfo = stackTrace != null ? '\nStack: $stackTrace' : '';

    developer.log(
      '$prefix $message$errorInfo$stackInfo',
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
