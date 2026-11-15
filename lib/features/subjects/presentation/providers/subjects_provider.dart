import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

import '../../data/repositories/subject_repository_impl.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subject_repository.dart';

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SubjectRepositoryImpl(db);
});

final activeSemesterSubjectsProvider = StreamProvider<List<Subject>>((ref) {
  final activeSemester = ref.watch(activeSemesterProvider);
  if (activeSemester == null) {
    return Stream.value([]);
  }
  final repo = ref.watch(subjectRepositoryProvider);
  return repo.watchSubjectsForSemester(activeSemester.id);
});

class SubjectController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int> createSubject({
    required int semesterId,
    required String name,
    bool lectureEnabled = true,
    bool labEnabled = false,
    int sortOrder = 0,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(subjectRepositoryProvider);
      final id = await repo.createSubject(
        semesterId: semesterId,
        name: name,
        lectureEnabled: lectureEnabled,
        labEnabled: labEnabled,
        sortOrder: sortOrder,
      );
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(subjectRepositoryProvider);
      await repo.updateSubject(subject);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteSubject(int id) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(subjectRepositoryProvider);
      await repo.deleteSubject(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final subjectControllerProvider =
    AsyncNotifierProvider<SubjectController, void>(
      SubjectController.new,
    );
