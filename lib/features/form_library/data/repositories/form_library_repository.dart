import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../../services/api/api_client.dart';
import '../models/library_exercise_model.dart';

part 'form_library_repository.g.dart';

@Riverpod(keepAlive: true)
FormLibraryRepository formLibraryRepository(Ref ref) {
  return FormLibraryRepository(apiClient: ref.watch(apiClientProvider));
}

class FormLibraryRepository {
  FormLibraryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<FormLibraryResponse, AppError>> getLibrary({
    String? search,
    String? muscleGroup,
    String sort = 'most_rated',
    int limit = 20,
    int offset = 0,
  }) async {
    AppLogger.debug('Fetching form library', tag: 'FormLibraryRepo');

    final queryParams = <String, dynamic>{
      'sort': sort,
      'limit': limit,
      'offset': offset,
      if (search != null && search.isNotEmpty) 'search': search,
      if (muscleGroup != null && muscleGroup.isNotEmpty)
        'muscleGroup': muscleGroup,
    };

    final result = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.formLibrary,
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        try {
          final response = FormLibraryResponse.fromJson(data);
          return Success(response);
        } catch (e) {
          AppLogger.error(
            'Failed to parse form library response',
            tag: 'FormLibraryRepo',
            error: e,
          );
          return Failure(
            UnknownError(message: 'Failed to parse library data: $e'),
          );
        }
      },
      failure: (error) => Failure(error),
    );
  }

  Future<Result<FormLibraryResponse, AppError>> getFeaturedForms() async {
    return getLibrary(sort: 'most_rated', limit: 6, offset: 0);
  }

  Future<Result<Map<String, dynamic>, AppError>> rateExercise(
    String exerciseId,
  ) async {
    AppLogger.debug('Rating exercise: $exerciseId', tag: 'FormLibraryRepo');

    final result = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.exerciseRatings,
      data: {'exerciseId': exerciseId},
    );

    return result.when(
      success: (data) => Success(data),
      failure: (error) => Failure(error),
    );
  }

  Future<Result<Map<String, dynamic>, AppError>> removeRating(
    String exerciseId,
  ) async {
    AppLogger.debug('Removing rating: $exerciseId', tag: 'FormLibraryRepo');

    final result = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.exerciseRatings}/$exerciseId',
    );

    return result.when(
      success: (data) => Success(data),
      failure: (error) => Failure(error),
    );
  }
}
