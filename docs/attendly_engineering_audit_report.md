# Attendly — Comprehensive Flutter Engineering & Architecture Audit

**Repository:** `https://github.com/ayushpatil0810/attendly`  
**Branch:** `main`  
**Audit Scope:** Complete read-only inspection of all Dart source files, Riverpod providers, Drift SQLite schema/migrations, backup/restore services, theme system, Android native widgets/manifests, and test suites.  
**Design & Product Constraint:** Preserve the exact current visual aesthetic, layout proportions, and feature set added on the go—including **Phosphor Icons (`phosphoricons_flutter`)** as the chosen icon library, Personal Attendance Goals, Milestones, Day Notes, 8 Pastel Palettes, Light/Dark/System modes, QR Semester Sharing, Daily Reminders, and Adaptive Android Home Screen Widgets.

---

## 1. Executive Summary

Attendly is a feature-rich, offline-first college attendance tracker built on a clean domain-driven foundation. Its mathematical attendance engine (`AttendanceCalculator`, `SafeAbsenceCalculator`, `RecoveryCalculator`, `ScenarioCalculator`, `InsightObservationGenerator`), strict separation between real SQLite records and ephemeral simulator projections, and atomic transaction design in `BackupService` are well-engineered.

However, a line-by-line inspection of the `main` branch source code revealed **three primary systemic issues** that currently break compilation, cause inconsistent theme switching (including unexpected black/dark backgrounds and unreadable text), and risk silent data loss during backup/restore:

