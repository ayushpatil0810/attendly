import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/semesters/domain/entities/semester.dart';
import 'package:attendly/features/semesters/domain/entities/semester_qr_payload.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

final semesterQrPayloadProvider =
    FutureProvider.autoDispose.family<SemesterQrPayload, int>((ref, semesterId) async {
  final repo = ref.watch(semesterRepositoryProvider);
  return repo.exportSemesterPayload(semesterId);
});

class ShareSemesterQrSheet extends ConsumerWidget {
  const ShareSemesterQrSheet({
    super.key,
    required this.semester,
  });

  final Semester semester;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payloadAsync = ref.watch(semesterQrPayloadProvider(semester.id));

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.divider,
                borderRadius: AppRadius.pillBorder,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Share Semester',
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                  AppCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 20),

            payloadAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.brandViolet),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: AppErrorState(
                  message: 'Could not generate QR code for this semester.',
                  onRetry: () => ref.invalidate(semesterQrPayloadProvider(semester.id)),
                ),
              ),
              data: (payload) {
                if (payload.subjects.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppColors.softPeach,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const AppIcon(
                            AppIcons.alert,
                            size: 24,
                            color: AppColors.inkPeach,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No courses in this semester',
                          style: AppTypography.itemTitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add at least one subject to this semester before sharing it with classmates.',
                          style: AppTypography.bodyMuted,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          label: 'Close',
                          variant: AppButtonVariant.outline,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                }

                final encodedString = payload.toEncodedString();

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      // Header Card with semester title & meta badges
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.softLavender.withValues(alpha: 0.6),
                          borderRadius: AppRadius.mdBorder,
                          border: Border.all(
                            color: AppColors.brandViolet.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payload.semesterName,
                              style: AppTypography.sectionTitle.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _MetaChip(
                                  icon: AppIcons.check,
                                  label: '${payload.thresholdPercent}% Goal',
                                  color: AppColors.inkViolet,
                                  backgroundColor: AppColors.pureWhite,
                                ),
                                _MetaChip(
                                  icon: AppIcons.subjects,
                                  label: '${payload.subjects.length} courses',
                                  color: AppColors.inkViolet,
                                  backgroundColor: AppColors.pureWhite,
                                ),
                                _MetaChip(
                                  icon: AppIcons.insights,
                                  label: payload.calculationMethod.displayName,
                                  color: AppColors.mutedInk,
                                  backgroundColor: AppColors.pureWhite,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // QR Code Container with High-Contrast White Background
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: AppRadius.lgBorder,
                          border: Border.all(color: AppColors.border, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Semantics(
                          label: 'QR Code for semester ${payload.semesterName} with ${payload.subjects.length} courses',
                          child: QrImageView(
                            data: encodedString,
                            version: QrVersions.auto,
                            size: 210.0,
                            backgroundColor: AppColors.pureWhite,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.ink,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Guidance caption
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppIcon(
                            AppIcons.scan,
                            size: 16,
                            color: AppColors.brandViolet,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Have your classmate scan this using Attendly',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.inkViolet,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Shares course names and settings only. Personal attendance records remain 100% private.',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.mutedInk,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Fallback copy button
                      AppButton(
                        label: 'Copy Code Data',
                        icon: const AppIcon(
                          AppIcons.exportFile,
                          size: 16,
                          color: AppColors.pureWhite,
                        ),
                        variant: AppButtonVariant.primary,
                        isFullWidth: true,
                        size: AppButtonSize.medium,
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: encodedString));
                          AppHaptics.lightImpact(ref);
                          if (context.mounted) {
                            AppToast.showSuccess(
                              context,
                              message: 'Semester code copied to clipboard.',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final dynamic icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

void showShareSemesterQrSheet({
  required BuildContext context,
  required Semester semester,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.pureWhite,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (context) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: ShareSemesterQrSheet(semester: semester),
      );
    },
  );
}
