import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/preferences_service.dart';
import 'package:attendly/core/shared/widgets/app_segmented_control.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/theme_provider.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);

    return AppleInsetGroup(
      header: 'Appearance',
      margin: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AppSegmentedControl<ThemeMode>(
            items: const [
              SegmentItem(
                value: ThemeMode.system,
                label: 'System',
                icon: Icon(AppIcons.device, size: 16),
              ),
              SegmentItem(
                value: ThemeMode.light,
                label: 'Light',
                icon: Icon(AppIcons.sun, size: 16),
              ),
              SegmentItem(
                value: ThemeMode.dark,
                label: 'Dark',
                icon: Icon(AppIcons.moon, size: 16),
              ),
            ],
            selectedValue: currentMode,
            onChanged: (mode) {
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
              AppHaptics.selectionClick(ref);
            },
          ),
        ),
      ],
    );
  }
}
