import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/backup/backup_format.dart';
import 'package:attendly/core/backup/backup_providers.dart';
import 'package:attendly/core/backup/backup_validator.dart';
import 'package:attendly/core/services/platform_file_service.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/theme/app_theme_id.dart';
import 'package:attendly/core/theme/theme_provider.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

class BackupOperationState {
  const BackupOperationState({
    this.isExporting = false,
    this.isRestoring = false,
    this.lastExportResult,
    this.errorMessage,
  });

  final bool isExporting;
  final bool isRestoring;
  final ExportFileResult? lastExportResult;
  final String? errorMessage;

  BackupOperationState copyWith({
    bool? isExporting,
    bool? isRestoring,
    ExportFileResult? lastExportResult,
    String? errorMessage,
  }) {
    return BackupOperationState(
      isExporting: isExporting ?? this.isExporting,
      isRestoring: isRestoring ?? this.isRestoring,
      lastExportResult: lastExportResult ?? this.lastExportResult,
      errorMessage: errorMessage,
    );
  }
}

class BackupController extends Notifier<BackupOperationState> {
  @override
  BackupOperationState build() => const BackupOperationState();

  /// Exports current attendance database to a JSON file and prompts the platform save/share sheet
  Future<ExportFileResult> exportBackup() async {
    state = state.copyWith(isExporting: true, errorMessage: null);

    try {
      final backupService = ref.read(backupServiceProvider);
      final fileService = ref.read(platformFileServiceProvider);
      final preferences = ref.read(appPreferencesProvider);
      final themeMode = ref.read(themeModeProvider);
      final activeThemeId = ref.read(activeThemeIdProvider);

      final jsonContent = await backupService.exportBackupJson(
        appPreferences: {
          'hapticFeedbackEnabled': preferences.hapticFeedbackEnabled,
          'themeMode': themeMode.name,
          'colorThemeId': activeThemeId.id,
        },
      );

      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final fileName = 'attendly_backup_$timestamp.json';

      final result = await fileService.exportBackupFile(
        fileName: fileName,
        jsonContent: jsonContent,
      );

      state = state.copyWith(isExporting: false, lastExportResult: result);
      return result;
    } catch (e) {
      final err = e.toString();
      state = state.copyWith(isExporting: false, errorMessage: err);
      return ExportFileResult(isSuccess: false, errorMessage: err);
    }
  }

  /// Prompts user to select a JSON file and validates its contents without touching the database
  Future<BackupValidationResult?> pickAndValidateBackup() async {
    try {
      final fileService = ref.read(platformFileServiceProvider);
      final backupService = ref.read(backupServiceProvider);

      final content = await fileService.pickBackupJsonFile();
      if (content == null) {
        return null; // User cancelled
      }

      return backupService.validateBackup(content);
    } catch (e) {
      return BackupValidationResult.failure(e.toString());
    }
  }

  /// Restores data from validated [BackupData] within an atomic transaction
  Future<bool> executeRestore(BackupData data) async {
    state = state.copyWith(isRestoring: true, errorMessage: null);

    try {
      final backupService = ref.read(backupServiceProvider);
      final newActiveSemesterId = await backupService.restoreBackup(data);

      // Restore preferences if included
      if (data.appPreferences != null) {
        final haptic = data.appPreferences!['hapticFeedbackEnabled'];
        if (haptic is bool) {
          ref.read(appPreferencesProvider.notifier).setHapticFeedback(haptic);
        }
        final themeModeName = data.appPreferences!['themeMode'];
        if (themeModeName is String) {
          final mode = ThemeMode.values.firstWhere(
            (m) => m.name == themeModeName,
            orElse: () => ThemeMode.system,
          );
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        }
        final colorThemeId = data.appPreferences!['colorThemeId'];
        if (colorThemeId is String) {
          ref
              .read(activeThemeIdProvider.notifier)
              .setThemeId(AppThemeId.fromId(colorThemeId));
        }
      }

      // Update active semester selection
      if (newActiveSemesterId != null) {
        ref
            .read(selectedSemesterIdProvider.notifier)
            .selectSemester(newActiveSemesterId);
      } else {
        ref.read(selectedSemesterIdProvider.notifier).clearSelection();
      }

      // Invalidate reactive providers to force complete UI refresh
      ref.invalidate(activeSemestersStreamProvider);
      ref.invalidate(allSemestersStreamProvider);
      ref.invalidate(activeSemesterProvider);
      ref.invalidate(semesterAttendanceSummaryProvider);

      state = state.copyWith(isRestoring: false);
      return true;
    } catch (e) {
      state = state.copyWith(isRestoring: false, errorMessage: e.toString());
      return false;
    }
  }
}

final backupControllerProvider =
    NotifierProvider<BackupController, BackupOperationState>(
      BackupController.new,
    );
