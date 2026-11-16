import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_calculation_method.dart';
import 'package:attendly/features/onboarding/presentation/providers/onboarding_provider.dart';

import '../../data/repositories/semester_repository_impl.dart';
import '../../domain/entities/semester.dart';
import '../../domain/entities/semester_qr_payload.dart';
import '../../domain/repositories/semester_repository.dart';

const String _activeSemesterKey = 'selected_active_semester_id_v1';

final semesterRepositoryProvider = Provider<SemesterRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SemesterRepositoryImpl(db);
});

final activeSemestersStreamProvider = StreamProvider<List<Semester>>((ref) {
  final repo = ref.watch(semesterRepositoryProvider);
  return repo.watchActiveSemesters();
});

final allSemestersStreamProvider = StreamProvider<List<Semester>>((ref) {
  final repo = ref.watch(semesterRepositoryProvider);
  return repo.watchAllSemesters();
});

class SelectedSemesterIdNotifier extends Notifier<int?> {
  @override
  int? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedId = prefs.getInt(_activeSemesterKey);
    return savedId;
  }

  void selectSemester(int id) {
    state = id;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt(_activeSemesterKey, id);
  }

  void clearSelection() {
    state = null;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove(_activeSemesterKey);
  }
}

final selectedSemesterIdProvider =
    NotifierProvider<SelectedSemesterIdNotifier, int?>(
      SelectedSemesterIdNotifier.new,
    );

/// The currently active semester, resolved against the active list.
final activeSemesterProvider = Provider<Semester?>((ref) {
  final activeSemestersAsync = ref.watch(activeSemestersStreamProvider);

  return activeSemestersAsync.maybeWhen(
    data: (semesters) {
      if (semesters.isEmpty) return null;

      final selectedId = ref.watch(selectedSemesterIdProvider);
      if (selectedId != null) {
        final match = semesters.where((s) => s.id == selectedId);
        if (match.isNotEmpty) return match.first;
      }

      // Default to the most recently updated active semester
      return semesters.first;
    },
    orElse: () => null,
  );
});

class SemesterController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<int?> createSemester({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
    double attendanceThreshold = 0.75,
    AttendanceCalculationMethod calculationMethod =
        AttendanceCalculationMethod.rawCombined,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(semesterRepositoryProvider);
      final id = await repo.createSemester(
        name: name,
        startDate: startDate,
        endDate: endDate,
        attendanceThreshold: attendanceThreshold,
        calculationMethod: calculationMethod,
      );
      ref.read(selectedSemesterIdProvider.notifier).selectSemester(id);
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateSemester(Semester semester) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(semesterRepositoryProvider);
      await repo.updateSemester(semester);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> archiveSemester(int id, {required bool isArchived}) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(semesterRepositoryProvider);
      await repo.archiveSemester(id, isArchived: isArchived);
      final currentSelected = ref.read(selectedSemesterIdProvider);
      if (currentSelected == id && isArchived) {
        ref.read(selectedSemesterIdProvider.notifier).clearSelection();
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<int> importSemesterFromQr(
    SemesterQrPayload payload, {
    String? customName,
    bool replaceExisting = false,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(semesterRepositoryProvider);
      final id = await repo.importSemesterPayload(
        payload,
        customName: customName,
        replaceExisting: replaceExisting,
      );
      ref.read(selectedSemesterIdProvider.notifier).selectSemester(id);
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteSemester(int id) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(semesterRepositoryProvider);
      await repo.deleteSemester(id);
      final currentSelected = ref.read(selectedSemesterIdProvider);
      if (currentSelected == id) {
        ref.read(selectedSemesterIdProvider.notifier).clearSelection();
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final semesterControllerProvider =
    AsyncNotifierProvider<SemesterController, void>(SemesterController.new);
