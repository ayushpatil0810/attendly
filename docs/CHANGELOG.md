# Changelog

All notable changes to the College Attendance Tracker are documented in this file.

This project uses a Keep a Changelog-style format. Entries describe user-visible behavior, important technical changes, and fixes. Dates use `YYYY-MM-DD`.

The project is currently in its pre-release development phase. Do not invent release history or claim features are complete until they have been implemented and verified.

## [Unreleased]

### Added
- Phase 5: Settings, Local Backup & Data Safety implementation.
- Core Local Backup & Restore system (`lib/core/backup/`):
  - `BackupConstants`: Versioned format identifier (`college-attendance-tracker-backup`, version 1).
  - `BackupData`, `SemesterBackupModel`, `SubjectBackupModel`, `AttendanceSessionBackupModel`, and `BackupSummary` models with JSON serialization.
  - `BackupValidator`: Exhaustive multi-stage pure Dart validator validating JSON syntax, schema version, required fields, date formats (`YYYY-MM-DD`), enum constraints (`lecture`/`lab`, `present`/`absent`), subject-to-semester and session-to-subject referential integrity, component enablement on subjects, duplicate session keys `(subjectId, sessionDate, component)`, and safe file-size/record-count boundaries.
  - `BackupService`: Versioned JSON export and transactional restore with relational ID remapping (`oldId -> newId`) ensuring foreign-key integrity and complete transaction rollback on failure.
  - Strict simulator isolation: Ephemeral simulator sessions exist exclusively in-memory and are never included in exported backups or restored attendance.
  - Documented restore policy: Replace existing local data after explicit user confirmation in a dedicated preview summary dialog.
- Core Platform Services & Infrastructure (`lib/core/services/`):
  - `PlatformFileService` and `PlatformFileServiceImpl`: Abstraction for local JSON file picking and export sharing across mobile and desktop platforms using `file_picker` (13.3.3) and `share_plus` (13.3.1).
  - `AppPreferencesNotifier` and `appPreferencesProvider`: Persistent preference state management using `shared_preferences` with `AppHaptics` tactile feedback utility for attendance logging and button taps.
- Settings Presentation Suite (`lib/features/settings/`):
  - `SettingsScreen`: Clean four-section configuration screen with Plus Jakarta Sans typography, Hugeicons, and responsive spacing.
  - `SemesterSettingsSection`: Active semester display with immediate calculation method switcher (`Raw Combined` vs `50/50 Average`), attendance threshold slider with instant reactive recalculation across the app, and direct access to semester switcher and edit dialogs.
  - `AppPreferencesSection`: Haptic feedback toggle and system reduced motion accessibility explanation.
  - `BackupRestoreSection`: One-tap export and import flows with loading states, error dialogs, and success toasts.
  - `BackupSummaryDialog`: Pre-restore confirmation modal displaying export date, semester count, subject count, attendance session breakdown, and clear replacement consequence warning before destructive action.
  - `PrivacyOfflineSection`: Comprehensive offline-first transparency notice detailing 100% device-local SQLite storage, zero accounts/authentication, no cloud synchronization, student data ownership, and device data loss reminders.
- Navigation updates:
  - Registered `/settings` route in `GoRouter` (`RouteNames.settings` / `RouteNames.settingsPath`).
  - Connected Settings navigation cog in `DashboardHeader` to open Settings screen.
- Phase 4: Insights, Advanced Analytics & What-if Attendance Simulator.
- Domain calculation services and entities:
  - `HypotheticalSession`: In-memory model for hypothetical future classes.
  - `SimulatorProjection`: Comparative projection model tracking actual baseline vs projected counts, percentages, deltas, threshold status transitions, and subject/component breakdowns.
  - `InsightsFilter`: Multi-dimensional filtering model supporting `DateRangeType` (All Time, Last 7 Days, Last 30 Days, Custom Range), subject filtering, and component filtering.
  - `InsightObservation`: Factual observation model categorizing analytical observations into achievement, warning, and info.
  - `ScenarioCalculator`: Pure Dart simulation service combining real recorded sessions with hypothetical sessions, projecting outcomes using `AttendanceCalculator` with 100% calculation parity.
  - `InsightObservationGenerator`: Factual observation generator providing verifiable takeaways (component imbalances, below-threshold alerts, recent trends) while strictly avoiding speculative predictions and requiring >= 3 conducted sessions.
