# Changelog

All notable changes to the College Attendance Tracker are documented in this file.

This project uses a Keep a Changelog-style format. Entries describe user-visible behavior, important technical changes, and fixes. Dates use `YYYY-MM-DD`.

The project is currently in its pre-release development phase. Do not invent release history or claim features are complete until they have been implemented and verified.

## [Unreleased]

### Added
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
