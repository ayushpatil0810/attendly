import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized icon mappings using Material Icons exclusively
abstract final class AppIcons {
  // Navigation dock destinations (Regular for inactive, Fill for active)
  static const home = Icons.home_outlined;
  static const homeFill = Icons.home;
  static const subjects = Icons.menu_book_outlined;
  static const subjectsFill = Icons.menu_book;
  static const quickLog = Icons.add;
  static const history = Icons.calendar_today_outlined;
  static const historyFill = Icons.calendar_today;
  static const insights = Icons.insights_outlined;
  static const insightsFill = Icons.insights;

  // Actions
  static const add = Icons.add;
  static const edit = Icons.edit_outlined;
  static const delete = Icons.delete_outline;
  static const check = Icons.check;
  static const checkCircle = Icons.check_circle;
  static const checkCircleOutlined = Icons.check_circle_outline;
  static const close = Icons.close;
  static const back = Icons.arrow_back;
  static const forward = Icons.arrow_forward;
  static const arrowDown = Icons.keyboard_arrow_down;
  static const arrowUp = Icons.keyboard_arrow_up;
  static const caretRight = Icons.chevron_right;
  static const settings = Icons.settings_outlined;
  static const undo = Icons.undo;
  static const archive = Icons.archive_outlined;
  static const more = Icons.more_horiz;

  // Components & Concepts
  static const lecture = Icons.school_outlined;
  static const lab = Icons.science_outlined;
  static const calendar = Icons.calendar_today_outlined;
  static const info = Icons.info_outline;
  static const alert = Icons.warning_amber_rounded;
  static const exportFile = Icons.upload_file_outlined;
  static const importFile = Icons.file_download_outlined;
  static const shield = Icons.shield_outlined;
  static const file = Icons.description_outlined;
  static const device = Icons.smartphone_outlined;
  static const database = Icons.storage_outlined;
  static const note = Icons.edit_note_outlined;
  static const qrCode = Icons.qr_code_2;
  static const scan = Icons.qr_code_scanner;
  static const flash = Icons.flash_on;
  static const flashOff = Icons.flash_off;
  static const notification = Icons.notifications_outlined;
  static const clock = Icons.access_time_outlined;
  static const target = Icons.track_changes;
  static const trophy = Icons.emoji_events_outlined;
  static const award = Icons.military_tech_outlined;
  static const flag = Icons.flag_outlined;
  static const sun = Icons.light_mode_outlined;
  static const moon = Icons.dark_mode_outlined;
  static const palette = Icons.palette_outlined;
}

/// Standardized Icon wrapper for uniform styling
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = 22.0,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    return Icon(
      icon,
      size: size,
      color: color ?? iconTheme.color ?? context.colors.textPrimary,
      semanticLabel: semanticLabel,
    );
  }
}
