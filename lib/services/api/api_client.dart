import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/api_error_codes.dart';
import '../../core/utils/api_response.dart';
import '../../core/utils/app_error.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/result.dart';
import '../storage/secure_storage_service.dart';
import 'interceptors.dart';

part 'api_client.g.dart';

/// API Client Service
///
/// Centralized HTTP client using Dio with automatic token management.
/// All API calls should go through this client.
///
/// **Server Response Format:**
/// The server always returns responses in this format:
/// ```json
/// {
///   "data": { ... } | null,
///   "errors": [{ "field": "email", "message": "Invalid" }]
/// }
/// ```
///
/// This client automatically:
/// - Unwraps the `data` field from successful responses
/// - Parses `errors` array and returns appropriate `AppError` on failure
///
/// Usage:
/// ```dart
/// final apiClient = ref.read(apiClientProvider);
/// final result = await apiClient.get<Map<String, dynamic>>('/users/profile');
/// result.when(
///   success: (data) => print(data), // Already unwrapped from { data: ... }
///   failure: (error) => print(error.message),
/// );
/// ```
class ApiClient {
  ApiClient({
    required SecureStorageService secureStorage,
    Dio? dio,
    void Function()? onAuthFailure,
  }) : _secureStorage = secureStorage {
    _dio = dio ?? Dio();
    _onAuthFailure = onAuthFailure ?? () {};
    _configureDio();
  }

  late final Dio _dio;
  final SecureStorageService _secureStorage;
  late void Function() _onAuthFailure;