- Reactive Riverpod providers:
  - `insightsFilterProvider`, `filteredSemesterAttendanceSummaryProvider`, and `insightObservationsProvider` (`insights_providers.dart`).
  - `simulatorControllerProvider`, `simulatorProjectionProvider`, and `scenarioCalculatorProvider` (`simulator_providers.dart`).
- Insights presentation components:
  - `InsightsFilterBar`: Multi-dimensional filtering pills with custom date picker sheet and clear button.
  - `InsightsOverviewCard`: Contextual distribution donut chart, total conducted sessions, and threshold comparison.
  - `SubjectComparisonCard`: Horizontal comparison bars across subjects with target threshold indicator and honest unavailable states.
  - `LectureLabComparisonCard`: Side-by-side component breakdown showing Lecture vs Lab attendance, counts, and performance variances.
  - `AdvancedTrendCard`: Chronological cumulative attendance sparkline plotting only actual recorded class dates without artificial interpolation.
  - `InsightObservationsSection`: Transparent, factual analytical notes explaining trends and alerts.
- Attendance Simulator presentation components:
  - `SimulatorScreen` and `SimulatorContent`: Interactive what-if modeling workspace.
  - `SimulatorProjectionCard`: Side-by-side comparison of actual baseline vs projected attendance, delta badges, and threshold transitions.
  - `SimulatorInputPanel`: Subject & component picker, single-tap (+1 Present, +1 Absent), and quick batch increment buttons (+3, +5).
  - `HypotheticalSessionList`: Interactive list of hypothetical sessions with Present/Absent toggle, individual deletion, and full simulation reset.
  - Strict simulator isolation ensuring hypothetical sessions exist solely in memory, never writing to the Drift database or modifying actual attendance totals.
- Navigation enhancements:
  - Unified segmented control (`Insights` | `Simulator`) on the Insights tab.
  - Registered `/simulator` standalone route in `GoRouter` with direct access from dashboard cards.
- Phase 3: Dashboard & Attendance Calculations implementation.
- Pure Dart domain calculation services:
  - `AttendanceCalculator`: Authoritative engine for Raw Combined and Component Average (50/50) attendance percentages, provisional states, and threshold evaluations.
  - `SafeAbsenceCalculator`: Mathematical computation of maximum safe additional absences with boundary inequality verification.
  - `RecoveryCalculator`: Consecutive attended classes required to recover to target threshold under stated assumptions, with impossibility detection for 100% threshold.
- Domain summary and calculation entities:
  - `SemesterAttendanceSummary`, `SubjectAttendanceSummary`, `ComponentAttendanceSummary`, `SafeAbsenceResult`, `RecoveryResult`, `AttendanceTrendPoint`, `AttendanceAvailability`, and `ThresholdStatus`.
- Reactive Riverpod provider `semesterAttendanceSummaryProvider` recalculating automatically on database session, subject, threshold, or policy changes.
- Home Dashboard UI suite (`HomeScreen`):
  - `DashboardHeader`: Contextual greeting, active semester display, quick switcher sheet, and edit shortcut.
  - `OverallAttendanceHero`: Prominent tabular attendance figure, custom animated donut progress ring with threshold marker dot, status badge, and target percentage difference.
  - `CompactAttendanceStats`: Breathable counts for Conducted, Present, and Absent sessions, with Lecture and Lab breakdowns.
  - `SafeAbsenceRecoveryCard`: Contextual insight displaying safe absences, recovery requirements, or Component Average scenario requirements.
  - `DashboardSubjectPreview`: Concise preview of enrolled subjects with compact progress bars, attendance figures, and navigation to Subjects tab.
  - `DashboardTrendCard`: Chronological attendance sparkline based strictly on actual recorded session dates with clean empty state for insufficient history.
  - `DashboardEmptyState`: Welcoming empty dashboard for unrecorded semesters offering immediate quick logging without fake data.
