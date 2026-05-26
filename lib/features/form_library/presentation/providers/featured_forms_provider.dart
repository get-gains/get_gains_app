import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/library_exercise_model.dart';
import '../../data/repositories/form_library_repository.dart';

part 'featured_forms_provider.g.dart';

@riverpod
Future<List<LibraryExerciseModel>> featuredForms(Ref ref) async {
  final repo = ref.read(formLibraryRepositoryProvider);
  final result = await repo.getFeaturedForms();

  return result.when(
    success: (response) => response.exercises,
    failure: (_) => [],
  );
}