  /// Access the raw Dio instance (for advanced use cases)
  Dio get dio => _dio;

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add interceptors in order (FIFO for requests, LIFO for responses/errors)
    _dio.interceptors.addAll([
      // Auth (runs first on requests — attaches token before logging)
      AuthInterceptor(
        secureStorage: _secureStorage,
        onTokenRefresh: _refreshToken,
        onAuthFailure: () => _onAuthFailure(),
      ),
      // Retry logic
      RetryInterceptor(),
      // Logging (only in debug — runs last so it captures final headers)
      if (kDebugMode) LoggingInterceptor(),
    ]);
  }

  /// Public method to attempt token refresh (e.g., on app startup)
  Future<bool> tryRefreshToken() => _refreshToken();

  /// Attempt to refresh the access token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      // Create a new Dio instance without interceptors to avoid loops
      final freshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await freshDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        // Server wraps responses in { data: { ... }, errors: [] }
        final data = responseData['data'] as Map<String, dynamic>;
        await _secureStorage.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        AppLogger.info('Token refreshed successfully', tag: 'ApiClient');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Token refresh failed', tag: 'ApiClient', error: e);
      return false;
    }
  }

  /// Update the auth failure callback (called from providers)
  void setAuthFailureCallback(void Function() callback) {
    _onAuthFailure = callback;
  }

  // ============== HTTP Methods ==============

  /// GET request
  ///
  /// Returns the unwrapped `data` field from the server response.
  /// If the server returns errors, returns a `Failure` with the error message.
  Future<Result<T, AppError>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response.data);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// POST request
  ///
  /// Returns the unwrapped `data` field from the server response.
  /// If the server returns errors, returns a `Failure` with the error message.
  Future<Result<T, AppError>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response.data);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// PUT request
  ///
  /// Returns the unwrapped `data` field from the server response.
  /// If the server returns errors, returns a `Failure` with the error message.
  Future<Result<T, AppError>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response.data);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// PATCH request
  ///
  /// Returns the unwrapped `data` field from the server response.
  /// If the server returns errors, returns a `Failure` with the error message.
  Future<Result<T, AppError>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response.data);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// DELETE request
  ///
  /// Returns the unwrapped `data` field from the server response.
  /// If the server returns errors, returns a `Failure` with the error message.
  Future<Result<T, AppError>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _parseResponse<T>(response.data);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// Upload file with multipart form data
  ///
  /// Returns the unwrapped `data` field from the server response.
  Future<Result<T, AppError>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? extraFields,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?extraFields,
      });

      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return _parseResponse<T>(response.data);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  // ============== Response Parsing ==============

  /// Parse the standard API response format { data, errors }
  ///
  /// - If `errors` is empty, returns Success with unwrapped `data`
  /// - If `errors` has items, returns Failure with combined error messages
  /// - Extracts the typed [ApiErrorCode] from `errors[0].code` when present
  Result<T, AppError> _parseResponse<T>(Map<String, dynamic>? responseData) {
    if (responseData == null) {
      return Failure(const NetworkError(message: 'Empty response from server'));
    }

    // Check if this follows the standard { data, errors } format
    if (!responseData.containsKey('errors')) {
      // Non-standard response, return as-is (for backwards compatibility)
      AppLogger.warning(
        'Response does not follow standard format: $responseData',
        tag: 'ApiClient',
      );
      return Success(responseData as T);
    }

    final errors = responseData['errors'] as List<dynamic>?;

    // Check for errors
    if (errors != null && errors.isNotEmpty) {
      final errorMessage = responseData.allErrorMessages;
      final firstError = errors.first as Map<String, dynamic>;
      final field = firstError['field'] as String?;
      final apiCode = responseData.firstErrorCode;

      AppLogger.debug('API returned errors: $errorMessage', tag: 'ApiClient');

      return Failure(
        ValidationError(message: errorMessage, field: field, code: apiCode),
      );
    }

    // Success - return unwrapped data
    final data = responseData['data'];
    if (data == null && T != Null) {
      // data is null but caller expects non-null
      return Success(null as T);
    }

    return Success(data as T);
  }

  // ============== Error Mapping ==============
  AppError _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError.timeout();
      case DioExceptionType.connectionError:
        return NetworkError.noConnection();
      case DioExceptionType.badResponse:
        // First try to extract errors from the standard { data, errors } format
        // so we preserve the server's user-friendly error message.
        final serverError = _tryParseServerErrors(e.response);
        if (serverError != null) return serverError;
        return _mapStatusCode(e.response?.statusCode, e.message);
      case DioExceptionType.cancel:
        return const NetworkError(
          message: 'Request cancelled',
          transportCode: 'CANCELLED',
        );
      default:
        return NetworkError(
          message: e.message ?? 'Network error occurred',
          originalError: e,
        );
    }
  }

  /// Try to parse the server's standard { data, errors } format from an
  /// error response. Returns an AppError with the server's message and typed
  /// [ApiErrorCode] if found.
  AppError? _tryParseServerErrors(Response<dynamic>? response) {
    if (response?.data == null) return null;
    try {
      final data = response!.data;
      if (data is Map<String, dynamic> && data.containsKey('errors')) {
        final errors = data['errors'] as List<dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final errorMessage = data.allErrorMessages;
          final statusCode = response.statusCode;
          final apiCode = data.firstErrorCode;

          // Subscription-gated endpoints → specific error type so the UI can
          // show an upgrade modal instead of a generic error.
          if (apiCode == ApiErrorCode.subscriptionRequired ||
              apiCode == ApiErrorCode.subscriptionTierInsufficient) {
            return SubscriptionRequiredError(
              message: errorMessage,
              code: apiCode,
            );
          }

          final firstError =
              (data['errors'] as List).first as Map<String, dynamic>;
          final meta = firstError['meta'] as Map<String, dynamic>?;

          // Return the server's error message with the typed code
          return NetworkError(
            message: errorMessage,
            code: apiCode,
            statusCode: statusCode,
            meta: meta,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  AppError _mapStatusCode(int? statusCode, String? message) {
    if (statusCode == null) {
      return NetworkError(message: message ?? 'Request failed');
    }
    return switch (statusCode) {
      400 => NetworkError(
        message: message ?? 'Bad request',
        transportCode: 'BAD_REQUEST',
        statusCode: 400,
      ),
      401 => NetworkError.unauthorized(),
      403 => NetworkError.forbidden(),
      404 => NetworkError.notFound(),
      422 => ValidationError(message: message ?? 'Validation failed'),
      429 => const NetworkError(
        message: 'Too many requests. Please slow down.',
        transportCode: 'RATE_LIMITED',
        statusCode: 429,
      ),
      >= 500 => NetworkError.serverError(
        statusCode: statusCode,
        serverMessage: message,
      ),
      _ => NetworkError(
        message: message ?? 'Request failed',
        statusCode: statusCode,
      ),
    };
  }
}

/// Provider for ApiClient
@Riverpod(keepAlive: true)
ApiClient apiClient(Ref ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);

  return ApiClient(secureStorage: secureStorage);
}
