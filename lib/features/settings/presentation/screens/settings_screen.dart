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
                  vertical: 10,
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
                    const SizedBox(width: 4),
                    const Text('Settings', style: AppTypography.screenTitle),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section A: Semester Settings
                      const AppSectionHeader(
                        title: 'Semester Settings',
                        subtitle: 'Active term calculation policy & threshold',
                      ),
                      const SizedBox(height: 10),
                      SemesterSettingsSection(activeSemester: activeSemester),
                      const SizedBox(height: 28),

                      // Section B: App Preferences
                      const AppSectionHeader(
                        title: 'App Preferences',
                        subtitle: 'Haptic feedback & motion behavior',
                      ),
                      const SizedBox(height: 10),
                      const AppPreferencesSection(),
                      const SizedBox(height: 28),

                      // Section C: Local Backup & Restore
                      const AppSectionHeader(
                        title: 'Local Backup & Restore',
                        subtitle: 'Safe on-device JSON export and import',
                      ),
                      const SizedBox(height: 10),
                      const BackupRestoreSection(),
                      const SizedBox(height: 28),

                      // Section D: Data Safety & Privacy Notice
                      const AppSectionHeader(
                        title: 'Privacy & Offline Guarantee',
                        subtitle: 'Personal offline storage without cloud tracking',
                      ),
                      const SizedBox(height: 10),
                      const PrivacyOfflineSection(),
                      const SizedBox(height: 36),
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
