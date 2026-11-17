import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendly/core/services/home_widget_service.dart';
import 'package:attendly/core/shared/widgets/app_floating_dock.dart';
import 'package:attendly/core/shared/widgets/app_frame.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/features/attendance/domain/entities/semester_attendance_summary.dart';
import 'package:attendly/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:attendly/features/attendance/presentation/widgets/quick_log_sheet.dart';
import 'package:attendly/features/subjects/presentation/screens/subjects_screen.dart';

import 'package:attendly/features/attendance/presentation/screens/history_screen.dart';

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
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Check if launched from a home screen widget action (e.g. Quick Log)
    ref.read(homeWidgetServiceProvider).checkInitialLaunchUri().then((uri) {
      if (uri != null) {
        _handleWidgetUri(uri);
      }
    });

    // Listen to foreground/background clicks on widgets
    _widgetClickSub = ref.read(homeWidgetServiceProvider).listenToWidgetClicks((
      uri,
    ) {
      if (uri != null) {
        _handleWidgetUri(uri);
      }
    });
  }

  void _handleWidgetUri(Uri uri) {
    if (uri.host == 'quick-log' || uri.path.contains('quick-log')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showQuickLogSheet(context: context);
        }
      });
    }
  }

  @override
  void dispose() {
    _widgetClickSub?.cancel();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _onQuickLogPressed() {
    showQuickLogSheet(context: context);
  }

  @override
  Widget build(BuildContext context) {
    // Automatically keep home screen widgets synchronized with attendance changes
    ref.listen<AsyncValue<SemesterAttendanceSummary?>>(
      semesterAttendanceSummaryProvider,
      (previous, next) {
        next.whenData((summary) {
          ref.read(homeWidgetServiceProvider).updateWidgets(summary);
        });
      },
    );
    final pages = IndexedStack(
      index: _currentIndex,
      children: [
        HomeScreen(onNavigateToSubjects: () => _onDestinationSelected(1)),
        SubjectsScreen(),
        HistoryScreen(),
        InsightsScreen(),
      ],
    );

    final useRail = AppFrame.useSideRail(context);

    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      resizeToAvoidBottomInset: false,
      body: useRail
          ? Row(
              children: [
                AppSideRail(
                  currentIndex: _currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  onQuickLogPressed: _onQuickLogPressed,
                ),
                Expanded(child: AppFrame(maxWidth: 720, child: pages)),
              ],
            )
          : Stack(
              children: [
                pages,
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
