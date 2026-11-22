import 'package:flutter/material.dart';
import 'package:attendly/core/shared/widgets/app_segmented_control.dart';
import 'package:attendly/core/shared/widgets/apple/apple_inset_group.dart';
import 'package:attendly/core/theme/app_colors.dart';
import 'package:attendly/core/theme/app_typography.dart';
import 'package:attendly/features/attendance/domain/entities/session_component.dart';
import 'package:attendly/features/attendance/domain/entities/subject_attendance_summary.dart';

/// Item representing a single trackable component in the comparison chart.
class SubjectComparisonItem {
  const SubjectComparisonItem({
    required this.subjectId,
    required this.displayName,
    required this.component,
    required this.presentCount,
    required this.conductedCount,
    this.percentage,
    required this.isAvailable,
    required this.meetsThreshold,
    required this.isBelowThreshold,
    this.isProvisional = false,
  });

  final int subjectId;
  final String displayName;
  final SessionComponent component;
  final int presentCount;
  final int conductedCount;
  final double? percentage;
  final bool isAvailable;
  final bool meetsThreshold;
  final bool isBelowThreshold;
  final bool isProvisional;

  String get formattedPercentage {
    if (percentage == null || !isAvailable) return '—';
    final pct = percentage!;
    if (pct == pct.roundToDouble()) return '${pct.toInt()}%';
    return '${pct.toStringAsFixed(1)}%';
  }
}

class SubjectComparisonCard extends StatefulWidget {
  const SubjectComparisonCard({
    super.key,
    required this.subjectSummaries,
    required this.threshold,
  });

  final List<SubjectAttendanceSummary> subjectSummaries;
  final double threshold;

  @override
  State<SubjectComparisonCard> createState() => _SubjectComparisonCardState();
}

class _SubjectComparisonCardState extends State<SubjectComparisonCard> {
  SessionComponent _selectedComponent = SessionComponent.lecture;
  late List<SubjectComparisonItem> _lectureItems;
  late List<SubjectComparisonItem> _labItems;

  @override
  void initState() {
    super.initState();
    _rebuildItems();
  }

