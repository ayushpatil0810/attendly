import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'app_colors.dart';

/// Centralized icon mappings using Hugeicons exclusively
abstract final class AppIcons {
  // Navigation dock destinations
  static const home = HugeIcons.strokeRoundedHome01;
  static const subjects = HugeIcons.strokeRoundedBook02;
  static const quickLog = HugeIcons.strokeRoundedAdd01;
  static const history = HugeIcons.strokeRoundedCalendar03;
  static const insights = HugeIcons.strokeRoundedAnalytics01;

  // Actions
  static const add = HugeIcons.strokeRoundedAdd01;
  static const edit = HugeIcons.strokeRoundedEdit02;
  static const delete = HugeIcons.strokeRoundedDelete02;
  static const check = HugeIcons.strokeRoundedTick01;
  static const close = HugeIcons.strokeRoundedCancel01;
  static const back = HugeIcons.strokeRoundedArrowLeft01;
  static const forward = HugeIcons.strokeRoundedArrowRight01;
  static const arrowDown = HugeIcons.strokeRoundedArrowDown01;
  static const settings = HugeIcons.strokeRoundedSettings02;
  static const undo = HugeIcons.strokeRoundedRotateLeft01;
  static const archive = HugeIcons.strokeRoundedArchive02;
  static const more = HugeIcons.strokeRoundedMoreHorizontal;

  // Components & Concepts
  static const lecture = HugeIcons.strokeRoundedTeacher;
  static const lab = HugeIcons.strokeRoundedFlaskRound;
  static const calendar = HugeIcons.strokeRoundedCalendar03;
  static const info = HugeIcons.strokeRoundedInformationCircle;
  static const alert = HugeIcons.strokeRoundedAlertCircle;
  static const exportFile = HugeIcons.strokeRoundedUpload01;
  static const importFile = HugeIcons.strokeRoundedDownload01;
  static const shield = HugeIcons.strokeRoundedShield01;
  static const file = HugeIcons.strokeRoundedFile01;
  static const device = HugeIcons.strokeRoundedSmartPhone01;
  static const database = HugeIcons.strokeRoundedDatabase;
  static const note = HugeIcons.strokeRoundedNote01;
}

/// Standardized HugeIcon wrapper for uniform styling
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = 22.0,
    this.color = AppColors.ink,
    this.semanticLabel,
  });

  final dynamic icon;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconWidget = ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: HugeIcon(icon: icon, color: Colors.black, size: size),
    );
    if (semanticLabel != null) {
      return Semantics(label: semanticLabel, child: iconWidget);
    }
    return iconWidget;
  }
}