- Phase 2: Attendance Management workflow implementation.
- `AttendanceSession`, `SessionComponent`, and `AttendanceStatus` domain entities and enums.
- `AttendanceRepository` and `AttendanceRepositoryImpl` supporting session creation, date querying, subject querying, month stream watching, safe updating, deletion, and duplicate session rejection.
- Reactive Riverpod state management in `attendance_providers.dart` (`selectedDateProvider`, `currentMonthProvider`, `sessionsForSelectedDateProvider`, `sessionsForMonthProvider`, and `AttendanceController` with comprehensive Undo support).
- Central Quick Attendance Log bottom sheet (`QuickLogSheet`):
  - Subject selection with auto-component selection for single-component subjects.
  - Component selector for subjects with both Lecture and Lab.
  - Single-tap immediate save on Present or Absent (no redundant save button).
  - Floating confirmation toast with one-tap Undo action.
  - Duplicate session detection and protection preventing accidental duplicate logging.
  - Date indicator defaulting to local calendar date with past-date selection.
- Full Attendance History screen (`HistoryScreen`):
  - Custom monthly attendance calendar (`AttendanceCalendar`) with animated month navigation, today jump, and date selection.
  - Honest calendar indicators: mint dot for Present, coral dot for Absent, mixed dots for both, and zero dots for unrecorded dates (never assuming absence).
  - Selected-date session list showing subject, component, status pill, and optional notes.
  - Historical session creation and safe session editing (`SessionFormSheet`).
  - Session deletion with confirmation dialog (`showDeleteSessionDialog`) and Undo toast.
- Database Schema Version 2 migration adding `UNIQUE (subject_id, session_date, component)` constraint and calendar indexes (`idx_attendance_sessions_unique` and `idx_attendance_sessions_date`).

### Changed
- Replaced Phase 1 Quick Log and History placeholders with fully functional Phase 2 implementations.
- Upgraded local database schema from version 1 to version 2 with automated, data-preserving migration.
- Reconciled all documentation files (`PRD.md`, `SPEC.md`, `TECH_STACK.md`, `ARCHITECTURE.md`, `DATABASE.md`, `DESIGN.md`, `TESTING.md`, `AGENTS.md`, `CHANGELOG.md`) to establish a 100% offline-only architecture using Drift/SQLite as the sole persistence source.
- Standardized local backup and restore requirements (versioned JSON export/import with validation and transactional rollback) across all documentation.

### Fixed
- Resolved RenderFlex overflow on narrow viewports (<360dp) across Dashboard widgets (`OverallAttendanceHero`, `CompactAttendanceStats`, `DashboardSubjectPreview`, and `DashboardTrendCard`) by replacing rigid `Row` layouts with responsive `Wrap`, `Flexible`, and `FittedBox` scaling patterns.

### Deprecated

### Removed
- Removed obsolete architecture decisions and documentation references to Supabase, Supabase Auth, PostgreSQL remote database, cloud synchronization queues, multi-device conflict resolution, and connectivity tracking from `PRD.md`, `SPEC.md`, `TECH_STACK.md`, `ARCHITECTURE.md`, and `TESTING.md`.

### Security

## Release notes guidelines

When making a change, update the `[Unreleased]` section under the appropriate heading.

Use these categories:
- **Added** — new user-facing features or capabilities.
- **Changed** — changes to existing behavior or design.
- **Fixed** — bug fixes.
- **Deprecated** — functionality that will be removed in a future release.
- **Removed** — removed functionality.
- **Security** — security and privacy-related changes.

When publishing a release:
1. Create a version heading using the project's chosen versioning scheme, for example `## [1.0.0] - YYYY-MM-DD`.
2. Move the relevant entries from `[Unreleased]` into that release section.
3. Leave a fresh `[Unreleased]` section at the top.
4. Ensure the release notes describe only changes that are actually implemented and validated.
5. Link release headings to repository tags only if the repository uses those tags.

## Contributor and AI-agent rules

- Keep entries concise and understandable to students and maintainers.
- Record meaningful behavior, schema, architecture, dependency, and design changes.
- Mention database migrations when a release changes the local database schema.
- Mention backup-format changes when export/import compatibility changes.
- Do not record routine formatting-only changes unless they are part of a significant maintenance release.
- Do not claim tests passed unless they were run.
- Do not include secrets, personal attendance records, or private device data.
- Keep the changelog consistent with `PRD.md`, `SPEC.md`, `DATABASE.md`, `DESIGN.md`, and `AGENTS.md`.
- The app is offline-only. Do not add changelog entries describing cloud sync, hosted authentication, or remote persistence unless the product direction is explicitly changed by the user.