1. **Incomplete Multi-Palette Theme & Phosphor Icon Wiring (Root Cause of Theme Glitches & Compilation Errors):**
   * The 8-palette theme system (`AppThemeId`, `AppPalettes`, `AppThemeColors`, `theme_provider.dart`, `appearance_section.dart`) and the transition to **Phosphor Icons (`phosphoricons_flutter`)** were partially introduced while `pubspec.yaml`, `app_icons.dart`, `app_theme.dart`, and `app.dart` still had legacy `hugeicons` and static light-only token wiring (`AppColors`, `AppTypography`).
   * `theme_provider.dart` calls `AppTheme.buildTheme(themeId, Brightness)` and `HomeWidgetService.updateThemeColors(...)`, **neither of which exists** in `app_theme.dart` or `home_widget_service.dart`.
   * `appearance_section.dart` uses `package:phosphoricons_flutter/phosphoricons_flutter.dart` and references `AppIcons.sun` and `AppIcons.palette`, while `pubspec.yaml` and `lib/core/theme/app_icons.dart` were not yet updated from `hugeicons` to `phosphoricons_flutter`, and `SettingsScreen` never mounts `AppearanceSection`.
   * `AttendlyApp` (`lib/app/app.dart`) hardcodes `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, and `themeMode: ThemeMode.system` without watching `themePreferencesProvider`.
   * Nearly all screens, cards, bottom sheets, dialogs, and `AppTypography` styles hardcode light-mode constants (`AppColors.warmWhite`, `AppColors.pureWhite`, `AppColors.ink`), while Material components (`AlertDialog`, `Theme.of(context)`) react to OS Dark Mode—producing the exact black/dark background clashes and stale colors observed.
2. **Schema Drift in Backup & Restore (Silent Data Loss):**
   * While the Drift SQLite database is at `schemaVersion = 5` (adding the `day_notes` table in v4 and `semesters.target_goal` in v5), `BackupData`, `BackupService`, and `BackupValidator` only export and restore schema v3 fields. Exporting and restoring a backup **silently deletes all `day_notes` and resets every semester's `targetGoal` back to `0.85`**, and also omits theme preferences (`pref_theme_mode_v1`, `pref_color_theme_id_v1`).
3. **Database Query, Widget Sync, and Rebuild Inefficiencies:**
   * Missing composite SQLite indexes on `attendance_sessions(subject_id, session_date)` and `subjects(semester_id, sort_order)`.
   * `AttendanceWidgetViews.kt` references view IDs that do not match `widget_attendance_medium.xml` and `widget_attendance_large.xml`, and `HomeWidgetService` forgets to save `subject_${num}_pct_int`.
   * `AppIcon` wraps every icon in an offscreen `ColorFiltered` (`saveLayer`) render pass (originally a workaround for `HugeIcon`) with a hardcoded `AppColors.ink` default. Switching `AppIcons` and `AppIcon` to standard `IconData` from `phosphoricons_flutter` eliminates `ColorFiltered` completely!

---

## 2. Current Architecture Assessment

### Layer Separation (Presentation / Domain / Data)
* **Strengths:**
  * Domain entities (`Semester`, `Subject`, `AttendanceSession`, `DayNote`, `HypotheticalSession`, `SemesterAttendanceSummary`, `SubjectAttendanceSummary`) are immutable value objects with proper equality/hashCode implementations.
  * Domain services (`AttendanceCalculator`, `SafeAbsenceCalculator`, `RecoveryCalculator`, `ScenarioCalculator`, `InsightObservationGenerator`) are 100% pure Dart with zero database or Flutter UI coupling.
  * Simulator isolation is strictly enforced: `SimulatorController` stores `HypotheticalSession` items purely in Riverpod memory, and `ScenarioCalculator` assigns negative ephemeral IDs (`-(i + 1)`) without ever writing to Drift or `HomeWidgetService`.
* **Architectural Weaknesses:**
  * **Inverted Core/Domain Dependency on Presentation:** `sharedPreferencesProvider` is declared inside `lib/features/onboarding/presentation/providers/onboarding_provider.dart` and imported upward by `lib/core/theme/theme_provider.dart`, `lib/core/services/preferences_service.dart`, `lib/core/services/notification_preferences_service.dart`, `lib/features/attendance/domain/services/milestone_service.dart`, and `lib/features/semesters/presentation/providers/semesters_provider.dart`. Core and domain layers should never import from a feature's `presentation/` layer.
  * **Broken Contracts Between Theme & Service Layers:** `theme_provider.dart` invokes methods on `AppTheme` (`buildTheme`) and `HomeWidgetService` (`updateThemeColors`) that were not yet added to those classes.

### Riverpod State Management
* Uses Riverpod 3 (`Notifier`, `AsyncNotifier`, `StreamProvider`, `Provider`) idioms appropriately.
* **Reload Flicker Issue:** `semesterAttendanceSummaryProvider`, `currentMonthAttendanceSummaryProvider`, `filteredSemesterAttendanceSummaryProvider`, and `simulatorProjectionProvider` immediately return `const AsyncLoading()` whenever `subjectsAsync.isLoading || sessionsAsync.isLoading` is true, even if `.value` already holds valid data from a previous emission. Preserving existing values during background stream refreshes prevents UI loading flashes.

### Navigation & Routing
* `appRouterProvider` (`lib/app/router/app_router.dart`) uses `GoRouter` cleanly for `/`, `/onboarding`, `/semester-setup`, `/home`, `/simulator`, and `/settings`.
* `ScanSemesterQrScreen` is pushed imperatively via `Navigator.of(context).push(MaterialPageRoute(...))` (`openScanSemesterQrScreen`), which works well for a modal camera scanner returning a `bool?` result.

---

## 3. Project Structure Assessment

* **Directory Layout:** Clean feature-first modular layout (`lib/app`, `lib/core`, `lib/features/{attendance,dashboard,insights,onboarding,semesters,settings,shell,simulator,subjects}`).
* **Redundant / Obsolete / Disconnected Files Identified:**
  1. `lib/features/shell/presentation/screens/history_screen.dart` (88 bytes) — Single-line `export` wrapper around `lib/features/attendance/presentation/screens/history_screen.dart`. `main_shell_screen.dart` can import `HistoryScreen` directly.
  2. `lib/features/subjects/presentation/widgets/subject_detail_sheet.dart` (20.5 KB) — Unused bottom sheet widget replaced by the inline expandable `_SubjectCard` in `subjects_screen.dart`.
  3. `android/app/src/main/kotlin/com/attendly/attendly/AttendanceWidgetViews.kt` (13.1 KB) — Contains a centralized `buildAdaptiveViews`, `buildSmallViews`, `buildMediumViews`, and `buildLargeViews` implementation, while `SmallAttendanceWidgetProvider.kt`, `MediumAttendanceWidgetProvider.kt`, and `LargeAttendanceWidgetProvider.kt` duplicate manual `RemoteViews` building instead of delegating to `AttendanceWidgetViews` (and have mismatched layout IDs vs `widget_attendance_medium.xml` / `widget_attendance_large.xml`).
  4. `DuplicateSessionFailure` in `lib/core/errors/app_failure.dart:24` and `on DuplicateSessionFailure` in `lib/features/attendance/presentation/widgets/session_form_sheet.dart:170` — Dead exception class left over from pre-v3 schema (before multiple same-day sessions per component were allowed).

---

## 4. Complete Findings Catalog (Classified by Severity)

### Critical Severity (Compilation Breaks, Data Loss, Crashes, Broken Core Features)

#### [CRITICAL-01] Incomplete Migration to `phosphoricons_flutter` & Missing Theme Methods Break Compilation
* **Relevant Files & Locations:**
  * `pubspec.yaml:29-46`
  * `lib/core/theme/app_icons.dart:1-79`
  * `lib/features/settings/presentation/widgets/appearance_section.dart:3, 50, 74, 79, 84, 113, 192`
  * `lib/core/theme/theme_provider.dart:49-54, 81-86, 95-96`
  * `lib/core/theme/app_theme.dart:1-257`
  * `lib/core/services/home_widget_service.dart:36-175`
* **What is wrong (Verified Problem):**
  1. `appearance_section.dart` uses `package:phosphoricons_flutter/phosphoricons_flutter.dart` (`PhosphorIconsRegular`, `PhosphorIconsFill`) and references `AppIcons.sun` (line 50) and `AppIcons.palette` (line 113), while `pubspec.yaml` and `lib/core/theme/app_icons.dart` still reference `hugeicons: ^4.4.0` and lack `sun` and `palette`.
  2. `theme_provider.dart` (lines 95–96) calls `AppTheme.buildTheme(themeId, Brightness.light)` and `AppTheme.buildTheme(themeId, Brightness.dark)`, but `AppTheme` (`lib/core/theme/app_theme.dart`) only defines `static ThemeData get lightTheme` and `static ThemeData get darkTheme`—`buildTheme` does not exist.
  3. `theme_provider.dart` (lines 49–54 and 81–86) calls `ref.read(homeWidgetServiceProvider).updateThemeColors(...)`, which does not exist on `HomeWidgetService`.
* **Why it matters:** Running `flutter analyze` or `flutter test` across the project fails to compile until `phosphoricons_flutter` is wired in `pubspec.yaml` and `app_icons.dart`, and `buildTheme` / `updateThemeColors` are implemented.
* **Recommended solution:**
  1. Replace `hugeicons` with `phosphoricons_flutter` in `pubspec.yaml` and migrate all icon constants in `AppIcons` (`lib/core/theme/app_icons.dart`)—including `sun`, `moon`, `palette`, `deviceMobile`, and `checkCircle`—to `PhosphorIconsRegular` / `PhosphorIconsFill` (`IconData`), rendering them cleanly via standard `Icon(icon, size: size, color: effectiveColor)` inside `AppIcon`.
  2. Implement `AppTheme.buildTheme(AppThemeId themeId, Brightness brightness)` in `lib/core/theme/app_theme.dart` using `themeId.colorsFor(brightness)` and registering `extensions: <ThemeExtension<dynamic>>[colors]`.
  3. Implement `updateThemeColors(...)` on `HomeWidgetService` (`lib/core/services/home_widget_service.dart`).
* **Expected benefit:** Completes your intended Phosphor Icons migration, restores clean compilation across all files and tests, removes the `hugeicons` dependency, and completes the 8-palette theme contract.
* **Breaking change / Migration:** None.

---

#### [CRITICAL-02] Root `AttendlyApp`, `SettingsScreen`, and UI Widgets Are Disconnected from the 8-Palette / Dark Mode Theme System
* **Relevant Files & Locations:**
  * `lib/app/app.dart:11-23`
  * `lib/features/settings/presentation/screens/settings_screen.dart:74-127`
  * `lib/core/theme/app_colors.dart:1-46`
  * `lib/core/theme/app_typography.dart:1-125`
  * All screen, dialog, bottom sheet, and shared widget files in `lib/core/shared/widgets/` and `lib/features/`
* **What is wrong (Verified Problem):**
  1. `AttendlyApp` (`lib/app/app.dart:14-21`) hardcodes:
     ```dart
     return MaterialApp.router(
       title: 'attendly',
       debugShowCheckedModeBanner: false,
       theme: AppTheme.lightTheme,
       darkTheme: AppTheme.darkTheme,
       themeMode: ThemeMode.system,
       routerConfig: router,
     );
     ```
     It never watches `themePreferencesProvider`.
  2. `SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`) never imports or renders `AppearanceSection`.
  3. Even when `MaterialApp.router` switches to `darkTheme` under `ThemeMode.system`, 95% of the app's widgets bypass `Theme.of(context)` and `AppThemeColors`, directly referencing `const` light-mode hex values in `AppColors` (`AppColors.warmWhite`, `AppColors.pureWhite`, `AppColors.ink`, `AppColors.divider`) and `AppTypography` (where every `TextStyle` hardcodes `color: AppColors.ink` `#30263F`).
