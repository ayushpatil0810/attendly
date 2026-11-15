# Development Progress — College Attendance Tracker

## Project Overview
- **Project Name / Identifier:** College Attendance Tracker (Working title: attendly)
- **Current Development Phase:** Phase 5: Settings, Local Backup & Data Safety
- **Overall Project Status:** Phase 5 Completed (Ready for Phase 6 review)
- **Description:** A 100% offline-only personal college attendance tracking mobile app built with Flutter, Riverpod, Drift (SQLite), and go_router. Features independent lecture and lab tracking, Raw Combined and Component Average (50/50) attendance calculation methods, safe absence calculations, recovery projections, What-if Attendance Simulator, local JSON backup/export, transactional restore with validation, app preferences, and a custom design system following soft, colorful, modern minimalism (light theme only, Plus Jakarta Sans, Hugeicons, floating bottom navigation dock).

---

## Phase Tracker

| Phase | Description | Status |
|---|---|---|
| **Phase 1** | **Foundation, Design System & Initial Setup** | **Completed** |
| **Phase 2** | **Attendance Management** | **Completed** |
| **Phase 3** | **Dashboard & Attendance Calculations** | **Completed** |
| **Phase 4** | **Insights, Advanced Charts & Attendance Simulator** | **Completed** |
| **Phase 5** | **Settings, Local Backup & Data Safety** | **Completed** |
| Phase 6 | Polish & Release Preparation | Not Started |

---

## Phase 5 Progress & Achievements

### 1. Pre-implementation Baseline & Review
- [x] Reviewed all nine project documents (`PRD.md`, `SPEC.md`, `TECH_STACK.md`, `ARCHITECTURE.md`, `DATABASE.md`, `DESIGN.md`, `TESTING.md`, `AGENTS.md`, `CHANGELOG.md`) and `progress.md`.
- [x] Verified existing tests and static analysis baseline: 147/147 tests passed, 0 analyzer issues found.
- [x] Verified strict separation between actual attendance records (SQLite) and hypothetical simulator sessions (in-memory only).

### 2. Core Backup & Restore System (`lib/core/backup/`)
- [x] **Versioned Format Models (`BackupConstants` & `BackupData`):**
  - Authoritative format identifier `college-attendance-tracker-backup` with version `1`.
  - Serializes and deserializes `SemesterBackupModel`, `SubjectBackupModel`, `AttendanceSessionBackupModel`, and optional `appPreferences`.
  - Generates `BackupSummary` for previewing export date, semester names/counts, subject counts, and present/absent session breakdowns before restore.
- [x] **Pure Dart Validator (`BackupValidator`):**
  - Validates JSON document syntax and structure.
  - Verifies format identifier and format version (rejecting unsupported/future versions > 1).
  - Validates ISO-8601 timestamps and calendar date strings (`YYYY-MM-DD`, real calendar validation).
  - Enforces entity uniqueness (no duplicate semester IDs, subject IDs, or session IDs).
  - Validates referential integrity: every subject references an existing semester in the backup; every session references an existing subject.
  - Enforces component rules: rejects sessions whose component (`lecture` or `lab`) is disabled on the parent subject.
  - Enforces duplicate session constraints: rejects duplicate `(subjectId, sessionDate, component)` records.
  - Enforces safe file size (< 25 MB) and total record count boundaries (< 100,000 records).
- [x] **Transactional Backup Service (`BackupService`):**
  - Generates portable UTF-8 JSON backups of all persistent application data.
  - Executes restore entirely within an atomic database transaction (`_db.transaction`).
  - Safely remaps old IDs to new auto-increment IDs (`oldId -> newId`) across foreign-key relationships.
  - Strictly preserves existing local database without partial writes if any error occurs during restore.
  - Adheres to the approved replace restore policy with explicit user confirmation.
- [x] **Strict Simulator Isolation:**
  - Ephemeral simulator scenarios remain strictly in memory; they are never queried or exported during backup generation, and hypothetical sessions cannot be imported into the actual database.