  @override
  void didUpdateWidget(covariant SubjectComparisonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjectSummaries != widget.subjectSummaries ||
        oldWidget.threshold != widget.threshold) {
      _rebuildItems();
    }
  }

  void _rebuildItems() {
    final lectureItems = <SubjectComparisonItem>[];
    for (final s in widget.subjectSummaries) {
      if (s.lectureEnabled) {
        final lecSummary = s.lectureSummary;
        final conducted = lecSummary?.conductedCount ??
            (s.labEnabled ? 0 : s.totalConducted);
        final present = lecSummary?.presentCount ??
            (s.labEnabled ? 0 : s.totalPresent);
        final pct = lecSummary?.percentage ??
            (s.labEnabled ? null : s.percentage);
        final isAvail = lecSummary?.isAvailable ??
            (s.labEnabled ? false : s.isAvailable);
        final meets = lecSummary?.meetsThreshold ??
            (s.labEnabled ? false : s.meetsThreshold);
        final below = lecSummary?.isBelowThreshold ??
            (s.labEnabled ? false : s.isBelowThreshold);

        lectureItems.add(
          SubjectComparisonItem(
            subjectId: s.subjectId,
            displayName: s.subjectName,
            component: SessionComponent.lecture,
            presentCount: present,
            conductedCount: conducted,
            percentage: pct,
            isAvailable: isAvail,
            meetsThreshold: meets,
            isBelowThreshold: below,
            isProvisional: !s.labEnabled && s.isProvisional,
          ),
        );
      }
    }

    final labItems = <SubjectComparisonItem>[];
    for (final s in widget.subjectSummaries) {
      if (s.labEnabled) {
        final labSummary = s.labSummary;
        final conducted = labSummary?.conductedCount ??
            (s.lectureEnabled ? 0 : s.totalConducted);
        final present = labSummary?.presentCount ??
            (s.lectureEnabled ? 0 : s.totalPresent);
        final pct = labSummary?.percentage ??
            (s.lectureEnabled ? null : s.percentage);
        final isAvail = labSummary?.isAvailable ??
            (s.lectureEnabled ? false : s.isAvailable);
        final meets = labSummary?.meetsThreshold ??
            (s.lectureEnabled ? false : s.meetsThreshold);
        final below = labSummary?.isBelowThreshold ??
            (s.lectureEnabled ? false : s.isBelowThreshold);

        final labName = s.subjectName.toLowerCase().endsWith('lab')
            ? s.subjectName
            : '${s.subjectName} Lab';

        labItems.add(
          SubjectComparisonItem(
            subjectId: s.subjectId,
            displayName: labName,
            component: SessionComponent.lab,
            presentCount: present,
            conductedCount: conducted,
            percentage: pct,
            isAvailable: isAvail,
            meetsThreshold: meets,
            isBelowThreshold: below,
            isProvisional: !s.lectureEnabled && s.isProvisional,
          ),
        );
      }
    }

    _lectureItems = lectureItems;
    _labItems = labItems;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjectSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasLabs = _labItems.isNotEmpty;
    final hasLectures = _lectureItems.isNotEmpty;

    // Pick active component tab (default to Lecture; switch to Lab if only labs exist)
    SessionComponent activeComponent = _selectedComponent;
    if (!hasLabs) {
      activeComponent = SessionComponent.lecture;
    } else if (!hasLectures) {
      activeComponent = SessionComponent.lab;
    }

    final currentItems = activeComponent == SessionComponent.lab
        ? [..._labItems]
        : [..._lectureItems];

    // Sort: available by percentage desc; unavailable at end; then alphabetically
    currentItems.sort((a, b) {
      if (a.percentage != null && b.percentage != null) {
        return b.percentage!.compareTo(a.percentage!);
      } else if (a.percentage != null) {
        return -1;
      } else if (b.percentage != null) {
        return 1;
      }
      return a.displayName.compareTo(b.displayName);
    });

    final colors = context.colors;
    final compLabel =
        activeComponent == SessionComponent.lab ? 'Lab' : 'Lecture';

    return AppleInsetGroup(
      header: 'Subject Comparison',
      margin: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Control (Lectures | Labs) shown only if labs exist
              if (hasLabs && hasLectures) ...[
                AppSegmentedControl<SessionComponent>(
                  items: const [
                    SegmentItem(
                      value: SessionComponent.lecture,
                      label: 'Lectures',
                    ),
                    SegmentItem(
                      value: SessionComponent.lab,
                      label: 'Labs',
                    ),
                  ],
                  selectedValue: activeComponent,
                  onChanged: (val) {
                    setState(() => _selectedComponent = val);
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Item Count Header
              Text(
                '${currentItems.length} $compLabel${currentItems.length == 1 ? '' : 's'}',
                style: AppTypography.caption1.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),

              // Animated Transition for Horizontal Bar Chart
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: currentItems.isEmpty
                    ? Padding(
                        key: ValueKey('empty_${activeComponent.name}'),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No $compLabel courses found.',
                          style: AppTypography.footnote.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      )
                    : RepaintBoundary(
                        child: _HorizontalSubjectBarChart(
                          key: ValueKey(activeComponent),
                          items: currentItems,
                          threshold: widget.threshold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HorizontalSubjectBarChart extends StatelessWidget {
  const _HorizontalSubjectBarChart({
    super.key,
    required this.items,
    required this.threshold,
  });

  final List<SubjectComparisonItem> items;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _HorizontalBarItem(
            item: items[i],
            threshold: threshold,
          ),
        ],
      ],
    );
  }
}

class _HorizontalBarItem extends StatelessWidget {
  const _HorizontalBarItem({
    required this.item,
    required this.threshold,
  });

  final SubjectComparisonItem item;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAvailable = item.isAvailable;
    final isProvisional = item.isProvisional;
    final pct = item.percentage;

    Color barColor;
    Color valueColor;
    if (item.meetsThreshold) {
      barColor = colors.present;
      valueColor = colors.present;
    } else if (item.isBelowThreshold) {
      barColor = colors.absent;
      valueColor = colors.absent;
    } else if (isProvisional) {
      barColor = colors.accentOrange;
      valueColor = colors.accentOrange;
    } else {
      barColor = colors.track;
      valueColor = colors.textSecondary;
    }

    final double fillRatio = pct != null ? (pct / 100.0).clamp(0.0, 1.0) : 0.0;

    final String pctLabel = isAvailable && pct != null
        ? '${pct.toStringAsFixed(0)}%'
        : (isProvisional ? 'Prov' : '—');

    final semanticLabel =
        '${item.displayName}: ${item.formattedPercentage}. '
        '${item.presentCount} of ${item.conductedCount} classes attended.';

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Tooltip(
        message:
            '${item.displayName}\n${item.formattedPercentage} (${item.presentCount}/${item.conductedCount})',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Full Component Name on Left, Percentage & Ratio on Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    item.displayName,
                    style: AppTypography.caption1.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      pctLabel,
                      style: AppTypography.caption1.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (item.conductedCount > 0) ...[
                      const SizedBox(width: 5),
                      Text(
                        '(${item.presentCount}/${item.conductedCount})',
                        style: AppTypography.caption2.copyWith(
                          fontSize: 11.5,
                          color: colors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Horizontal Bar Track with Target Tick
            LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final targetX = (barWidth * threshold.clamp(0.0, 1.0))
                    .clamp(0.0, barWidth);

                return SizedBox(
                  height: 10,
                  width: double.infinity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      // Background Track
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.track.withValues(
                            alpha: colors.isDark ? 0.35 : 0.22,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),

                      // Filled Progress Bar
                      if (pct != null && fillRatio > 0)
                        Container(
                          height: 10,
                          width: (barWidth * fillRatio).clamp(0.0, barWidth),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),

                      // Vertical Target Line Tick
                      Positioned(
                        left: (targetX - 1.0).clamp(0.0, barWidth - 2.0),
                        top: -2,
                        bottom: -2,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            color: colors.textPrimary.withValues(
                              alpha: colors.isDark ? 0.45 : 0.30,
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
