# Development Progress — College Attendance Tracker

## Project Overview
- **Project Name / Identifier:** College Attendance Tracker (Working title: attendly)
- **Current Development Phase:** Phase 4: Insights, Advanced Charts & Attendance Simulator
- **Overall Project Status:** Phase 4 Completed (Ready for Phase 5 review)
- **Description:** A 100% offline-only personal college attendance tracking mobile app built with Flutter, Riverpod, Drift (SQLite), and go_router. Features independent lecture and lab tracking, Raw Combined and Component Average (50/50) attendance calculation methods, safe absence calculations, recovery projections, What-if Attendance Simulator, and a custom design system following soft, colorful, modern minimalism (light theme only, Plus Jakarta Sans, Hugeicons, floating bottom navigation dock).

---

## Phase Tracker

| Phase | Description | Status |
|---|---|---|
| **Phase 1** | **Foundation, Design System & Initial Setup** | **Completed** |
| **Phase 2** | **Attendance Management** | **Completed** |
| **Phase 3** | **Dashboard & Attendance Calculations** | **Completed** |
| **Phase 4** | **Insights, Advanced Charts & Attendance Simulator** | **Completed** |
| Phase 5 | Settings & Data Safety | Not Started |
| Phase 6 | Polish & Release Preparation | Not Started |

---

## Phase 4 Progress & Achievements

### 1. Pre-implementation Baseline & Review
- [x] Reviewed all nine project documents (`PRD.md`, `SPEC.md`, `TECH_STACK.md`, `ARCHITECTURE.md`, `DATABASE.md`, `DESIGN.md`, `TESTING.md`, `AGENTS.md`, `CHANGELOG.md`) and `progress.md`.
- [x] Verified existing tests and static analysis baseline: 112/112 tests passed, 0 analyzer issues found.
- [x] Confirmed existing calculation engine parity and reuse strategy.

### 2. Domain & Calculation Layer (`lib/features/attendance/domain/`)
- [x] **Hypothetical Session Entity (`HypotheticalSession`):**
  - Ephemeral model representing future hypothetical class meetings with subject, component (`lecture`/`lab`), and status (`present`/`absent`).
  - Stored strictly in-memory; never persisted to the database.
- [x] **Simulator Projection Entity (`SimulatorProjection`):**
  - Encapsulates immutable actual baseline summary alongside projected attendance summary, percentage difference delta, and threshold status transition flags (`improvedToThreshold`, `droppedBelowThreshold`).
- [x] **Scenario Calculator Service (`ScenarioCalculator`):**
  - Pure Dart calculation service reusing the authoritative `AttendanceCalculator` engine.
  - Maps hypothetical sessions to ephemeral in-memory sessions with negative IDs, guaranteeing 100% mathematical parity with dashboard calculation rules.
  - Strictly preserves Raw Combined and Component Average (50/50) semantics, including provisional states when enabled components lack recorded sessions.
- [x] **Insights Filter Entity (`InsightsFilter`):**
  - Multi-dimensional filter model supporting Date Range (`allTime`, `last7Days`, `last30Days`, `custom` with `DateTimeRange`), Subject filter (`int? subjectId`), and Component filter (`SessionComponent? component`).
  - Implements pure session evaluation (`matches(session)` and `filterSessions(sessions)`).
- [x] **Insight Observation Generator (`InsightObservationGenerator`):**
  - Pure Dart service that derives short, factual observations strictly from recorded session data.
  - Automatically suppresses observations when total conducted classes < 3 to prevent overconfident conclusions from few sessions.
  - Mathematically identifies threshold adherence, safe absence allowances, recovery requirements, subject-level attention needs, Lecture vs. Lab component imbalances ($\ge 10\%$ difference), and chronological cumulative trend trajectories ($\ge 5\%$ change over $\ge 4$ dates).
  - Strictly avoids generic motivational slogans, unsupported predictions, or claims that unrecorded classes were missed.

### 3. Reactive State Management (Riverpod)
- [x] **Insights Providers (`lib/features/insights/presentation/providers/insights_providers.dart`):**
  - `insightsFilterProvider`: Manages active filter state (date range, subject, component) with reset capability.
  - `filteredSemesterAttendanceSummaryProvider`: Reactive provider that filters the active semester's sessions stream and recalculates the summary using `AttendanceCalculator`.
  - `insightObservationsProvider`: Derives factual observations reactively from the filtered attendance summary.
- [x] **Simulator Providers (`lib/features/simulator/presentation/providers/simulator_providers.dart`):**
  - `scenarioCalculatorProvider`: Exposes pure `ScenarioCalculator`.
  - `simulatorControllerProvider`: In-memory `Notifier<List<HypotheticalSession>>` providing `addSession`, `addMultipleSessions` (batch add), `toggleSessionStatus`, `updateSession`, `removeSession`, and `reset`.
  - `simulatorProjectionProvider`: Reactive provider combining the read-only actual sessions stream from Drift with the ephemeral hypothetical sessions to output `SimulatorProjection`.

