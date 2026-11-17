import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_segmented_control.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_radius.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_theme_id.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/core/theme/theme_provider.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final activeThemeId = ref.watch(activeThemeIdProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header: Appearance Mode
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.softLavender,
                  borderRadius: AppRadius.mdBorder,
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  AppIcons.sun,
                  size: 20,
                  color: AppColors.brandViolet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance Mode',
                      style: AppTypography.itemTitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose system sync, light, or dark appearance',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Appearance Segmented Control
          AppSegmentedControl<ThemeMode>(
            items: const [
              SegmentItem(
                value: ThemeMode.system,
                label: 'System',
                icon: Icon(PhosphorIconsRegular.deviceMobile, size: 16),
              ),
              SegmentItem(
                value: ThemeMode.light,
                label: 'Light',
                icon: Icon(PhosphorIconsRegular.sun, size: 16),
              ),
              SegmentItem(
                value: ThemeMode.dark,
                label: 'Dark',
                icon: Icon(PhosphorIconsRegular.moon, size: 16),
              ),
            ],
            selectedValue: currentMode,
            onChanged: (mode) {
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
              AppHaptics.selectionClick(ref);
            },
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 18),

          // Section header: Color Theme
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.softMint,
                  borderRadius: AppRadius.mdBorder,
                ),
                alignment: Alignment.center,
                child: AppIcon(
                  AppIcons.palette,
                  size: 20,
                  color: AppColors.inkMint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pastel Palette',
                      style: AppTypography.itemTitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '8 handcrafted pastel themes for light and dark modes',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.mutedInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2-column Grid of Themes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppThemeId.values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              final theme = AppThemeId.values[index];
              final isSelected = theme == activeThemeId;
              final primaryColor = theme.previewColors[0];

              return InkWell(
                onTap: () {
                  ref.read(activeThemeIdProvider.notifier).setThemeId(theme);
                  AppHaptics.selectionClick(ref);
                },
                borderRadius: AppRadius.mdBorder,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.08)
                        : AppColors.track.withValues(alpha: 0.35),
                    borderRadius: AppRadius.mdBorder,
                    border: Border.all(
                      color: isSelected ? primaryColor : AppColors.divider,
                      width: isSelected ? 1.6 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title row with selection check
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              theme.name,
                              style: AppTypography.itemTitle.copyWith(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected
                                    ? primaryColor
                                    : AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              PhosphorIconsFill.checkCircle,
                              size: 16,
                              color: primaryColor,
                            ),
                        ],
                      ),
                      // Subtitle
                      Text(
                        theme.subtitle,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: AppColors.mutedInk,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Preview Color Swatches
                      Row(
                        children: theme.previewColors.map((color) {
                          return Container(
                            margin: const EdgeInsets.only(right: 5),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.pureWhite.withValues(
                                  alpha: 0.6,
                                ),
                                width: 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