### 3. Core Platform Services (`lib/core/services/`)
- [x] **Platform File Service (`PlatformFileService`):**
  - Abstraction for picking local `.json` backup files and exporting backups.
  - Uses `file_picker` (13.3.3) for custom extension file picking and desktop file saving.
  - Uses `share_plus` (13.3.1) for native mobile share-sheet export allowing offline saving to local files or storage.
  - Mockable interface for 100% deterministic test execution.
- [x] **Preferences & Haptics (`preferences_service.dart`):**
  - Manages `hapticFeedbackEnabled` state persisting via `SharedPreferences`.
  - `AppHaptics` utility providing tactile vibration for attendance logging and button interactions when enabled.

### 4. Settings Presentation Suite (`lib/features/settings/` & `SettingsScreen`)
- [x] **Settings Screen (`SettingsScreen`):**
  - Custom top navigation bar with back navigation and clean Plus Jakarta Sans title.
  - Four compact, non-card-overloaded sections following `DESIGN.md`.
- [x] **Semester Settings (`SemesterSettingsSection`):**
  - Displays current active semester name, threshold, and calculation policy.
  - Immediate calculation method switcher (`Raw Combined` vs `50/50 Average`) with instant recalculation across screens.
  - Real-time attendance threshold slider updating target threshold across all calculations immediately.
  - Direct actions to switch active semesters (`SemesterSwitcherSheet`) or edit full semester details (`SemesterFormSheet`).
- [x] **App Preferences (`AppPreferencesSection`):**
  - Interactive `AppSwitchTile` toggling haptic feedback.
  - Transparent information explaining system-level reduced-motion support.
- [x] **Local Backup & Restore (`BackupRestoreSection`):**
  - One-tap export flow with timestamped file naming (`attendly_backup_YYYY-MM-DD_HHmmss.json`), loading indicators, and success toast.
  - One-tap restore flow prompting file selection, validating backup, and displaying error dialogs for corrupted or unsupported files.
  - `BackupSummaryDialog`: Pre-restore confirmation modal displaying export date, semester list, subject count, attendance breakdown, and a high-visibility warning regarding data replacement.
- [x] **Privacy & Offline Information (`PrivacyOfflineSection`):**
  - Highlights 100% offline local SQLite storage.
  - Emphasizes zero account/login requirements, zero cloud sync/telemetry, and student data ownership.
  - Explains data loss risk upon app uninstall if no backup was exported.
- [x] **Navigation & Integration:**
  - Registered `/settings` route in `GoRouter` (`RouteNames.settingsPath`).
  - Linked Settings cog in `DashboardHeader` directly to Settings screen.

---

## Architectural & File Changes in Phase 5

```text
lib/
├── app/
│   └── router/
│       ├── app_router.dart                                      # Registered /settings route
│       └── route_names.dart                                     # Added settings & settingsPath
├── core/
│   ├── backup/
│   │   ├── backup_format.dart                                   # Format constants, entities & BackupSummary
│   │   ├── backup_providers.dart                                # Riverpod backupServiceProvider
│   │   ├── backup_service.dart                                  # JSON export & transactional restore service
│   │   └── backup_validator.dart                                # Multi-stage schema and integrity validator
│   ├── services/
│   │   ├── platform_file_service.dart                           # FilePicker & SharePlus file abstraction
│   │   └── preferences_service.dart                             # Haptic feedback state & AppHaptics utility
│   └── theme/
│       └── app_icons.dart                                       # Added HugeIcons for backup, restore, shield
└── features/
    ├── attendance/
    │   └── presentation/widgets/
    │       ├── quick_log_sheet.dart                             # Added tactile haptic feedback on save
    │       └── session_form_sheet.dart                          # Added tactile haptic feedback on save
    ├── dashboard/
    │   └── presentation/widgets/
    │       └── dashboard_header.dart                            # Connected settings cog to /settings route
    ├── semesters/
    │   └── presentation/providers/
    │       └── semesters_provider.dart                          # Persistent SemesterController (non-autoDispose)
    └── settings/
        └── presentation/
            ├── providers/
            │   └── settings_providers.dart                      # BackupController and export/restore states
            ├── screens/
            │   └── settings_screen.dart                         # Four-section Settings screen
            └── widgets/
                ├── app_preferences_section.dart                 # Haptic toggle & reduced motion info
                ├── backup_restore_section.dart                  # Export & restore action cards
                ├── backup_summary_dialog.dart                   # Pre-restore summary confirmation modal
                ├── privacy_offline_section.dart                 # Offline-only & privacy notice
                └── semester_settings_section.dart               # Threshold slider & calculation switcher
```

