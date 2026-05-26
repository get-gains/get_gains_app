import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/library_exercise_model.dart';
import '../../data/repositories/form_library_repository.dart';

part 'form_library_providers.g.dart';

@riverpod
class FormLibraryNotifier extends _$FormLibraryNotifier {
  @override
  AsyncValue<FormLibraryResponse?> build() {
    _loadPage(reset: true);
    return const AsyncLoading();
  }

  String _searchQuery = '';
  String? _muscleGroup;
  String _sort = 'most_rated';
  int _offset = 0;
  final int _limit = 20;
  List<LibraryExerciseModel> _allExercises = [];

  Future<void> _loadPage({bool reset = false}) async {
    if (reset) {
      _offset = 0;
      _allExercises = [];
    }

    final repo = ref.read(formLibraryRepositoryProvider);
    final result = await repo.getLibrary(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      muscleGroup: _muscleGroup,
      sort: _sort,
      limit: _limit,
      offset: _offset,
    );

    result.when(
      success: (response) {
        if (_offset == 0) {
          _allExercises = response.exercises;
        } else {
          _allExercises = [..._allExercises, ...response.exercises];
        }
        final newOffset = _offset + response.exercises.length;
        state = AsyncData(
          FormLibraryResponse(
            exercises: _allExercises,
            total: response.total,
            limit: _limit,
            offset: newOffset,
            hasMore: response.hasMore,
          ),
        );
      },
      failure: (error) {
        state = AsyncError(error.message, StackTrace.current);
      },
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore) return;
    _offset = current.offset;
    await _loadPage();
  }

  Future<void> setSearch(String query) async {
    if (_searchQuery == query) return;
    _searchQuery = query;
    await _loadPage(reset: true);
  }

  Future<void> setMuscleGroup(String? group) async {
    if (_muscleGroup == group) return;
    _muscleGroup = group;
    await _loadPage(reset: true);
  }

  Future<void> setSort(String sort) async {
    if (_sort == sort) return;
    _sort = sort;
    await _loadPage(reset: true);
  }

  Future<void> refresh() async {
    await _loadPage(reset: true);
  }

  void updateLocalRating(String exerciseId, int newCount, bool isRated) {
    final current = state.asData?.value;
    if (current == null) return;

    final updated = current.exercises.map((e) {
      if (e.id == exerciseId) {
        return LibraryExerciseModel(
          id: e.id,
          name: e.name,
          description: e.description,
          targetMuscles: e.targetMuscles,
          coachName: e.coachName,
          coachAvatarUrl: e.coachAvatarUrl,
          thumbsUpCount: newCount,
          isRatedByUser: isRated,
          hasForms: e.hasForms,
          createdAt: e.createdAt,
        );
      }
      return e;
    }).toList();

    state = AsyncData(
      FormLibraryResponse(
        exercises: updated,
        total: current.total,
        limit: current.limit,
        offset: current.offset,
        hasMore: current.hasMore,
      ),
    );
  }
}
