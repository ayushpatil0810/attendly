import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

class SegmentItem<T> {
  const SegmentItem({
    required this.value,
    required this.label,
    this.icon,
    this.description,
  });

  final T value;
  final String label;
  final Widget? icon;
  final String? description;
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<SegmentItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.track,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.value),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: AppMotion.duration(
                  context,
                  const Duration(milliseconds: 180),
                ),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colors.surface : Colors.transparent,
                  borderRadius: AppRadius.mdBorder,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.textPrimary.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.icon != null) ...[
                      item.icon!,
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        item.label,
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