### 4. Insights Screen UI (`lib/features/insights/presentation/widgets/` & `InsightsScreen`)
- [x] **Screen Architecture (`InsightsScreen`):**
  - Segmented control (`AppSegmentedControl`) toggling seamlessly between **Insights** and **Simulator** views with soft animations and icons.
  - Proper bottom padding (`AppSpacing.dockClearance`) ensuring zero obstruction by the floating dock.
- [x] **Interactive Filter Bar (`InsightsFilterBar`):**
  - Horizontal scrolling filter pills for Date Range (All Time, Last 7 Days, Last 30 Days, Custom range picker dialog), Subject selector, and Component selector.
  - Actionable "Reset" pill when non-default filter is applied.
- [x] **Attendance Overview (`InsightsOverviewCard`):**
  - Tabular attendance percentage, status badge, threshold reference, and Conducted/Present/Absent breakdown.
  - Custom `_AttendanceDistributionPainter` rendering a clean donut chart of Present vs. Absent sessions.
  - Clear provisional policy banner when Component Average is pending one enabled component.
- [x] **Subject Comparison (`SubjectComparisonCard`):**
  - Compact horizontal comparison bars showing attendance performance across subjects.
  - Vertical target threshold marker indicator on each bar track.
  - Does NOT rank unavailable subjects as 0%; unavailable and provisional subjects are displayed with honest labels.
- [x] **Lecture vs. Lab Comparison (`LectureLabComparisonCard`):**
  - Paired comparison bars showing independent Lecture and Lab counts and percentages for subjects with both components enabled.
  - Variance pills highlighting differences (e.g., `Lab +15% vs Lecture` or `Equal`).
  - Labeled "Not available" when a component has no recorded sessions.
- [x] **Advanced Chronological Trend (`AdvancedTrendCard`):**
  - Cumulative attendance line chart based strictly on actual recorded session dates with date range display.
  - Honest empty state when fewer than two dates have recorded classes.
- [x] **Factual Key Observations (`InsightObservationsSection`):**
  - Clean observation tiles with color-coded icons (mint for positive, coral for warning, violet/lavender for info).

### 5. Attendance Simulator UI (`lib/features/simulator/presentation/widgets/` & `SimulatorScreen`)
- [x] **Projection Card (`SimulatorProjectionCard`):**
  - Side-by-side comparison of **Actual Recorded Baseline** vs. **Projected Outcome**.
  - Impact badge displaying delta percentage points (`+X.X%` improvement or `-X.X%` decrease) and threshold status transitions (`Reaches Target!`, `Drops Below Target`).
  - Clear "Hypothetical Scenario — Not saved to database" visual indicator.
- [x] **Interactive Input Panel (`SimulatorInputPanel`):**
  - Subject and component selector with auto-selection for single-component subjects.
  - Quick action buttons: `+1 Present` (mint) and `+1 Absent` (coral).
  - Batch add buttons: `+3 Present`, `+5 Present`.
- [x] **Simulated Sessions List (`HypotheticalSessionList`):**
  - List of hypothetical sessions showing subject name and component badge.
  - Interactive status pill: single tap flips status between Present and Absent.
  - Delete button to remove individual hypothetical sessions.
  - Global `Reset Scenario` button to clear all simulated sessions.
  - Clean empty state when no hypothetical sessions exist, showing actual baseline without fake improvement.
- [x] **Standalone Route & Navigation (`SimulatorScreen`):**
  - Registered `/simulator` route in GoRouter (`RouteNames.simulatorPath`).
  - Connected "Open Simulator" action from Dashboard's Component Average card in `SafeAbsenceRecoveryCard`.

### 6. Simulator Isolation & Safety Verification
- [x] **Zero SQLite Writes:** Verified that adding, toggling, editing, removing, or resetting hypothetical sessions executes 0 SQLite database queries and creates 0 database rows.
- [x] **Dashboard Unchanged:** Verified that dashboard summaries and attendance totals remain 100% identical while hypothetical sessions are modeled.
- [x] **Reactive Baseline Refresh:** Verified that when actual attendance changes in Drift, the simulator baseline refreshes reactively without stale combinations.

---

## Architectural & File Changes in Phase 4

