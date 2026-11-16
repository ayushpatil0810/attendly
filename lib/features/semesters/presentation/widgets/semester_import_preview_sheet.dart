import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_bottom_sheet.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_text_field.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/semesters/domain/entities/semester_qr_payload.dart';
import 'package:attendly/features/semesters/presentation/providers/semesters_provider.dart';

enum _ConflictResolution { importAsNew, replaceExisting }

class SemesterImportPreviewSheet extends ConsumerStatefulWidget {
  const SemesterImportPreviewSheet({
    super.key,
    required this.payload,
    this.onImportSuccess,
  });

  final SemesterQrPayload payload;
  final VoidCallback? onImportSuccess;

  @override
  ConsumerState<SemesterImportPreviewSheet> createState() =>
      _SemesterImportPreviewSheetState();
}

class _SemesterImportPreviewSheetState
    extends ConsumerState<SemesterImportPreviewSheet> {
  late final TextEditingController _nameController;
  _ConflictResolution _conflictResolution = _ConflictResolution.importAsNew;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.payload.semesterName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleImport(bool hasConflict) async {
    final customName = _nameController.text.trim();
    if (customName.isEmpty) {
      AppToast.showError(context, message: 'Semester name cannot be empty.');
      return;
    }

    setState(() => _isImporting = true);

    try {
      final replace =
          hasConflict &&
          _conflictResolution == _ConflictResolution.replaceExisting;

      await ref
          .read(semesterControllerProvider.notifier)
          .importSemesterFromQr(
            widget.payload,
            customName: customName,
            replaceExisting: replace,
          );

      AppHaptics.lightImpact(ref);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      widget.onImportSuccess?.call();

      AppToast.showSuccess(
        context,
        message: 'Semester "$customName" imported successfully!',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      AppToast.showError(
        context,
        message: 'Could not import semester. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSemestersAsync = ref.watch(allSemestersStreamProvider);
    final semesters = allSemestersAsync.value ?? [];
    final currentInputName = _nameController.text.trim();

    final hasConflict = semesters.any(
      (s) => s.name.toLowerCase() == currentInputName.toLowerCase(),
    );

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
                  const Expanded(
                    child: Text(
                      'Import Semester',
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                  AppCloseButton(
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Editable Name Field
                    AppTextField(
                      controller: _nameController,
                      label: 'Semester Name',
                      hint: 'e.g. Fall 2026',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // Metadata Row (Threshold, Calculation Policy, Subject count)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _BadgePill(
                          icon: AppIcons.check,
                          label:
                              '${widget.payload.thresholdPercent}% Attendance Goal',
                          color: AppColors.inkViolet,
                          backgroundColor: AppColors.softLavender,
                        ),
                        _BadgePill(
                          icon: AppIcons.subjects,
                          label: '${widget.payload.subjects.length} Subjects',
                          color: AppColors.inkViolet,
                          backgroundColor: AppColors.softLavender,
                        ),
                        _BadgePill(
                          icon: AppIcons.insights,
                          label: widget.payload.calculationMethod.displayName,
                          color: AppColors.mutedInk,
                          backgroundColor: AppColors.softLavender.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ],
                    ),

                    // Conflict Resolution Notice
                    if (hasConflict) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.softPeach.withValues(alpha: 0.7),
                          borderRadius: AppRadius.mdBorder,
                          border: Border.all(
                            color: AppColors.brandPeach.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const AppIcon(
                                  AppIcons.alert,
                                  size: 16,
                                  color: AppColors.inkPeach,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Semester "$currentInputName" already exists',
                                    style: AppTypography.itemTitle.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Option 1: Import as New
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _conflictResolution =
                                      _ConflictResolution.importAsNew;
                                });
                              },
                              borderRadius: AppRadius.smBorder,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Radio<_ConflictResolution>(
                                      value: _ConflictResolution.importAsNew,
                                      groupValue: _conflictResolution,
                                      activeColor: AppColors.brandViolet,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                            () => _conflictResolution = val,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Import as a new copy ("$currentInputName (Imported)")',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight:
                                              _conflictResolution ==
                                                  _ConflictResolution
                                                      .importAsNew
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Option 2: Replace Existing
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _conflictResolution =
                                      _ConflictResolution.replaceExisting;
                                });
                              },
                              borderRadius: AppRadius.smBorder,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Radio<_ConflictResolution>(
                                      value:
                                          _ConflictResolution.replaceExisting,
                                      groupValue: _conflictResolution,
                                      activeColor: AppColors.brandViolet,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(
                                            () => _conflictResolution = val,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Replace existing semester and its courses',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight:
                                              _conflictResolution ==
                                                  _ConflictResolution
                                                      .replaceExisting
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: AppColors.inkCoral,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    const Text(
                      'Included Courses',
                      style: AppTypography.labelMedium,
                    ),
                    const SizedBox(height: 8),

                    // Subjects List Preview
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: AppRadius.mdBorder,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.payload.subjects.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: AppColors.divider,
                        ),
                        itemBuilder: (context, index) {
                          final subject = widget.payload.subjects[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.softLavender,
                                    borderRadius: AppRadius.smBorder,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkViolet,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    subject.name,
                                    style: AppTypography.itemTitle.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (subject.lectureEnabled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.softLavender,
                                      borderRadius: AppRadius.pillBorder,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const AppIcon(
                                          AppIcons.lecture,
                                          size: 11,
                                          color: AppColors.inkViolet,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Theory',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: AppColors.inkViolet,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (subject.hasBothComponents)
                                  const SizedBox(width: 4),
                                if (subject.labEnabled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.softMint,
                                      borderRadius: AppRadius.pillBorder,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const AppIcon(
                                          AppIcons.lab,
                                          size: 11,
                                          color: AppColors.inkMint,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Lab',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                                color: AppColors.inkMint,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: const BoxDecoration(
                color: AppColors.pureWhite,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'Import Semester',
                      icon: const AppIcon(
                        AppIcons.check,
                        size: 16,
                        color: AppColors.pureWhite,
                      ),
                      isLoading: _isImporting,
                      variant: AppButtonVariant.primary,
                      onPressed: () => _handleImport(hasConflict),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showSemesterImportPreviewSheet({
  required BuildContext context,
  required SemesterQrPayload payload,
  VoidCallback? onImportSuccess,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.pureWhite,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (context) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: SemesterImportPreviewSheet(
          payload: payload,
          onImportSuccess: onImportSuccess,
        ),
      );
    },
  );
}
