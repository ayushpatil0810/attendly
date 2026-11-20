import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:attendly/app/router/route_names.dart';
import 'package:attendly/core/shared/widgets/app_error_state.dart';
import 'package:attendly/core/shared/widgets/app_frame.dart';
import 'package:attendly/core/shared/widgets/app_loading_state.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_icons.dart';
import 'package:attendly/core/theme/app_spacing.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/simulator/presentation/providers/simulator_providers.dart';
import 'package:attendly/features/simulator/presentation/widgets/hypothetical_session_list.dart';
import 'package:attendly/features/simulator/presentation/widgets/simulator_input_panel.dart';
import 'package:attendly/features/simulator/presentation/widgets/simulator_projection_card.dart';

class SimulatorScreen extends ConsumerWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Attendance Simulator',
          style: AppTypography.headline.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: AppIcon(AppIcons.back, size: 20, color: colors.textPrimary),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.homePath);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Simulation',
            icon: AppIcon(AppIcons.delete, size: 20, color: colors.textSecondary),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              ref.read(simulatorControllerProvider.notifier).reset();
            },
          ),
        ],
      ),
      body: const SafeArea(
        child: AppFrame(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.sm,
            ),
            child: SimulatorContent(),
          ),
        ),
      ),
    );
  }
}

class SimulatorContent extends ConsumerWidget {
  const SimulatorContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final projectionAsync = ref.watch(simulatorProjectionProvider);

    return projectionAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: AppLoadingState(message: 'Calculating projection...'),
        ),
      ),
      error: (e, _) => AppErrorState(
        message: 'The what-if could not be calculated.',
        onRetry: () => ref.invalidate(simulatorProjectionProvider),
      ),
      data: (projection) {
        if (projection == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No active semester selected.',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SimulatorProjectionCard(projection: projection),
            const SizedBox(height: AppSpacing.lg),
            const SimulatorInputPanel(),
            const SizedBox(height: AppSpacing.lg),
            const HypotheticalSessionList(),
          ],
        );
      },
    );
  }
}