```text
lib/
├── app/
│   └── router/
│       ├── app_router.dart                                      # Registered /simulator route
│       └── route_names.dart                                     # Added simulator & simulatorPath
└── features/
    ├── attendance/
    │   └── domain/
    │       ├── entities/
    │       │   ├── component_attendance_summary.dart            # Added isAvailable / isNotAvailable getters
    │       │   ├── hypothetical_session.dart                    # In-memory ephemeral simulated session entity
    │       │   ├── insight_observation.dart                     # Factual observation model with category types
    │       │   ├── insights_filter.dart                         # Multi-dimensional filter model & session filtering
    │       │   ├── semester_attendance_summary.dart             # Added meetsThreshold, isBelowThreshold, formattedPercentage
    │       │   ├── simulator_projection.dart                    # Simulator projection model with deltas & transitions
    │       │   └── subject_attendance_summary.dart              # Added meetsThreshold, isBelowThreshold, formattedPercentage
    │       └── services/
    │           ├── insight_observation_generator.dart           # Pure Dart factual observation generator
    │           └── scenario_calculator.dart                     # Pure Dart simulator projection calculation engine
    ├── dashboard/
    │   └── presentation/widgets/
    │       └── safe_absence_recovery_card.dart                  # Added 'Open Simulator' action for Component Average
    ├── insights/
    │   └── presentation/
    │       ├── providers/
    │       │   └── insights_providers.dart                      # Filter notifier, filtered summary, observation providers
    │       └── widgets/
    │           ├── advanced_trend_card.dart                     # Chronological trend chart with date range
    │           ├── insight_observations_section.dart            # Factual observation cards section
    │           ├── insights_content.dart                        # Composed Insights tab content & empty filter state
    │           ├── insights_filter_bar.dart                     # Interactive date range, subject, component filter pills
    │           ├── insights_overview_card.dart                  # Overview hero with custom donut distribution chart
    │           ├── lecture_lab_comparison_card.dart             # Paired Lecture vs Lab comparison with variance badges
    │           └── subject_comparison_card.dart                 # Horizontal comparison bars with threshold line
    ├── shell/
    │   └── presentation/screens/
    │       └── insights_screen.dart                             # Replaced placeholder with segmented Insights/Simulator view
    └── simulator/
        └── presentation/
            ├── providers/
            │   └── simulator_providers.dart                     # In-memory simulator controller & projection provider
            ├── screens/
            │   └── simulator_screen.dart                        # Dedicated standalone Simulator screen & content
            └── widgets/
                ├── hypothetical_session_list.dart               # Simulated session list with toggle & reset
                ├── simulator_input_panel.dart                   # Subject/component picker & quick add buttons
                └── simulator_projection_card.dart               # Baseline vs. projected comparison card with deltas
```

---

## Test Verification Summary
- **Total Tests:** 147 passing tests across 20 test suites (35 new tests added in Phase 4).
- **Domain Calculation Tests:**
  - `scenario_calculator_test.dart` (9 tests): Raw Combined no sessions baseline, one Present projection, one Absent projection, mixed outcomes, threshold exactly met, single-component subjects, Component Average 50/50 averaging, provisional state handling, and single-component simulation.
  - `insight_observation_generator_test.dart` (4 tests): <3 sessions empty state, positive target & safe absence observation, below target & recovery observation, component imbalance (lecture vs lab variance $\ge 10\%$).
  - `insights_filter_test.dart` (6 tests): Default filter, subject filter, component filter, Last 7 Days, Last 30 Days, Custom date range.
- **Simulator Isolation Tests:**
  - `simulator_isolation_test.dart` (6 tests): Adding hypothetical session does not write to SQLite, toggling status does not modify actual records, removing session does not delete actual records, resetting does not modify database, dashboard values remain strictly unchanged, actual database session changes refresh baseline reactively.
- **Screen & Widget Tests:**
  - `insights_screen_test.dart` (5 tests): Empty state, populated insights with overview, subjects, comparisons and trend, segmented tab switching to Simulator, Last 7 Days filter and Reset, Component Average provisional state.
  - `simulator_screen_test.dart` (5 tests): Baseline attendance and empty state, +1 Present updates projection and list, toggling status flips Present/Absent, Reset Scenario clears all hypothetical entries, batch add (+3 Present).
  - `navigation_dock_test.dart` (1 test): Updated navigation verification for Insights and Simulator.
  - Pre-existing tests (111 tests): All database, dashboard, quick log, history, onboarding, and calculation tests continue passing.
- **Static Analysis & Formatting:**
  - `dart format .`: 123 files checked, 100% cleanly formatted.
  - `flutter analyze`: **0 issues found**.
  - `flutter test`: **147/147 tests passed**.

---

## Known Issues
- None. All Phase 4 requirements, mathematical parity, simulator isolation, advanced charts, filter interactions, and responsive layouts are fully verified and operating 100% offline.

---

## Next Steps (Phase 5 Readiness)
1. **Wait for user explicit approval** before initiating Phase 5.
2. In Phase 5 (Settings & Data Safety):
   - Build Settings screen (`SettingsScreen`) for semester threshold editing, calculation method configuration, and semester archiving.
   - Build local backup export service (`BackupService`) producing versioned portable JSON.
   - Build transactional backup restore service with schema and referential validation.
   - Test full backup export and restore round-trips against SQLite.

---

## Last Updated
2026-11-15
