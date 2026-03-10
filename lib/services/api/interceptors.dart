import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../storage/secure_storage_service.dart';

/// Auth Interceptor
///
/// Handles automatic JWT token injection and token refresh logic.
/// Attaches access token to all requests and handles 401 responses
/// by attempting to refresh the token.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.secureStorage,
    required this.onTokenRefresh,
    required this.onAuthFailure,
  });

  final SecureStorageService secureStorage;
  final Future<bool> Function() onTokenRefresh;
  final void Function() onAuthFailure;

  bool _isRefreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for auth endpoints and recovery endpoints
    // Recovery endpoints use explicit Bearer tokens (not the stored access token)
    final isAuthEndpoint =
        options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh') ||
        options.path.contains('/auth/reset-password') ||
        options.path.contains('/auth/send-recovery-email') ||
        options.path.contains('/auth/check-email-verified') ||
        options.path.contains('/auth/exchange-code');

    if (!isAuthEndpoint) {
      final token = await secureStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == HttpStatus.unauthorized) {
      // Don't retry if already refreshing or if this is a refresh/recovery request
      if (_isRefreshing ||
          err.requestOptions.path.contains('/auth/refresh') ||
          err.requestOptions.path.contains('/auth/reset-password')) {
        if (err.requestOptions.path.contains('/auth/reset-password')) {
          // Recovery token failure — don't trigger logout, just propagate
          handler.next(err);
          return;
        }
        AppLogger.warning(
          'Token refresh failed, logging out',
          tag: 'AuthInterceptor',
        );
        onAuthFailure();
        handler.next(err);
        return;
      }

      _isRefreshing = true;
      AppLogger.info(
        'Access token expired, attempting refresh',
        tag: 'AuthInterceptor',
      );

      try {
        final success = await onTokenRefresh();
        _isRefreshing = false;

        if (success) {
          // Retry the original request with new token
          final token = await secureStorage.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';

          final response = await Dio().fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } else {
          onAuthFailure();
        }
      } catch (e) {
        _isRefreshing = false;
        AppLogger.error(
          'Token refresh error',
          tag: 'AuthInterceptor',
          error: e,
        );
        onAuthFailure();
      }
    }

    handler.next(err);
  }
}

/// Logging Interceptor
///
/// Logs all HTTP requests and responses for debugging.
/// Includes full request/response bodies for easier debugging.
/// Only active in debug mode.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug(
      '┌─────────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
    AppLogger.debug('│ → ${options.method} ${options.uri}', tag: 'HTTP');
    if (options.headers.isNotEmpty) {
      AppLogger.debug('│ Headers: ${options.headers}', tag: 'HTTP');
    }
    if (options.data != null) {
      AppLogger.debug('│ Body: ${options.data}', tag: 'HTTP');
    }
    AppLogger.debug(
      '└─────────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
      '┌─────────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
    AppLogger.debug(
      '│ ← ${response.statusCode} ${response.requestOptions.uri}',
      tag: 'HTTP',
    );
    AppLogger.debug('│ Response: ${response.data}', tag: 'HTTP');
    AppLogger.debug(
      '└─────────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      '┌─────────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
    AppLogger.error(
      '│ ✕ ${err.response?.statusCode ?? 'NO STATUS'} ${err.requestOptions.uri}',
      tag: 'HTTP',
    );
    AppLogger.error('│ Error: ${err.message}', tag: 'HTTP');
    if (err.response?.data != null) {
      AppLogger.error('│ Response: ${err.response?.data}', tag: 'HTTP');
    }
    AppLogger.error(
      '└─────────────────────────────────────────────────────────────────',
      tag: 'HTTP',
    );
    handler.next(err);
  }
}

/// Error Interceptor
///
/// Transforms Dio errors into more consistent error responses.
/// Parses the standard API error format: { data: null, errors: [{ field?, message }] }
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Add more context to errors
    final enrichedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: _getErrorMessage(err),
      message: _getErrorMessage(err),
    );
    handler.next(enrichedError);
  }

  String _getErrorMessage(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond. Please try again.';
      case DioExceptionType.badResponse:
        return _parseServerError(err.response);
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        final uri = err.requestOptions.uri.toString();
        if (uri.contains('localhost') || uri.contains('127.0.0.1')) {
          return 'Cannot reach server. Is it running? On a device, run: adb reverse tcp:3000 tcp:3000';
        }
        return 'No internet connection. Please check your network.';
      case DioExceptionType.unknown:
      default:
        return err.message ?? 'An unexpected error occurred.';
    }
  }

  /// Parse server error from the standard API response format
  ///
  /// Expected format: { data: null, errors: [{ field?, message }] }
  String _parseServerError(Response? response) {
    if (response == null) return 'Server error occurred.';

    try {
      final data = response.data;
      if (data is Map) {
        // Check for standard API error format: { errors: [...] }
        final errors = data['errors'] as List<dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          // Combine all error messages
          final messages = errors
              .map((e) {
                if (e is Map) {
                  final field = e['field'] as String?;
                  final message = e['message'] as String? ?? 'Unknown error';
                  return field != null ? '$field: $message' : message;
                }
                return e.toString();
              })
              .join(', ');
          return messages;
        }

        // Fallback to legacy formats
        return data['message'] ??
            data['error'] ??
            'Server error: ${response.statusCode}';
      }
    } catch (_) {}

    return 'Server error: ${response.statusCode}';
  }
}

/// Retry Interceptor
///
/// Automatically retries failed requests based on configuration.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  final int maxRetries;
  final Duration retryDelay;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only retry on network errors or 5xx server errors
    final shouldRetry =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        (err.response?.statusCode ?? 0) >= 500;

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    // FormData streams are consumed after the first send and cannot be
    // replayed. Retrying would throw "The FormData has already been
    // finalized." Skip retry entirely for multipart requests — the caller
    // is responsible for rebuilding FormData if it wants to retry.
    if (err.requestOptions.data is FormData) {
      handler.next(err);
      return;
    }

    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    if (retryCount < maxRetries) {
      // Rebuild from baseUrl + path so retry never uses a corrupted URI (e.g. 1192.168...)
      final retryUrl = '${ApiConstants.baseUrl}${err.requestOptions.path.startsWith('/') ? '' : '/'}${err.requestOptions.path}';
      AppLogger.info(
        'Retrying request (${retryCount + 1}/$maxRetries): $retryUrl',
        tag: 'RetryInterceptor',
      );

      await Future.delayed(retryDelay * (retryCount + 1));

      err.requestOptions.extra['retryCount'] = retryCount + 1;

      try {
        final retryOptions = err.requestOptions.copyWith(
          baseUrl: ApiConstants.baseUrl,
          path: err.requestOptions.path,
        );
        final response = await Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
          ),
        ).fetch(retryOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        if (e is DioException) {
          handler.next(e);
          return;
        }
      }
    }

    handler.next(err);
  }
}
