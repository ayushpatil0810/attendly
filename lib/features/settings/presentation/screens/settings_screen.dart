import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/app/router/route_names.dart';
import 'package:attendly/core/shared/widgets/app_frame.dart';
import 'package:attendly/core/shared/widgets/app_section_header.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

import '../widgets/app_preferences_section.dart';
import '../widgets/backup_restore_section.dart';
import '../widgets/privacy_offline_section.dart';
import '../widgets/semester_settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSemester = ref.watch(activeSemesterProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: AppFrame(
          child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Semantics(
                    label: 'Go back',
                    button: true,
                    child: IconButton(
                      tooltip: 'Back',
                      icon: const AppIcon(
                        AppIcons.back,
                        size: 20,
                        color: AppColors.ink,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.homePath);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Settings', style: AppTypography.screenTitle),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section A: Semester Settings
                    const AppSectionHeader(
                      title: 'Semester Settings',
                      subtitle:
                          'Active semester calculation policy & threshold',
                    ),
                    const SizedBox(height: 8),
                    SemesterSettingsSection(activeSemester: activeSemester),
                    const SizedBox(height: 24),

                    // Section B: App Preferences
                    const AppSectionHeader(
                      title: 'App Preferences',
                      subtitle: 'Tactile and interaction feedback',
                    ),
                    const SizedBox(height: 8),
                    const AppPreferencesSection(),
                    const SizedBox(height: 24),

                    // Section C: Local Backup & Restore
                    const AppSectionHeader(
                      title: 'Local Backup & Restore',
                      subtitle:
                          'Export or import your attendance database safely',
                    ),
                    const SizedBox(height: 8),
                    const BackupRestoreSection(),
                    const SizedBox(height: 24),

                    // Section D: Data Safety & Privacy Notice
                    const AppSectionHeader(
                      title: 'Privacy & Offline Guarantee',
                      subtitle:
                          'Personal offline storage without cloud tracking',
                    ),
                    const SizedBox(height: 8),
                    const PrivacyOfflineSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