---

## Test Verification Summary
- **Total Tests:** 186 passing tests across 24 test suites (39 new tests added in Phase 5).
- **Core Backup & Validation Tests:**
  - `backup_validator_test.dart` (23 tests): Valid backup parsing and summary, empty string rejection, invalid JSON syntax, non-object root, missing/unrecognized format identifier, unsupported format version (> 1), invalid export timestamp, missing data object, non-list collections, duplicate semester IDs, blank semester name, invalid threshold (out of bounds), unsupported calculation method, invalid calendar dates (e.g. Feb 31), start date after end date, duplicate subject IDs, broken semester foreign keys, subject without enabled components, duplicate session IDs, broken subject foreign keys, invalid session calendar dates, invalid component/status enums, component disabled on subject, duplicate `(subject, date, component)` sessions.
  - `backup_export_test.dart` (3 tests): Empty database export matching schema, populated database export with all fields and preferences, and simulator data isolation verification.
  - `backup_restore_test.dart` (4 tests): Fresh database restore with domain calculation parity, replace policy verification, transactional failure rollback leaving existing database 100% intact, and full round-trip export-restore-reexport data equivalence.
- **Settings Screen & Navigation Tests:**
  - `settings_screen_test.dart` (8 tests): All 4 sections rendered with initial semester details, toggling haptic feedback updates preference state, changing calculation method updates semester, export backup flow triggers file service with success toast, restore with invalid file shows error dialog, restore with valid file displays summary dialog and cancels safely without altering database, confirming Restore & Replace replaces local data, privacy section displays all offline guarantees.
  - `dashboard_settings_navigation_test.dart` (1 test): Tapping settings cog on dashboard header navigates to `/settings`.
- **Pre-existing Suites (147 tests):** All database, calculation engine, simulator isolation, insights, history, quick log, and onboarding tests continue passing without regression.
- **Static Analysis & Formatting:**
  - `dart format .`: 141 files checked, 100% cleanly formatted.
  - `flutter analyze`: **0 issues found**.
  - `flutter test`: **186/186 tests passed**.

---

## Privacy & Offline Verification
- [x] Zero network dependencies: Verified no Firebase, Supabase, authentication, remote databases, cloud sync, or telemetry packages exist.
- [x] Platform manifest check: Verified `android/app/src/main/AndroidManifest.xml` contains NO `android.permission.INTERNET` permission.
- [x] Backups remain 100% local: Files are written only to device storage or native share sheets; no data is ever uploaded.
- [x] Honest data claims: No unsupported encryption claims are made in the UI or documentation.

---

## Known Issues
- None. All Phase 5 requirements, local backup/export, local restore/import, transactional safety, data validation, and settings controls are verified and working 100% offline.

---

## Next Steps (Phase 6 Readiness)
1. **Wait for user explicit approval** before initiating Phase 6.
2. In Phase 6 (Polish & Release Preparation):
   - Accessibility audit across all screens.
   - Comprehensive edge-case handling and responsiveness verification on small viewports.
   - Final release preparation according to project documentation.

---

## Last Updated
2026-11-15
