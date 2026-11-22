import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(dateStr);
    } catch (_) {}
    final isFuture = parsedDate != null &&
        DateTime(parsedDate.year, parsedDate.month, parsedDate.day).isAfter(today);

    if (!hasNote) {
      if (isFuture) {
        return const SizedBox.shrink();
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showDayNoteDialog(context: context, ref: ref, dateStr: dateStr);
            },
            borderRadius: BorderRadius.circular(16),
            child: Semantics(
              button: true,
              label: '+ Add note for this day',
              child: Container(
                constraints: const BoxConstraints(minHeight: 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
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
              color: colors.surfaceSubtle.withValues(
                alpha: colors.isDark ? 0.6 : 0.85,
              ),
              borderRadius: AppRadius.mdBorder,
              border: Border.all(
                color: colors.border.withValues(
                  alpha: colors.isDark ? 0.45 : 0.65,
                ),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: colors.isDark ? 0.15 : 0.02,
                  ),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(
                      alpha: colors.isDark ? 0.5 : 0.9,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.border.withValues(
                        alpha: colors.isDark ? 0.35 : 0.5,
                      ),
                      width: 0.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(
                    AppIcons.note,
                    size: 16,
                    color: colors.brandPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DAY NOTE',
                        style: AppTypography.caption2.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Edit day note',
                  icon: AppIcon(
                    AppIcons.edit,
                    size: 16,
                    color: colors.brandPrimary,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
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
                    size: 16,
                    color: colors.textTertiary,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () async {
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
