import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: AppColors.pureWhite,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      return Padding(
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: AppRadius.pillBorder,
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title, style: AppTypography.sectionTitle),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.track,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.mutedInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Flexible(child: child),
            ],
          ),
        ),
      );
    },
  );
}
