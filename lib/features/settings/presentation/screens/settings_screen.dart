import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_frame.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

import '../widgets/appearance_section.dart';
import '../widgets/backup_restore_section.dart';
import '../widgets/daily_reminder_section.dart';
import '../widgets/semester_settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSemester = ref.watch(activeSemesterProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: AppFrame(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.only(
              left: AppSpacing.screenHorizontal,
              right: AppSpacing.screenHorizontal,
              top: AppSpacing.screenTop,
              bottom: AppSpacing.safeDockClearance,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Screen Header: Apple Large Title & Subtitle
                Text(
                  'Settings',
                  style: AppTypography.title1.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Preferences & Academic Configuration',
                  style: AppTypography.footnote.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),

                SemesterSettingsSection(activeSemester: activeSemester),
                const SizedBox(height: 24),
                const AppearanceSection(),
                const SizedBox(height: 24),
                const DailyReminderSection(),
                const SizedBox(height: 24),
                const BackupRestoreSection(),
                const SizedBox(height: 20),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Attendly 1.0.0',
                      style: AppTypography.caption2.copyWith(
                        color: colors.textSecondary.withValues(alpha: 0.6),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