* **Why it matters:** This is the exact root cause of the theme bugs you reported:
  * Some components (like Material `AlertDialog` in `SemesterSwitcherSheet` or `Theme.of(context)` surfaces) turn dark/black when the OS is in Dark Mode, while screens and cards stay bright white—or dark surfaces render near-black `#30263F` text from `AppTypography`, making text unreadable.
  * Selecting any of the 8 color palettes or Light/Dark modes has no effect on hardcoded `AppColors` widgets.
* **Recommended solution:** Detailed in **Section 5 (Centralized Theme System Solution)**.
* **Expected benefit:** Every screen, modal, dialog, bottom sheet, calendar, chart, and button updates instantaneously and consistently across all 8 palettes and Light/Dark/System modes without altering the app's visual look.
* **Breaking change / Migration:** None.

---

#### [CRITICAL-03] Backup Export & Restore Silently Drops `day_notes`, `semesters.targetGoal`, and Theme Preferences (Data Loss)
* **Relevant Files & Locations:**
  * `lib/core/backup/backup_format.dart:11-57, 152-182`
  * `lib/core/backup/backup_service.dart:14-97, 108-200`
  * `lib/core/backup/backup_validator.dart:130-427`
  * `lib/features/settings/presentation/providers/settings_providers.dart:44-50, 91-115`
