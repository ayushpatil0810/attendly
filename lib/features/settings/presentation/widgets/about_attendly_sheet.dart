import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/shared/widgets/apple/apple_list_tile.dart';
import 'package:attendly/core/shared/widgets/attendly_brand_mark.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';

/// Shows the Apple HIG styled About Attendly modal sheet.
Future<void> showAboutAttendlySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.88,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: const AboutAttendlySheet(),
          ),
        ),
      );
    },
  );
}

/// A clean, minimal modal sheet presenting developer attribution,
/// open-source repository links, and app metadata adhering to Apple HIG.
class AboutAttendlySheet extends StatelessWidget {
  const AboutAttendlySheet({super.key});

  static const String developerName = 'Ayush Patil';
  static const String websiteUrl = 'https://ayushpatil.in';
  static const String websiteDisplay = 'ayushpatil.in';
  static const String githubUsername = 'ayushpatil0810';
  static const String githubProfileUrl = 'https://github.com/ayushpatil0810';
  static const String repositoryUrl =
      'https://github.com/ayushpatil0810/attendly';
  static const String repositoryDisplay = 'ayushpatil0810/attendly';
  static const String appVersion = '1.0.0';

  Future<void> _openUrl(BuildContext context, String urlString) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        Clipboard.setData(ClipboardData(text: urlString));
        AppToast.showSuccess(
          context,
          message: 'Link copied to clipboard: $urlString',
        );
      }
    } catch (_) {
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: urlString));
        AppToast.showSuccess(
          context,
          message: 'Link copied to clipboard: $urlString',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: AppRadius.pillBorder,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Top Header Row with Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'About',
                style: AppTypography.caption1.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppCloseButton(onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 8),

          // Hero App Brand Mark & Title
          Center(
            child: Column(
              children: [
                const AttendlyBrandMark(size: 60),
                const SizedBox(height: 12),
                Text(
                  'Attendly',
                  style: AppTypography.title2.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Version $appVersion',
                  style: AppTypography.subhead.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Personal, offline-first attendance companion.',
                  textAlign: TextAlign.center,
                  style: AppTypography.footnote.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Developer Section
          AppleInsetGroup(
            header: 'DEVELOPER',
            margin: EdgeInsets.zero,
            children: [
              AppleListTile(
                leading: AppleIconTile(
                  icon: Icons.person_rounded,
                  backgroundColor: colors.brandPrimary,
                ),
                title: developerName,
                subtitle: 'Creator & Developer',
              ),
              AppleListTile(
                leading: const AppleIconTile(
                  icon: Icons.language_rounded,
                  backgroundColor: Color(0xFF5856D6), // Apple Purple
                ),
                title: 'Website',
                subtitle: websiteDisplay,
                showDisclosure: true,
                onTap: () => _openUrl(context, websiteUrl),
              ),
              AppleListTile(
                leading: const AppleIconTile(
                  icon: Icons.code_rounded,
                  backgroundColor: Color(0xFF24292F), // GitHub Dark
                ),
                title: 'GitHub',
                subtitle: '@$githubUsername',
                showDisclosure: true,
                onTap: () => _openUrl(context, githubProfileUrl),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Open Source Section
          AppleInsetGroup(
            header: 'OPEN SOURCE',
            margin: EdgeInsets.zero,
            children: [
              AppleListTile(
                leading: AppleIconTile(
                  icon: Icons.folder_outlined,
                  backgroundColor: colors.accentGreen,
                ),
                title: 'Source Code',
                subtitle: repositoryDisplay,
                showDisclosure: true,
                onTap: () => _openUrl(context, repositoryUrl),
              ),
              AppleListTile(
                leading: const AppleIconTile(
                  icon: AppIcons.shield,
                  backgroundColor: Color(0xFF8E8E93), // Apple System Gray
                ),
                title: 'License',
                subtitle: 'MIT License',
                trailing: Text(
                  'Free & Open',
                  style: AppTypography.footnote.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Privacy Note
          Center(
            child: Text(
              '100% Offline & Private • Zero Trackers',
              style: AppTypography.caption1.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Dismiss Button
          AppButton(
            label: 'Done',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.medium,
            isFullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
