import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
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
/// Usage:
/// ```dart
/// final apiClient = ref.read(apiClientProvider);
/// final result = await apiClient.get<Map<String, dynamic>>('/users/profile');
/// result.when(
///   success: (data) => print(data),
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
  late final void Function() _onAuthFailure;

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

    // Add interceptors in order (executed in LIFO order for requests, FIFO for responses)
    _dio.interceptors.addAll([
      // Logging (only in debug)
      if (kDebugMode) LoggingInterceptor(),
      // Error transformation
      ErrorInterceptor(),
      // Retry logic
      RetryInterceptor(),
      // Auth (added last so it runs first on requests)
      AuthInterceptor(
        secureStorage: _secureStorage,
        onTokenRefresh: _refreshToken,
        onAuthFailure: _onAuthFailure,
      ),
    ]);
  }

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
        final data = response.data as Map<String, dynamic>;
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
  Future<Result<T, AppError>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// POST request
  Future<Result<T, AppError>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// PUT request
  Future<Result<T, AppError>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// PATCH request
  Future<Result<T, AppError>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// DELETE request
  Future<Result<T, AppError>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// Upload file with multipart form data
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

      final response = await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return Success(response.data as T);
    } on DioException catch (e) {
      return Failure(_mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(originalError: e));
    }
  }

  /// Map Dio exceptions to AppError
  AppError _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError.timeout();
      case DioExceptionType.connectionError:
        return NetworkError.noConnection();
      case DioExceptionType.badResponse:
        return _mapStatusCode(e.response?.statusCode, e.message);
      case DioExceptionType.cancel:
        return const NetworkError(
          message: 'Request cancelled',
          code: 'CANCELLED',
        );
      default:
        return NetworkError(
          message: e.message ?? 'Network error occurred',
          originalError: e,
        );
    }
  }

  AppError _mapStatusCode(int? statusCode, String? message) {
    if (statusCode == null) {
      return NetworkError(message: message ?? 'Request failed');
    }
    return switch (statusCode) {
      400 => NetworkError(
        message: message ?? 'Bad request',
        code: 'BAD_REQUEST',
        statusCode: 400,
      ),
      401 => NetworkError.unauthorized(),
      403 => NetworkError.forbidden(),
      404 => NetworkError.notFound(),
      422 => ValidationError(message: message ?? 'Validation failed'),
      429 => const NetworkError(
        message: 'Too many requests. Please slow down.',
        code: 'RATE_LIMITED',
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

  return ApiClient(
    secureStorage: secureStorage,
    // Auth failure callback will be set by auth state provider
    onAuthFailure: () {
      AppLogger.warning('Auth failure callback not set', tag: 'ApiClient');
    },
  );
}