* **What is wrong (Verified Problem):**
  1. Database schema v4 added the `day_notes` table (`DayNotes`), and schema v5 added `target_goal` (`targetGoal`, default `0.85`) to `Semesters`.
  2. `SemesterBackupModel` (`backup_format.dart:11-57`) does not include `targetGoal`.
  3. `BackupData` (`backup_format.dart:152-182`) has no `dayNotes` collection.
  4. `BackupService.restoreBackup` (`backup_service.dart:108-200`) deletes all existing tables (which cascades and wipes `day_notes`), then re-inserts semesters without `targetGoal` (resetting every semester's personal goal to `0.85`) and never restores `day_notes`.
  5. `BackupController.exportBackup` (`settings_providers.dart:46-50`) only exports `'hapticFeedbackEnabled'` in `appPreferences`, omitting `pref_theme_mode_v1`, `pref_color_theme_id_v1`, and daily reminder settings, and `executeRestore` forgets to invalidate `dayNotesForMonthProvider` / `dayNoteForDateFamilyProvider`.
* **Why it matters:** Restoring a backup causes permanent data loss of all student day notes and custom personal attendance goals.
* **Recommended solution:**
  * Add `targetGoal` (defaulting to `0.85` when missing in older v1 backups) to `SemesterBackupModel` and validate `targetGoal > 0.0 && targetGoal <= 1.0` in `BackupValidator`.
  * Add `DayNoteBackupModel` (`id`, `semesterId`, `date`, `content`, `createdAt`, `updatedAt`) and `final List<DayNoteBackupModel> dayNotes` (defaulting to `const []` when absent in older v1 backups) to `BackupData`.
  * Export, validate, and restore `dayNotes` (remapping `semesterId` via `oldToNewSemesterId`) inside `BackupService.restoreBackup`'s transaction.
  * Include theme preferences in `appPreferences` during export/restore and invalidate day note providers on restore.
* **Expected benefit:** 100% lossless backup and restore across all schema v5 tables and preferences while maintaining full backward compatibility with existing v1 backup JSON files.
* **Breaking change / Migration:** Backward-compatible with v1 backups (missing `targetGoal` defaults to `0.85`; missing `dayNotes` defaults to `[]`).

---

#### [CRITICAL-04] `getSessionBySubjectDateComponent` Crashes with `StateError` When Multiple Sessions Exist on Same Day
* **Relevant Files & Locations:**
  * `lib/features/attendance/data/repositories/attendance_repository_impl.dart:192-207`
* **What is wrong (Verified Problem):**
  ```dart
  @override
  Future<AttendanceSession?> getSessionBySubjectDateComponent(
    int subjectId,
    String sessionDate,
    SessionComponent component,
  ) async {
    final row =
        await (_db.select(_db.attendanceSessions)..where(
              (tbl) =>
                  tbl.subjectId.equals(subjectId) &
                  tbl.sessionDate.equals(sessionDate) &
                  tbl.component.equals(component.dbValue),
            ))
            .getSingleOrNull();
    return row != null ? _toEntity(row) : null;
  }
  ```
  Since schema v3 allows logging multiple sessions for the same subject, date, and component (e.g., two lectures of the same subject on the same day), Drift's `.getSingleOrNull()` throws an unhandled `StateError('Too many elements')` whenever 2+ matching rows exist.
* **Why it matters:** Calling `getSessionBySubjectDateComponent` on a day with two lectures for the same subject crashes the operation.
* **Recommended solution:** Add `..orderBy([(tbl) => OrderingTerm(expression: tbl.id, mode: OrderingMode.desc)])..limit(1)` before `.getSingleOrNull()`.
* **Expected benefit:** Prevents a `StateError` crash when multiple same-day sessions exist.
* **Breaking change / Migration:** None.

---

### High Severity (Data Integrity, Broken UI Workflows, Native Widget Bugs, Database Indexing)

#### [HIGH-01] `GoalMilestonesCard` Is Built & Tested But Never Rendered on `HomeScreen`
* **Relevant Files & Locations:**
  * `lib/features/dashboard/presentation/widgets/goal_milestones_card.dart:1-740`
  * `lib/features/shell/presentation/screens/home_screen.dart:118-174`
* **What is wrong (Verified Problem):**
  * `GoalMilestonesCard` is a complete feature widget (displaying the student's Personal Attendance Goal progress bar, goal recovery advice, and 75%–100% unlockable Milestone badges with detail sheets), and `QuickLogSheet` even triggers `MilestoneCelebrationDialog` when a milestone is reached (`quick_log_sheet.dart:123-147`).
  * However, `HomeScreen` (`lib/features/shell/presentation/screens/home_screen.dart`) never imports or renders `GoalMilestonesCard`.
* **Why it matters:** The Personal Goal progress & Milestones card is currently unreachable from the Dashboard UI unless mounted.
* **Recommended solution:** Make `GoalMilestonesCard` fully theme-aware (and mount it on `HomeScreen` if desired, or keep `HomeScreen`'s current layout if you intentionally hid it).
* **Expected benefit:** Preserves your exact dashboard intent while keeping `GoalMilestonesCard` and its tests 100% theme-compatible.
* **Breaking change / Migration:** None.

---

#### [HIGH-02] Android Home Screen Widget Layout Mismatch & Missing `subject_${num}_pct_int` Data
* **Relevant Files & Locations:**
  * `lib/core/services/home_widget_service.dart:144-162`
  * `android/app/src/main/kotlin/com/attendly/attendly/AttendanceWidgetViews.kt:89-280`
  * `android/app/src/main/kotlin/com/attendly/attendly/MediumAttendanceWidgetProvider.kt:13-81`
  * `android/app/src/main/kotlin/com/attendly/attendly/LargeAttendanceWidgetProvider.kt:14-149`
  * `android/app/src/main/res/layout/widget_attendance_medium.xml`
  * `android/app/src/main/res/layout/widget_attendance_large.xml`
* **What is wrong (Verified Problem):**
  1. `AttendanceWidgetViews.kt` references view IDs that **do not exist** in `widget_attendance_medium.xml` and `widget_attendance_large.xml` (such as `R.id.widget_medium_progress_ring`, `R.id.widget_medium_empty_subjects`, `R.id.widget_m_s1_row`, `R.id.widget_m_s1_bar`, `R.id.widget_large_progress_ring`, `R.id.widget_s1_bar`).
  2. Because `AttendanceWidgetViews.kt` references non-existent `R.id.*` resources, **the Android Kotlin build (`assembleDebug` / `assembleRelease`) will fail with `Unresolved reference` errors in `AttendanceWidgetViews.kt`**!
  3. Meanwhile, `SmallAttendanceWidgetProvider.kt`, `MediumAttendanceWidgetProvider.kt`, and `LargeAttendanceWidgetProvider.kt` match the XML layouts (`widget_attendance_small.xml`, `widget_attendance_medium.xml`, `widget_attendance_large.xml`), and `HomeWidgetService` does not save `subject_${num}_pct_int`.
* **Why it matters:** `AttendanceWidgetViews.kt` breaks Android Gradle compilation because its `R.id.*` references don't match the XML layouts in `res/layout/`.
* **Recommended solution:** Align `AttendanceWidgetViews.kt` and the three `*AttendanceWidgetProvider.kt` classes with the actual XML layouts in `res/layout/widget_attendance_{small,medium,large}.xml`, save `subject_${num}_pct_int` in `HomeWidgetService`, and apply dynamic theme colors (`updateThemeColors`) to the widget views.
* **Expected benefit:** Fixes Android Gradle compilation and enables theme-synchronized home screen widgets.
* **Breaking change / Migration:** None.

---

#### [HIGH-03] `Semester.copyWith` Cannot Clear `startDate` or `endDate`
* **Relevant Files & Locations:**
  * `lib/features/semesters/domain/entities/semester.dart:33-57`
  * `lib/features/semesters/presentation/widgets/semester_form_sheet.dart:78, 114-121, 353, 405`
* **What is wrong (Verified Problem):**
  * `SemesterFormSheet` provides clear (`X`) buttons that set `_startDate = null` or `_endDate = null` (lines 353, 405), and also clears `_endDate = null` if a new start date is after the existing end date (line 78).
  * When saving, `_save()` calls `widget.initialSemester!.copyWith(startDate: _startDate, endDate: _endDate, ...)`.
  * Because `Semester.copyWith` uses `startDate: startDate ?? this.startDate` and `endDate: endDate ?? this.endDate`, passing `null` silently retains the old date!
* **Why it matters:** Users can never clear a semester's start or end date once set.
* **Recommended solution:** Add `bool clearStartDate = false` and `bool clearEndDate = false` parameters to `Semester.copyWith` and pass them from `SemesterFormSheet._save()`.
* **Expected benefit:** Clearing semester dates works reliably and persists to SQLite.
* **Breaking change / Migration:** Non-breaking optional parameters on `copyWith`.

---

#### [HIGH-04] `AttendanceRepositoryImpl.updateSession` Fails to Validate Component Enabled on Subject
* **Relevant Files & Locations:**
  * `lib/features/attendance/data/repositories/attendance_repository_impl.dart:262-302`
* **What is wrong (Verified Problem):**
  * `createSession` validates that `lectureEnabled` / `labEnabled` is true for the session's `component` (lines 229–234).
  * `updateSession` fetches `subjectRow` (lines 270–276) but omits the `lectureEnabled` / `labEnabled` check.
* **Why it matters:** Updating a session to a disabled component succeeds in SQLite, but later causes `BackupValidator.validate` (`backup_validator.dart:382-393`) to reject any backup exported from the app!
* **Recommended solution:** Add the `lectureEnabled` / `labEnabled` validation check to `updateSession`.
* **Expected benefit:** Prevents invalid session records and guarantees all exported backups pass restore validation.
* **Breaking change / Migration:** None.

---

#### [HIGH-05] Permissive `DateTime.tryParse` Rollover in `AttendanceRepositoryImpl._validateSessionDate`
* **Relevant Files & Locations:**
  * `lib/features/attendance/data/repositories/attendance_repository_impl.dart:31-48`
* **What is wrong (Verified Problem):**
  * `_validateSessionDate` uses `DateTime.tryParse(sessionDate)`. In Dart, `DateTime.tryParse('2026-02-31')` does not return `null`—it silently rolls over to `2026-03-03`.
  * By contrast, `BackupValidator._isValidIsoDate` (`backup_validator.dart:430-446`) strictly checks `dt.year == year && dt.month == month && dt.day == day`.
* **Why it matters:** An invalid calendar date string accepted by `AttendanceRepositoryImpl` will corrupt the database and cause future backup restores to fail validation.
* **Recommended solution:** Use strict calendar validation (`dt.year == year && dt.month == month && dt.day == day`) in `_validateSessionDate`.
* **Expected benefit:** 100% parity between repository date validation and backup date validation.
* **Breaking change / Migration:** None.

---

#### [HIGH-06] Missing Composite SQLite Indexes on Foreign Keys & Date Columns
* **Relevant Files & Locations:**
  * `lib/core/database/app_database.dart:22-94`
* **What is wrong (Verified Problem):**
  * Only `idx_attendance_sessions_date` (`session_date`) and `idx_day_notes_date` (`date`) are indexed.
  * Foreign key columns `attendance_sessions.subject_id` and `subjects.semester_id` have no indexes.
* **Why it matters:** Every joined query (`watchSessionsForSemester`, `watchSessionsForDate`, `watchSessionsForMonth`, `getSessionsForSubject`) and every `ON DELETE CASCADE` operation must scan `attendance_sessions` and `subjects`.
* **Recommended solution:** Add composite indexes in `onCreate` and `beforeOpen`:
  * `CREATE INDEX IF NOT EXISTS idx_attendance_sessions_subject_date ON attendance_sessions(subject_id, session_date);`
  * `CREATE INDEX IF NOT EXISTS idx_subjects_semester_sort ON subjects(semester_id, sort_order);`
* **Expected benefit:** $O(\log N)$ indexed lookups for all session and subject queries without breaking existing `schemaVersion == 5` assertions.
* **Breaking change / Migration:** None.

---

### Medium Severity (Performance, State Management, Reliability)

#### [MEDIUM-01] `AppIcon` Allocates an Offscreen `ColorFiltered` Layer for Every Icon
* **Relevant Files & Locations:**
  * `lib/core/theme/app_icons.dart:56-79`
* **What is wrong (Verified Problem):**
  ```dart
  final iconWidget = ColorFiltered(
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    child: HugeIcon(icon: icon, color: Colors.black, size: size),
  );
  ```
  Furthermore, `this.color = AppColors.ink` is a non-nullable default hardcoded to light-mode dark purple-black (`0xFF30263F`).
* **Why it matters:**
  1. `ColorFiltered` forces Flutter's engine to allocate an offscreen `ColorFilterLayer` (`saveLayer`) for every single icon on screen (20–35 icons per screen), adding unnecessary rasterization overhead during scrolling and bottom sheet animations.
  2. Any `AppIcon(AppIcons.calendar)` that omits `color:` defaults to `#30263F` even in Dark Mode, making icons invisible on dark surfaces.
* **Recommended solution:** With `AppIcons` migrated to `phosphoricons_flutter` (`IconData`), render a standard `Icon(icon, size: size, color: effectiveColor, semanticLabel: semanticLabel)` inside `AppIcon` without `ColorFiltered`, and make `color` nullable (`final Color? color;`), defaulting to `color ?? IconTheme.of(context).color ?? context.colors.textPrimary`.
* **Expected benefit:** Eliminates 20–35 offscreen `saveLayer` allocations per frame, uses native Flutter glyph rendering for Phosphor Icons, and automatically adapts default icon colors to Dark Mode and all 8 palettes.
* **Breaking change / Migration:** None (`const AppIcon(...)` constructor signature remains 100% compatible).

---

#### [MEDIUM-02] $O(S \times N)$ Redundant Session Filtering in `AttendanceCalculator.calculateSemester`
* **Relevant Files & Locations:**
  * `lib/features/attendance/domain/services/attendance_calculator.dart:54-65, 200-213`
* **What is wrong (Verified Problem):**
  * `calculateSemester` loops over $S$ subjects and passes the entire `sessions` list ($N$ sessions) into `calculateSubject`, which filters `sessions.where((s) => s.subjectId == subject.id).toList()` on every call.
* **Why it matters:** Performs $S + 2$ full passes over `sessions` on every stream emission and twice on every Simulator tap.
* **Recommended solution:** Group `sessions` by `subjectId` in a single $O(N)$ pass inside `calculateSemester` and pass each subject's pre-filtered session list to `calculateSubject`.
* **Expected benefit:** Reduces CPU work in Dashboard, Insights, and Simulator calculations.
* **Breaking change / Migration:** None.

---

#### [MEDIUM-03] Stream Reload Flicker & Duplicated Logic in Summary Providers
* **Relevant Files & Locations:**
  * `lib/features/attendance/presentation/providers/attendance_providers.dart:242-330`
  * `lib/features/insights/presentation/providers/insights_providers.dart:54-101`
  * `lib/features/simulator/presentation/providers/simulator_providers.dart:111-152`
* **What is wrong (Verified Problem):**
  * All four summary providers check `if (subjectsAsync.isLoading || sessionsAsync.isLoading) return const AsyncLoading();` without checking if `.hasValue` is already true, and duplicate ~40 lines of identical `AsyncValue` unwrapping code.
* **Why it matters:** Causes brief loading spinner flashes when invalidating providers or switching scopes, and duplicates boilerplate across 4 providers.
* **Recommended solution:** Use `.hasValue` so previous data is retained during background refreshes if available, and deduplicate the summary calculation helper.
* **Expected benefit:** Eliminates UI flicker and reduces provider boilerplate.
* **Breaking change / Migration:** None.

---

#### [MEDIUM-04] Non-Atomic Read-Then-Write in `DayNoteRepositoryImpl.setNoteForDate`
* **Relevant Files & Locations:**
  * `lib/features/attendance/data/repositories/day_note_repository_impl.dart:76-116`
* **What is wrong (Verified Problem):**
  * `setNoteForDate` performs a `SELECT` (`getNoteForDate`) followed by an `UPDATE` or `INSERT` outside a transaction.
* **Why it matters:** Two rapid taps can race on the `UNIQUE(semester_id, date)` constraint, and every note edit performs two database queries instead of one.
* **Recommended solution:** Wrap in `_db.transaction(...)` or use Drift's `insert(..., onConflict: DoUpdate(...))` targeting `(tbl.semesterId, tbl.date)`.
* **Expected benefit:** Atomic, single-round-trip day note saving.
* **Breaking change / Migration:** None.

---

#### [MEDIUM-05] Sequential Loop Inserts in `BackupService.restoreBackup`
* **Relevant Files & Locations:**
  * `lib/core/backup/backup_service.dart:169-195`
* **What is wrong (Verified Problem):**
  * `restoreBackup` awaits `_db.into(_db.attendanceSessions).insert(...)` one row at a time inside a `for` loop.
* **Why it matters:** Restoring 2,000+ attendance sessions across multiple semesters performs 2,000+ sequential round-trips to the background SQLite isolate.
* **Recommended solution:** Validate all session foreign keys first, then insert all sessions and day notes using `_db.batch((b) => b.insertAll(...))` inside the transaction.
* **Expected benefit:** Up to 10x faster backup restoration while preserving full atomic rollback safety.
* **Breaking change / Migration:** None.

---

#### [MEDIUM-06] Hardcoded Dark Status & Navigation Bar Icons in `lib/main.dart`
* **Relevant Files & Locations:**
  * `lib/main.dart:13-20`
* **What is wrong (Verified Problem):**
  * `main()` sets `statusBarIconBrightness: Brightness.dark` and `systemNavigationBarIconBrightness: Brightness.dark` once at startup and never updates it when the theme switches to Dark Mode.
* **Why it matters:** In Dark Mode, dark status bar and navigation bar icons are nearly invisible against the dark background.
* **Recommended solution:** Update `AttendlyApp` (`lib/app/app.dart`) to wrap the app in an `AnnotatedRegion<SystemUiOverlayStyle>` (or update `SystemChrome.setSystemUIOverlayStyle`) that dynamically matches the active theme's `isDark` state and background/surface colors.
* **Expected benefit:** Crisp, legible system status bar and navigation bar icons in both Light and Dark modes across all 8 palettes.
* **Breaking change / Migration:** None.

---

### Low Severity (Code Cleanup, Duplication, Layer Hygiene)

#### [LOW-01] `sharedPreferencesProvider` Placed in `features/onboarding/presentation/`
* **Relevant Files & Locations:**
  * `lib/features/onboarding/presentation/providers/onboarding_provider.dart:6-8`
* **What is wrong:** Core services and domain services import `onboarding_provider.dart` just to access `sharedPreferencesProvider`.
* **Recommended solution:** Define `sharedPreferencesProvider` in `lib/core/providers/shared_preferences_provider.dart` and re-export it from `onboarding_provider.dart` so zero existing imports break.

#### [LOW-02] Duplicated `_MiniRingPainter` Between Dashboard and Subjects Screen
* **Relevant Files & Locations:**
  * `lib/features/dashboard/presentation/widgets/dashboard_subject_preview.dart:418-475`
  * `lib/features/subjects/presentation/screens/subjects_screen.dart:669-726`
* **What is wrong:** Exact 58-line duplicate `CustomPainter` class.
* **Recommended solution:** Reuse or extract into `lib/core/shared/widgets/app_progress.dart`.

#### [LOW-03] Redundant Re-Export Stub & Unused `DuplicateSessionFailure`
* **Relevant Files & Locations:**
  * `lib/features/shell/presentation/screens/history_screen.dart`
  * `lib/core/errors/app_failure.dart:24`, `lib/features/attendance/presentation/widgets/session_form_sheet.dart:170`
* **What is wrong:** Unused legacy artifacts.
* **Recommended solution:** Clean up unused catch block and redundant stub.

---

## 5. Deep-Dive: Centralized Theme & Phosphor Icon Solution (Preserving Current Visual Design)

To fix all theme switching bugs and complete the Phosphor Icons transition **without changing the look and feel of the app**:

1. **Migrate `pubspec.yaml` and `AppIcons` (`lib/core/theme/app_icons.dart`) to `phosphoricons_flutter`:**
   * Replace `hugeicons` with `phosphoricons_flutter` in `pubspec.yaml`.
   * Map every icon constant in `AppIcons` (`home`, `subjects`, `quickLog`, `history`, `insights`, `add`, `edit`, `delete`, `check`, `close`, `back`, `forward`, `arrowDown`, `settings`, `undo`, `archive`, `more`, `lecture`, `lab`, `calendar`, `info`, `alert`, `exportFile`, `importFile`, `shield`, `file`, `device`, `database`, `note`, `qrCode`, `scan`, `flash`, `flashOff`, `notification`, `clock`, `target`, `trophy`, `award`, `flag`, plus `sun`, `moon`, `palette`, `checkCircle`) to its exact `PhosphorIconsRegular` / `PhosphorIconsFill` `IconData` equivalent.
   * Update `AppIcon` to render `Icon(icon, size: size, color: effectiveColor, semanticLabel: semanticLabel)` where `effectiveColor = color ?? IconTheme.of(context).color ?? context.colors.textPrimary`.
2. **Complete `AppTheme.buildTheme(AppThemeId themeId, Brightness brightness)` in `lib/core/theme/app_theme.dart`:**
   * Resolve `final colors = themeId.colorsFor(brightness);`.
   * Attach `extensions: <ThemeExtension<dynamic>>[colors]` to `ThemeData`.
   * Populate `scaffoldBackgroundColor: colors.background`, `colorScheme`, `textTheme` (with `bodyColor: colors.textPrimary`, `displayColor: colors.textPrimary`), `appBarTheme`, `cardTheme`, `dialogTheme`, `bottomSheetTheme`, `dividerTheme`, `inputDecorationTheme`, `snackBarTheme`, `popupMenuTheme`, `datePickerTheme`, and `timePickerTheme` directly from `colors`.
   * Keep `AppTheme.lightTheme` and `AppTheme.darkTheme` as getters delegating to `buildTheme(AppThemeId.lavenderDream, Brightness.light / dark)` so all existing tests referencing `AppTheme.lightTheme` continue to work.
3. **Add `BuildContext` Theme Token Accessor (`context.colors`) & Dynamic `AppTypography`:**
   * Add a convenient `extension AppThemeContext on BuildContext`:
     ```dart
     AppThemeColors get colors =>
         Theme.of(this).extension<AppThemeColors>() ??
         (Theme.of(this).brightness == Brightness.dark
             ? AppPalettes.lavenderDreamDark
             : AppPalettes.lavenderDreamLight);
     ```
   * In `AppTypography` (`lib/core/theme/app_typography.dart`), remove hardcoded `color: AppColors.ink` from primary `TextStyle` definitions so `Text('...', style: AppTypography.screenTitle)` automatically inherits the active theme's `DefaultTextStyle` (`colors.textPrimary` in both Light and Dark modes!), while mapping secondary/muted styles cleanly via `context.colors`.
   * Update shared widgets (`AppBottomSheet`, `AppButton`, `AppFloatingDock`, `AppSegmentedControl`, `AppSwitchTile`, `AppTextField`, `AppToast`, `AppEmptyState`, `AppErrorState`, `AppLoadingState`, `AppSectionHeader`) and feature widgets/dialogs/sheets to read surface, background, border, divider, track, and brand colors from `context.colors` (`AppThemeColors`).
4. **Wire `AttendlyApp` (`lib/app/app.dart`) & `SettingsScreen` (`settings_screen.dart`):**
   * Watch `themePreferencesProvider` in `AttendlyApp` and pass `themeState.lightTheme`, `themeState.darkTheme`, and `themeState.themeMode` to `MaterialApp.router`.
   * Mount `AppearanceSection` in `SettingsScreen` so users can switch between System/Light/Dark and all 8 palettes directly from Settings.

---

## 6. Prioritized Action Plan (Implementation Batches)

### Batch 1 — Phosphor Icons Migration & Theme System Overhaul (High Priority)
* Update `pubspec.yaml` and `lib/core/theme/app_icons.dart` to use `phosphoricons_flutter` exclusively and remove `ColorFiltered` from `AppIcon`.
* Implement `AppTheme.buildTheme(AppThemeId, Brightness)` and `context.colors` extension.
* Implement `HomeWidgetService.updateThemeColors`.
* Update `AppearanceSection` to use `context.colors` and mount it in `SettingsScreen`.
* Connect `AttendlyApp` (`lib/app/app.dart`) to `themePreferencesProvider` with dynamic `SystemUiOverlayStyle`.
* Make `AppTypography` and all shared & feature widgets/dialogs/bottom sheets/pickers/painters theme-aware via `context.colors` (`AppThemeColors`) while keeping Lavender Dream Light 100% visually identical to the current design.

### Batch 2 — Database, Backup/Restore & Repository Integrity Fixes
* Update `BackupData`, `SemesterBackupModel`, `DayNoteBackupModel`, `BackupValidator`, and `BackupService` to export, validate, and restore `semesters.targetGoal`, `day_notes`, and theme preferences (with batch inserts and v1 backward compatibility).
* Fix `AttendanceRepositoryImpl.getSessionBySubjectDateComponent` (`..limit(1)`), `updateSession` component validation, and strict calendar date validation in `_validateSessionDate`.
* Fix `Semester.copyWith` date clearing in `SemesterFormSheet` and atomic upsert in `DayNoteRepositoryImpl.setNoteForDate`.
* Fix Android widget `AttendanceWidgetViews.kt` resource IDs and save `subject_${num}_pct_int` in `HomeWidgetService`.
* Add composite SQLite indexes on `attendance_sessions(subject_id, session_date)` and `subjects(semester_id, sort_order)`.

### Batch 3 — Performance & Architecture Cleanup
* Optimize `AttendanceCalculator.calculateSemester` ($O(N)$ session grouping) and `ScenarioCalculator`.
* Deduplicate summary providers and preserve `valueOrNull` across stream reloads.
* Move `sharedPreferencesProvider` to `lib/core/providers/shared_preferences_provider.dart` (with re-export in `onboarding_provider.dart`).

### Batch 4 — Tests, `progress.md`, and `CHANGELOG.md`
* Add unit and widget tests covering `day_notes` + `targetGoal` backup/restore, multi-session same-day repository queries, date clearing on semesters, and live theme/palette switching across screens and modals.
* Update `progress.md` and `CHANGELOG.md`.