import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

final semesterQrPayloadProvider = FutureProvider.autoDispose
    .family<SemesterQrPayload, int>((ref, semesterId) async {
      final repo = ref.watch(semesterRepositoryProvider);
      return repo.exportSemesterPayload(semesterId);
    });

class ShareSemesterQrSheet extends ConsumerWidget {
  const ShareSemesterQrSheet({super.key, required this.semester});

  final Semester semester;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
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
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: AppRadius.pillBorder,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Share Semester',
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                  AppCloseButton(onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            const SizedBox(height: 16),

            payloadAsync.when(
              loading: () => SizedBox(
                height: 280,
                child: Center(
                  child: CircularProgressIndicator(
                    color: colors.brandPrimary,
                  ),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: AppErrorState(
                  message: 'Could not generate QR code for this semester.',
                  onRetry: () =>
                      ref.invalidate(semesterQrPayloadProvider(semester.id)),
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
                          decoration: BoxDecoration(
                            color: colors.accentOrange.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: AppIcon(
                            AppIcons.alert,
                            size: 24,
                            color: colors.accentOrange,
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

                return Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Semester Title (Typographic hero, no unearned card)
                        Text(
                          payload.semesterName,
                          style: AppTypography.screenTitle.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: colors.textPrimary,
                            height: 1.25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Distilled Metadata Badges
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _MetaBadge(
                              icon: AppIcons.check,
                              label: '${payload.thresholdPercent}% Goal',
                            ),
                            _MetaBadge(
                              icon: AppIcons.subjects,
                              label:
                                  '${payload.subjects.length} ${payload.subjects.length == 1 ? "course" : "courses"}',
                            ),
                            _MetaBadge(
                              icon: AppIcons.insights,
                              label: payload.calculationMethod.displayName,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // QR Code Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(
                              color: colors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Semantics(
                            label:
                                'QR Code for semester ${payload.semesterName} with ${payload.subjects.length} courses',
                            child: QrImageView(
                              data: encodedString,
                              version: QrVersions.auto,
                              size: 210.0,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Guidance Lockup
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              AppIcons.scan,
                              size: 16,
                              color: colors.brandPrimary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Scan with Attendly on another phone',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Privacy Reassurance
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              AppIcons.shield,
                              size: 13,
                              color: colors.textTertiary,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Shares courses and targets only · Attendance records stay private',
                                style: AppTypography.bodySmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Primary Action
                        AppButton(
                          label: 'Copy Code Data',
                          icon: const AppIcon(
                            AppIcons.exportFile,
                            size: 16,
                            color: Colors.white,
                          ),
                          variant: AppButtonVariant.primary,
                          isFullWidth: true,
                          size: AppButtonSize.medium,
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: encodedString),
                            );
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

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

  final dynamic icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.isDark
            ? colors.brandPrimary.withValues(alpha: 0.16)
            : colors.brandPrimarySoft,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 12, color: colors.brandPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.withTabularFigures(
              AppTypography.labelSmall.copyWith(
                color: colors.brandPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
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
    backgroundColor: context.colors.surface,
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
