import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/features/attendance/domain/entities/attendance_status.dart';
import 'package:attendly/features/attendance/domain/entities/hypothetical_session.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/domain/entities/simulator_projection.dart';
import 'package:attendly/features/attendance/domain/services/scenario_calculator.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';
import 'package:attendly/features/subjects/presentation/providers/subjects_provider.dart';

final scenarioCalculatorProvider = Provider<ScenarioCalculator>((ref) {
  final attendanceCalc = ref.watch(attendanceCalculatorProvider);
  return ScenarioCalculator(attendanceCalculator: attendanceCalc);
});

class SimulatorController extends Notifier<List<HypotheticalSession>> {
  @override
  List<HypotheticalSession> build() => const [];

  int _nextId = 1;

  /// Adds a single hypothetical session.
  void addSession({
    required int subjectId,
    required SessionComponent component,
    required AttendanceStatus status,
  }) {
    final newSession = HypotheticalSession(
      id: 'hypo_${DateTime.now().microsecondsSinceEpoch}_${_nextId++}',
      subjectId: subjectId,
      component: component,
      status: status,
    );
    state = [...state, newSession];
  }

  /// Adds multiple identical hypothetical sessions at once (e.g. +3 Present).
  void addMultipleSessions({
    required int subjectId,
    required SessionComponent component,
    required AttendanceStatus status,
    required int count,
  }) {
    if (count <= 0) return;
    final newSessions = <HypotheticalSession>[];
    final baseTime = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < count; i++) {
      newSessions.add(
        HypotheticalSession(
          id: 'hypo_${baseTime}_${_nextId++}',
          subjectId: subjectId,
          component: component,
          status: status,
        ),
      );
    }
    state = [...state, ...newSessions];
  }

  /// Toggles status between Present and Absent for a hypothetical session.
  void toggleSessionStatus(String id) {
    state = state.map((s) {
      if (s.id == id) {
        final newStatus = s.isPresent
            ? AttendanceStatus.absent
            : AttendanceStatus.present;
        return s.copyWith(status: newStatus);
      }
      return s;
    }).toList();
  }

  /// Updates subject, component, or status of a hypothetical session.
  void updateSession({
    required String id,
    int? subjectId,
    SessionComponent? component,
    AttendanceStatus? status,
  }) {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(
          subjectId: subjectId,
          component: component,
          status: status,
        );
      }
      return s;
    }).toList();
  }

  /// Removes a hypothetical session by its ID.
  void removeSession(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  /// Resets and clears all hypothetical sessions.
  ///
  /// This only clears in-memory simulated sessions and NEVER deletes or modifies actual records.
  void reset() {
    state = const [];
  }
}

final simulatorControllerProvider =
    NotifierProvider<SimulatorController, List<HypotheticalSession>>(
      SimulatorController.new,
    );

/// Computes the [SimulatorProjection] reactively.
///
/// Combines the immutable active semester attendance baseline from Drift
/// with the ephemeral hypothetical sessions currently configured in memory.
final simulatorProjectionProvider = Provider<AsyncValue<SimulatorProjection?>>((
  ref,
) {
  final activeSemester = ref.watch(activeSemesterProvider);
  if (activeSemester == null) {
    return const AsyncData(null);
  }

  final subjectsAsync = ref.watch(activeSemesterSubjectsProvider);
  final sessionsAsync = ref.watch(activeSemesterSessionsStreamProvider);
  final hypotheticalSessions = ref.watch(simulatorControllerProvider);

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
  final actualSessions = sessionsAsync.value ?? [];
  final scenarioCalculator = ref.watch(scenarioCalculatorProvider);

  final projection = scenarioCalculator.calculateProjection(
    semester: activeSemester,
    subjects: subjects,
    actualSessions: actualSessions,
    hypotheticalSessions: hypotheticalSessions,
  );

  return AsyncData(projection);
});
