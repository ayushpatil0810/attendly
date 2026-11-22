import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/attendance_status.dart';

/// Reusable Apple HIG-styled attendance action button with live counter badge
/// and built-in undo/decrement stepper affordance.
///
/// Shared across both single-subject (Log Attendance) and multi-subject (Quick Log) drawers.
class AttendanceActionButton extends StatelessWidget {
  const AttendanceActionButton({
    super.key,
    required this.status,
    required this.count,
    required this.onTap,
    this.onDecrement,
    this.isLoading = false,
    this.semanticSubjectName,
    this.semanticComponentLabel,
  });

  final AttendanceStatus status;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onDecrement;
  final bool isLoading;
  final String? semanticSubjectName;
  final String? semanticComponentLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPresent = status == AttendanceStatus.present;
    final isLogged = count > 0;

    // Default (Idle) State: neutral filled surface (#2C2C2E in Dark, #F2F2F7 in Light) with no colored border
    // Active (Logged) State: solid semantic fill (calibrated green for Present, calibrated red for Absent)
    final idleBgColor =
        colors.isDark ? colors.surfaceSubtle : colors.background;
    final activeBgColor = isPresent ? colors.present : colors.absent;
    final bgColor = isLogged ? activeBgColor : idleBgColor;

    // In idle state, text is primary color and icon is semantic green/red.
    // In active state, icon, text, and counter are bold white.
    final iconColor = isLogged
        ? Colors.white
        : (isPresent ? colors.present : colors.absent);
    final textColor = isLogged ? Colors.white : colors.textPrimary;
    final iconData = isPresent ? AppIcons.check : AppIcons.close;
    final statusName = isPresent ? 'Present' : 'Absent';

    final labelText = isLogged ? '$statusName · $count' : statusName;
    final actionSemantics = isLogged
        ? 'Mark $statusName for $semanticSubjectName $semanticComponentLabel, $count currently logged'
        : 'Mark $statusName for $semanticSubjectName $semanticComponentLabel';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: 44,
      constraints: const BoxConstraints(minWidth: 88, minHeight: 44),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(11),
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Undo / Decrement Stepper Button (only visible when count > 0)
                if (isLogged && onDecrement != null) ...[
                  Semantics(
                    button: true,
                    label:
                        'Remove 1 $statusName for $semanticSubjectName $semanticComponentLabel',
                    child: Tooltip(
                      message: 'Remove 1 $statusName',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onDecrement!();
                          },
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(11),
                            bottomLeft: Radius.circular(11),
                          ),
                          child: Container(
                            width: 32,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.remove,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.8,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ],

                // Main Increment Action Button
                Semantics(
                  button: true,
                  label: actionSemantics,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onTap();
                      },
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isLogged ? 0 : 11),
                        bottomLeft: Radius.circular(isLogged ? 0 : 11),
                        topRight: const Radius.circular(11),
                        bottomRight: const Radius.circular(11),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(iconData, size: 14, color: iconColor),
                            const SizedBox(width: 4),
                            Text(
                              labelText,
                              style: AppTypography.footnote.copyWith(
                                color: textColor,
                                fontWeight: isLogged
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: -0.2,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
