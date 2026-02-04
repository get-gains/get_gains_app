import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Application Logger
///
/// Centralized logging utility with log levels and conditional debug output.
/// Integrates with Sentry for remote error tracking in production builds.
///
/// Local console logging only happens in debug mode.
/// Sentry logging happens in both debug and release modes when enabled.
enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();

  static const String _tag = 'GetGains';

  /// Whether Sentry logging is enabled.
  /// Set to true after Sentry.init() completes successfully.
  static bool _sentryEnabled = false;

  /// Enable Sentry logging. Call this after Sentry.init() completes.
  static void enableSentry() {
    _sentryEnabled = true;
    info('Sentry logging enabled', tag: 'AppLogger');
  }

  /// Disable Sentry logging (useful for testing).
  static void disableSentry() {
    _sentryEnabled = false;
  }

  /// Check if Sentry is enabled.
  static bool get isSentryEnabled => _sentryEnabled;

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

  /// Capture an exception directly to Sentry with optional context.
  /// Use this for critical errors that need immediate attention.
  static Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? tag,
    Map<String, dynamic>? extras,
  }) async {
    // Always log locally
    error(
      'Exception captured: $exception',
      tag: tag,
      error: exception,
      stackTrace: stackTrace,
    );

    if (!_sentryEnabled) return;

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (tag != null) {
          scope.setTag('component', tag);
        }
        if (extras != null) {
          for (final entry in extras.entries) {
            scope.setExtra(entry.key, entry.value);
          }
        }
      },
    );
  }

  /// Add a breadcrumb for navigation/action tracking.
  /// Breadcrumbs appear in Sentry error reports for context.
  static void addBreadcrumb(
    String message, {
    String? category,
    String? type,
    Map<String, dynamic>? data,
    SentryLevel? level,
  }) {
    if (!_sentryEnabled) return;

    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        type: type,
        data: data,
        level: level ?? SentryLevel.info,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Set user context for Sentry reports.
  static void setUser({String? id, String? email, String? username}) {
    if (!_sentryEnabled) return;

    Sentry.configureScope((scope) {
      if (id == null && email == null && username == null) {
        scope.setUser(null);
      } else {
        scope.setUser(SentryUser(id: id, email: email, username: username));
      }
    });
  }

  /// Clear user context (on logout).
  static void clearUser() {
    setUser();
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final logTag = tag ?? _tag;

    // Local logging (debug mode only)
    if (kDebugMode) {
      _logLocal(level, message, logTag, error, stackTrace);
    }

    // Sentry logging (all modes when enabled)
    if (_sentryEnabled) {
      _logToSentry(level, message, logTag, error, stackTrace);
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

  static void _logToSentry(
    LogLevel level,
    String message,
    String logTag,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final sentryLevel = _toSentryLevel(level);

    // For errors, capture as exception for better tracking
    if (level == LogLevel.error && error != null) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('component', logTag);
          scope.setExtra('message', message);
        },
      );
    } else {
      // For debug/info/warning, add as breadcrumb
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: '[$logTag] $message',
          category: 'log',
          level: sentryLevel,
          timestamp: DateTime.now(),
          data: error != null ? {'error': error.toString()} : null,
        ),
      );
    }
  }

  static SentryLevel _toSentryLevel(LogLevel level) {
    return switch (level) {
      LogLevel.debug => SentryLevel.debug,
      LogLevel.info => SentryLevel.info,
      LogLevel.warning => SentryLevel.warning,
      LogLevel.error => SentryLevel.error,
    };
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
