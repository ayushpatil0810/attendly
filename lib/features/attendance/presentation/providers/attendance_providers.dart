import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/providers/database_provider.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/day_note_repository_impl.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/attendance_status.dart';
import '../../domain/entities/day_note.dart';
import '../../domain/entities/semester_attendance_summary.dart';
import '../../domain/entities/session_component.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/day_note_repository.dart';
import '../../domain/services/attendance_calculator.dart';
import '../../domain/services/recovery_calculator.dart';
import '../../domain/services/safe_absence_calculator.dart';

String formatDateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AttendanceRepositoryImpl(db);
});

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void selectDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }

  void selectToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

class CurrentMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }

  void previousMonth() {
    if (state.month == 1) {
      state = DateTime(state.year - 1, 12, 1);
    } else {
      state = DateTime(state.year, state.month - 1, 1);
    }
  }

  void nextMonth() {
    if (state.month == 12) {
      state = DateTime(state.year + 1, 1, 1);
    } else {
      state = DateTime(state.year, state.month + 1, 1);
    }
  }

  void currentMonth() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, 1);
  }
}

final currentMonthProvider = NotifierProvider<CurrentMonthNotifier, DateTime>(
  CurrentMonthNotifier.new,
);

/// Watches all sessions for the active semester
final activeSemesterSessionsStreamProvider =
    StreamProvider<List<AttendanceSession>>((ref) {
      final activeSemester = ref.watch(activeSemesterProvider);
      if (activeSemester == null) {
        return Stream.value([]);
      }
      final repo = ref.watch(attendanceRepositoryProvider);
      return repo.watchSessionsForSemester(activeSemester.id);
    });

/// Watches sessions for a specific date in the active semester
final sessionsForDateFamilyProvider =
    StreamProvider.family<List<AttendanceSession>, String>((ref, dateStr) {
      final activeSemester = ref.watch(activeSemesterProvider);
      if (activeSemester == null) {
        return Stream.value([]);
      }
      final repo = ref.watch(attendanceRepositoryProvider);
      return repo.watchSessionsForDate(activeSemester.id, dateStr);
    });

/// Watches sessions for the selected calendar date
final sessionsForSelectedDateProvider = StreamProvider<List<AttendanceSession>>(
  (ref) {
    final activeSemester = ref.watch(activeSemesterProvider);
    if (activeSemester == null) {
      return Stream.value([]);
    }
    final selectedDate = ref.watch(selectedDateProvider);
    final dateStr = formatDateOnly(selectedDate);
    final repo = ref.watch(attendanceRepositoryProvider);
    return repo.watchSessionsForDate(activeSemester.id, dateStr);
  },
);

/// Watches sessions for the currently viewed calendar month
final sessionsForMonthProvider = StreamProvider<List<AttendanceSession>>((ref) {
  final activeSemester = ref.watch(activeSemesterProvider);
  if (activeSemester == null) {
    return Stream.value([]);
  }
  final currentMonth = ref.watch(currentMonthProvider);
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.watchSessionsForMonth(
    activeSemester.id,
    currentMonth.year,
    currentMonth.month,
  );
});

/// Represents the previous action that can be undone
sealed class UndoAction {
  const UndoAction();
}

class UndoCreatedSession extends UndoAction {
  const UndoCreatedSession(this.sessionId);
  final int sessionId;
}

class UndoDeletedSession extends UndoAction {
  const UndoDeletedSession(this.session);
  final AttendanceSession session;
}

class UndoUpdatedSession extends UndoAction {
  const UndoUpdatedSession(this.previousSession);
  final AttendanceSession previousSession;
}

class AttendanceController extends AsyncNotifier<UndoAction?> {
  @override
  Future<UndoAction?> build() async => null;

