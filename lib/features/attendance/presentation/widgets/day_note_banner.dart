import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';

import '../providers/attendance_providers.dart';
import 'day_note_dialog.dart';

class DayNoteBanner extends ConsumerWidget {
  const DayNoteBanner({
    super.key,
    required this.dateStr,
    this.isCompact = false,
  });

  final String dateStr;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(dayNoteForDateFamilyProvider(dateStr));
    final note = noteAsync.value;
    final hasNote = note != null && note.content.trim().isNotEmpty;

    if (!hasNote) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AppHaptics.selectionClick(ref);
              showDayNoteDialog(context: context, ref: ref, dateStr: dateStr);
            },
            borderRadius: AppRadius.pillBorder,
            child: Semantics(
              button: true,
              label: '+ Add note for this day',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(
                    color: AppColors.inkViolet.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      AppIcons.note,
                      size: 14,
                      color: AppColors.inkViolet,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+ Add note for this day',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.inkViolet,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.selectionClick(ref);
          showDayNoteDialog(
            context: context,
            ref: ref,
            dateStr: dateStr,
            initialContent: note.content,
          );
        },
        borderRadius: AppRadius.mdBorder,
        child: Semantics(
          label: 'Day note: ${note.content}. Double tap to edit.',
          child: Container(
            padding: EdgeInsets.fromLTRB(
              12,
              isCompact ? 8 : 10,
              6,
              isCompact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppIcon(AppIcons.note, size: 15, color: AppColors.inkViolet),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.content,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Edit day note',
                  icon: AppIcon(
                    AppIcons.edit,
                    size: 14,
                    color: AppColors.inkViolet,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    AppHaptics.selectionClick(ref);
                    showDayNoteDialog(
                      context: context,
                      ref: ref,
                      dateStr: dateStr,
                      initialContent: note.content,
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Delete day note',
                  icon: AppIcon(
                    AppIcons.close,
                    size: 14,
                    color: AppColors.mutedInk,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    AppHaptics.selectionClick(ref);
                    await ref
                        .read(dayNoteControllerProvider.notifier)
                        .deleteNote(date: dateStr);
                    if (context.mounted) {
                      AppToast.showInfo(context, message: 'Day note deleted.');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
