import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'app_colors.dart';

/// Centralized icon mappings using Phosphor Icons exclusively
abstract final class AppIcons {
  // Navigation dock destinations (Regular for inactive, Fill for active)
  static const home = PhosphorIconsRegular.house;
  static const homeFill = PhosphorIconsFill.house;
  static const subjects = PhosphorIconsRegular.books;
  static const subjectsFill = PhosphorIconsFill.books;
  static const quickLog = PhosphorIconsRegular.plus;
  static const history = PhosphorIconsRegular.calendarBlank;
  static const historyFill = PhosphorIconsFill.calendarBlank;
  static const insights = PhosphorIconsRegular.chartLineUp;
  static const insightsFill = PhosphorIconsFill.chartLineUp;

  // Actions
  static const add = PhosphorIconsRegular.plus;
  static const edit = PhosphorIconsRegular.pencilSimple;
  static const delete = PhosphorIconsRegular.trash;
  static const check = PhosphorIconsRegular.check;
  static const close = PhosphorIconsRegular.x;
  static const back = PhosphorIconsRegular.arrowLeft;
  static const forward = PhosphorIconsRegular.arrowRight;
  static const arrowDown = PhosphorIconsRegular.caretDown;
  static const settings = PhosphorIconsRegular.gear;
  static const undo = PhosphorIconsRegular.arrowCounterClockwise;
  static const archive = PhosphorIconsRegular.archive;
  static const more = PhosphorIconsRegular.dotsThree;

  // Components & Concepts
  static const lecture = PhosphorIconsRegular.chalkboardTeacher;
  static const lab = PhosphorIconsRegular.flask;
  static const calendar = PhosphorIconsRegular.calendarBlank;
  static const info = PhosphorIconsRegular.info;
  static const alert = PhosphorIconsRegular.warningCircle;
  static const exportFile = PhosphorIconsRegular.export;
  static const importFile = PhosphorIconsRegular.downloadSimple;
  static const shield = PhosphorIconsRegular.shieldCheck;
  static const file = PhosphorIconsRegular.fileText;
  static const device = PhosphorIconsRegular.deviceMobile;
  static const database = PhosphorIconsRegular.database;
  static const note = PhosphorIconsRegular.notePencil;
  static const qrCode = PhosphorIconsRegular.qrCode;
  static const scan = PhosphorIconsRegular.scan;
  static const flash = PhosphorIconsRegular.lightning;
  static const flashOff = PhosphorIconsRegular.lightningSlash;
  static const notification = PhosphorIconsRegular.bell;
  static const clock = PhosphorIconsRegular.clock;
  static const target = PhosphorIconsRegular.target;
  static const trophy = PhosphorIconsRegular.trophy;
  static const award = PhosphorIconsRegular.medal;
  static const flag = PhosphorIconsRegular.flag;
  static const sun = PhosphorIconsRegular.sun;
  static const moon = PhosphorIconsRegular.moon;
  static const palette = PhosphorIconsRegular.paintBrushBroad;
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
    return Icon(
      icon,
      size: size,
      color: color ?? context.colors.textPrimary,
      semanticLabel: semanticLabel,
    );
  }
}
