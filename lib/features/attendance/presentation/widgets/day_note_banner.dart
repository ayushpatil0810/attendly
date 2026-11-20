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
    final colors = context.colors;
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
            borderRadius: BorderRadius.circular(16),
            child: Semantics(
              button: true,
              label: '+ Add note for this day',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle.withValues(
                    alpha: colors.isDark ? 0.6 : 0.8,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.border.withValues(
                      alpha: colors.isDark ? 0.4 : 0.6,
                    ),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      AppIcons.note,
                      size: 14,
                      color: colors.brandPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+ Add note for this day',
                      style: AppTypography.caption1.copyWith(
                        color: colors.brandPrimary,
                        fontWeight: FontWeight.w700,
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
              color: colors.surfaceSubtle,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(
                color: colors.border.withValues(
                  alpha: colors.isDark ? 0.6 : 0.8,
                ),
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppIcon(
                  AppIcons.note,
                  size: 15,
                  color: colors.brandPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.content,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textPrimary,
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
                    size: 15,
                    color: colors.brandPrimary,
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
                    size: 15,
                    color: colors.textTertiary,
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
