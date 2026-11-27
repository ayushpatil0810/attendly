import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/shared/widgets/apple/apple_list_tile.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';

import 'about_attendly_sheet.dart';

/// Apple HIG Inset Grouped section for app metadata, developer attribution,
/// and open-source project links in the Settings screen.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppleInsetGroup(
      header: 'About',
      margin: EdgeInsets.zero,
      children: [
        AppleListTile(
          leading: AppleIconTile(
            icon: AppIcons.info,
            backgroundColor: colors.brandPrimary,
          ),
          title: 'About Attendly',
          subtitle: 'Developer, website & source code',
          showDisclosure: true,
          onTap: () => showAboutAttendlySheet(context),
        ),
      ],
    );
  }
}