  Future<int> recordSession({
    required int subjectId,
    required String sessionDate,
    required SessionComponent component,
    required AttendanceStatus status,
    String? note,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final id = await repo.createSession(
        subjectId: subjectId,
        sessionDate: sessionDate,
        component: component,
        status: status,
        note: note,
      );
      final action = UndoCreatedSession(id);
      state = AsyncData(action);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateSession(AttendanceSession session) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final oldSession = await repo.getSessionById(session.id);
      await repo.updateSession(session);
      if (oldSession != null) {
        state = AsyncData(UndoUpdatedSession(oldSession));
      } else {
        state = const AsyncData(null);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteSession(AttendanceSession session) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      await repo.deleteSession(session.id);
      state = AsyncData(UndoDeletedSession(session));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> undo() async {
    final action = state.asData?.value;
    if (action == null) return;

    state = const AsyncLoading();
    try {
      final repo = ref.read(attendanceRepositoryProvider);
      switch (action) {
        case UndoCreatedSession(sessionId: final sessionId):
          await repo.deleteSession(sessionId);
        case UndoDeletedSession(session: final session):
          await repo.createSession(
            subjectId: session.subjectId,
            sessionDate: session.sessionDate,
            component: session.component,
            status: session.status,
            note: session.note,
          );
        case UndoUpdatedSession(previousSession: final previousSession):
          await repo.updateSession(previousSession);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final attendanceControllerProvider =
    AsyncNotifierProvider<AttendanceController, UndoAction?>(
      AttendanceController.new,
    );

final safeAbsenceCalculatorProvider = Provider<SafeAbsenceCalculator>((ref) {
  return const SafeAbsenceCalculator();
});

final recoveryCalculatorProvider = Provider<RecoveryCalculator>((ref) {
  return const RecoveryCalculator();
});

final attendanceCalculatorProvider = Provider<AttendanceCalculator>((ref) {
  final safeAbsenceCalculator = ref.watch(safeAbsenceCalculatorProvider);
  final recoveryCalculator = ref.watch(recoveryCalculatorProvider);
  return AttendanceCalculator(
    safeAbsenceCalculator: safeAbsenceCalculator,
    recoveryCalculator: recoveryCalculator,
  );
});

/// Reactive provider yielding the active semester's attendance summary,
/// automatically recalculated whenever sessions, subjects, or semester settings update.
final semesterAttendanceSummaryProvider =
    Provider<AsyncValue<SemesterAttendanceSummary?>>((ref) {
      final activeSemester = ref.watch(activeSemesterProvider);
      if (activeSemester == null) {
        return const AsyncData(null);
      }

      final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
      final sessionsAsync = ref.watch(activeSemesterSessionsStreamProvider);

      if (!subjectsAsync.hasValue || !sessionsAsync.hasValue) {
        if (subjectsAsync.hasError) {
          return AsyncError(
            subjectsAsync.error!,
            subjectsAsync.stackTrace ?? StackTrace.current,
          );
        }
        if (sessionsAsync.hasError) {
          return AsyncError(
            sessionsAsync.error!,
            sessionsAsync.stackTrace ?? StackTrace.current,
          );
        }
        return const AsyncLoading();
      }

      if (subjectsAsync.hasError) {
        return AsyncError(
          subjectsAsync.error!,
          subjectsAsync.stackTrace ?? StackTrace.current,
        );
      }

      if (sessionsAsync.hasError) {
        return AsyncError(
          sessionsAsync.error!,
          sessionsAsync.stackTrace ?? StackTrace.current,
        );
      }

      final subjects = subjectsAsync.value ?? [];
      final sessions = sessionsAsync.value ?? [];
      final calculator = ref.watch(attendanceCalculatorProvider);

      final summary = calculator.calculateSemester(
        semester: activeSemester,
        subjects: subjects,
        sessions: sessions,
      );

      return AsyncData(summary);
    });

/// Reactive provider yielding attendance summary for sessions in the current calendar month only.
final currentMonthAttendanceSummaryProvider =
    Provider<AsyncValue<SemesterAttendanceSummary?>>((ref) {
      final activeSemester = ref.watch(activeSemesterProvider);
      if (activeSemester == null) {
        return const AsyncData(null);
      }

      final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
      final sessionsAsync = ref.watch(activeSemesterSessionsStreamProvider);

      if (!subjectsAsync.hasValue || !sessionsAsync.hasValue) {
        if (subjectsAsync.hasError) {
          return AsyncError(
            subjectsAsync.error!,
            subjectsAsync.stackTrace ?? StackTrace.current,
          );
        }
        if (sessionsAsync.hasError) {
          return AsyncError(
            sessionsAsync.error!,
            sessionsAsync.stackTrace ?? StackTrace.current,
          );
        }
        return const AsyncLoading();
      }

      if (subjectsAsync.hasError) {
        return AsyncError(
          subjectsAsync.error!,
          subjectsAsync.stackTrace ?? StackTrace.current,
        );
      }

      if (sessionsAsync.hasError) {
        return AsyncError(
          sessionsAsync.error!,
          sessionsAsync.stackTrace ?? StackTrace.current,
        );
      }

      final subjects = subjectsAsync.value ?? [];
      final sessions = sessionsAsync.value ?? [];
      final calculator = ref.watch(attendanceCalculatorProvider);

      final now = DateTime.now();
      final yearMonthPrefix =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
      final monthSessions = sessions
          .where((s) => s.sessionDate.startsWith(yearMonthPrefix))
          .toList();

      final summary = calculator.calculateSemester(
        semester: activeSemester,
        subjects: subjects,
        sessions: monthSessions,
      );

      return AsyncData(summary);
    });

final dayNoteRepositoryProvider = Provider<DayNoteRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DayNoteRepositoryImpl(db);
});

final dayNoteForDateFamilyProvider = StreamProvider.family<DayNote?, String>((
  ref,
  dateStr,
) {
  final activeSemester = ref.watch(activeSemesterProvider);
  if (activeSemester == null) {
    return Stream.value(null);
  }
  final repo = ref.watch(dayNoteRepositoryProvider);
  return repo.watchNoteForDate(activeSemester.id, dateStr);
});

final dayNotesForMonthProvider = StreamProvider<Map<String, String>>((ref) {
  final activeSemester = ref.watch(activeSemesterProvider);
  if (activeSemester == null) {
    return Stream.value({});
  }
  final currentMonth = ref.watch(currentMonthProvider);
  final yearMonthPrefix =
      '${currentMonth.year.toString().padLeft(4, '0')}-${currentMonth.month.toString().padLeft(2, '0')}';
  final repo = ref.watch(dayNoteRepositoryProvider);
  return repo.watchNotesForMonth(activeSemester.id, yearMonthPrefix).map((
    notes,
  ) {
    final map = <String, String>{};
    for (final note in notes) {
      map[note.date] = note.content;
    }
    return map;
  });
});

class DayNoteController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> saveNote({required String date, required String content}) async {
    final activeSemester = ref.read(activeSemesterProvider);
    if (activeSemester == null) return;

    state = const AsyncLoading();
    try {
      final repo = ref.read(dayNoteRepositoryProvider);
      await repo.setNoteForDate(
        semesterId: activeSemester.id,
        date: date,
        content: content,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteNote({required String date}) async {
    final activeSemester = ref.read(activeSemesterProvider);
    if (activeSemester == null) return;

    state = const AsyncLoading();
    try {
      final repo = ref.read(dayNoteRepositoryProvider);
      await repo.deleteNoteForDate(semesterId: activeSemester.id, date: date);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final dayNoteControllerProvider =
    AsyncNotifierProvider<DayNoteController, void>(DayNoteController.new);
