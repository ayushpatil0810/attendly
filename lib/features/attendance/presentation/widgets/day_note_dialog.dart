import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/shared/widgets/app_button.dart';
import 'package:attendly/core/shared/widgets/app_text_field.dart';
import 'package:attendly/core/shared/widgets/app_toast.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_typography.dart';

import '../providers/attendance_providers.dart';

Future<void> showDayNoteDialog({
  required BuildContext context,
  WidgetRef? ref,
  required String dateStr,
  String? initialContent,
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime? parsedDate;
  try {
    parsedDate = DateTime.parse(dateStr);
  } catch (_) {}
  if (parsedDate != null &&
      DateTime(parsedDate.year, parsedDate.month, parsedDate.day).isAfter(today)) {
    AppToast.showError(context, message: 'Cannot add notes for future dates.');
    return;
  }
  return showDialog<void>(
    context: context,
    builder: (ctx) =>
        _DayNoteDialog(dateStr: dateStr, initialContent: initialContent),
  );
}

class _DayNoteDialog extends ConsumerStatefulWidget {
  const _DayNoteDialog({required this.dateStr, this.initialContent});

  final String dateStr;
  final String? initialContent;

  @override
  ConsumerState<_DayNoteDialog> createState() => _DayNoteDialogState();
}

class _DayNoteDialogState extends ConsumerState<_DayNoteDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(widget.dateStr);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final formattedDate = DateFormat('EEE, d MMM yyyy').format(parsedDate);
    final isEditing =
        widget.initialContent != null &&
        widget.initialContent!.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.surfaceSubtle.withValues(
                alpha: colors.isDark ? 0.6 : 0.8,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.border.withValues(
                  alpha: colors.isDark ? 0.4 : 0.6,
                ),
                width: 0.5,
              ),
            ),
            alignment: Alignment.center,
            child: AppIcon(
              AppIcons.note,
              size: 18,
              color: colors.brandPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Day Note' : 'Add Day Note',
                  style: AppTypography.itemTitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  formattedDate,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AppTextField(
            controller: _controller,
            hint: 'e.g. Sports Day, Medical leave, Rain holiday, Fest',
            maxLines: 3,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            if (isEditing)
              IconButton(
                tooltip: 'Delete note',
                icon: AppIcon(
                  AppIcons.delete,
                  size: 18,
                  color: colors.accentRed,
                ),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        final parentContext = context;
                        final noteToDelete = widget.initialContent;
                        Navigator.of(context).pop();
                        try {
                          await ref
                              .read(dayNoteControllerProvider.notifier)
                              .deleteNote(date: widget.dateStr);
                          if (parentContext.mounted) {
                            AppToast.showInfo(
                              parentContext,
                              message: 'Day note deleted.',
                              actionLabel: noteToDelete != null ? 'Undo' : null,
                              onAction: noteToDelete != null
                                  ? () async {
                                      await ref
                                          .read(
                                            dayNoteControllerProvider.notifier,
                                          )
                                          .saveNote(
                                            date: widget.dateStr,
                                            content: noteToDelete,
                                          );
                                      if (parentContext.mounted) {
                                        AppToast.showSuccess(
                                          parentContext,
                                          message: 'Day note restored.',
                                        );
                                      }
                                    }
                                  : null,
                            );
                          }
                        } catch (_) {
                          if (parentContext.mounted) {
                            AppToast.showError(
                              parentContext,
                              message: 'Could not delete note.',
                            );
                          }
                        }
                      },
              ),
            const Spacer(),
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.labelMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: 'Save',
              size: AppButtonSize.small,
              isLoading: _isSaving,
              onPressed: () async {
                final text = _controller.text.trim();
                setState(() => _isSaving = true);
                final parentContext = context;
                Navigator.of(context).pop();
                try {
                  await ref
                      .read(dayNoteControllerProvider.notifier)
                      .saveNote(date: widget.dateStr, content: text);
                  if (parentContext.mounted) {
                    AppToast.showSuccess(
                      parentContext,
                      message: text.isEmpty
                          ? 'Day note cleared.'
                          : 'Day note saved.',
                    );
                  }
                } catch (_) {
                  if (parentContext.mounted) {
                    AppToast.showError(
                      parentContext,
                      message: 'Could not save note.',
                    );
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
