import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/shared/widgets/app_floating_dock.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/features/attendance/presentation/widgets/quick_log_sheet.dart';
import 'package:attendly/features/subjects/presentation/screens/subjects_screen.dart';

import 'history_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _onQuickLogPressed() {
    showQuickLogSheet(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Destination screens
          IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(onNavigateToSubjects: () => _onDestinationSelected(1)),
              const SubjectsScreen(),
              const HistoryScreen(),
              const InsightsScreen(),
            ],
          ),

          // Floating Bottom Navigation Dock
          Align(
            alignment: Alignment.bottomCenter,
            child: AppFloatingDock(
              currentIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              onQuickLogPressed: _onQuickLogPressed,
            ),
          ),
        ],
      ),
    );
  }
}
