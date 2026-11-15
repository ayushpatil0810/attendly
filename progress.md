# Development Progress — College Attendance Tracker

## Project Overview
- **Project Name / Identifier:** College Attendance Tracker (Working title: attendly)
- **Current Development Phase:** Phase 1: Foundation & Setup
- **Overall Project Status:** Phase 1 Completed (Ready for Phase 2 review)
- **Description:** A 100% offline-only personal college attendance tracking mobile app built with Flutter, Riverpod, Drift (SQLite), and go_router. Features independent lecture and lab tracking, Raw Combined and Component Average (50/50) attendance calculation methods, safe absence calculations, and a custom design system following soft, colorful, modern minimalism (light theme only, Plus Jakarta Sans, Hugeicons, floating bottom navigation dock).

---

## Phase Tracker

| Phase | Description | Status |
|---|---|---|
| **Phase 1** | **Foundation, Design System & Initial Setup** | **Completed** |
| Phase 2 | Attendance Management | Not Started |
| Phase 3 | Dashboard | Not Started |
| Phase 4 | Analytics & Simulator | Not Started |
| Phase 5 | Settings & Data Safety | Not Started |
| Phase 6 | Polish & Release Preparation | Not Started |

---

## Current Phase Progress (Phase 1)

- [x] Inspect existing repository and documentation (`PRD.md`, `SPEC.md`, `TECH_STACK.md`, `ARCHITECTURE.md`, `DATABASE.md`, `DESIGN.md`, `TESTING.md`, `AGENTS.md`, `CHANGELOG.md`)
- [x] Create and initialize `progress.md`
- [x] Initialize Flutter project with Android and iOS platform support
- [x] Configure approved dependencies (`flutter_riverpod: ^3.5.0`, `go_router: ^18.1.4`, `drift: ^2.35.4`, `sqlite3_flutter_libs: ^0.6.0+eol`, `path_provider: ^2.1.6`, `path: ^1.9.1`, `intl: ^0.20.3`, `hugeicons: ^4.4.0`, `shared_preferences: ^2.5.6`, dev: `drift_dev: ^2.35.3`, `build_runner: ^2.17.1`, `flutter_lints: ^6.0.0`, `mocktail: ^1.0.5`, `sqlite3: ^3.9.1`)
- [x] Bundle Plus Jakarta Sans locally (`assets/fonts/PlusJakartaSans-VariableFont_wght.ttf` registered in `pubspec.yaml`)
- [x] Integrate Hugeicons package with centralized icon mapping (`AppIcons` / `AppIcon`)
- [x] Implement Workstream B: Design system tokens & components
  - [x] Color tokens (`brandViolet`, `brandMint`, `brandCoral`, `brandPeach`, `warmWhite`, `ink`, `mutedInk`, `divider`, `track`, tints) in `lib/core/theme/app_colors.dart`
  - [x] Typography scale with Plus Jakarta Sans and tabular figures in `lib/core/theme/app_typography.dart`
  - [x] Spacing scale (8-point grid) in `lib/core/theme/app_spacing.dart` and radius tokens in `lib/core/theme/app_radius.dart`
  - [x] Reusable foundational components:
    - [x] `AppButton` (primary, secondary, outline, text, destructive with loading states)
    - [x] `AppTextField` (clean, non-boxed, custom borders, validation and helper styling)
    - [x] `AppSegmentedControl` (pill toggle for calculation method selection)
    - [x] `AppSwitchTile` (switch row with custom tinting for lecture/lab toggles)
    - [x] `AppSectionHeader` (clean section dividers with optional action buttons)
    - [x] `AppProgressBar` and `AppProgressRing` (smooth rounded visual progress)
    - [x] `AppToast` (floating snackbar feedback with undo actions)
    - [x] `AppBottomSheet` (modal bottom sheet container with drag handle)
    - [x] `AppFloatingDock` (floating elevated pill bottom navigation bar with central quick log)
    - [x] `AppLoadingState` and `AppEmptyState` (soft, friendly illustration/icon states)
- [x] Implement Workstream D: Local database foundation (Drift/SQLite)
  - [x] `Semesters` table (id, name, start_date, end_date, attendance_threshold, calculation_method, is_archived, created_at, updated_at)
  - [x] `Subjects` table (id, semester_id, name, lecture_enabled, lab_enabled, sort_order, created_at, updated_at)
  - [x] `AttendanceSessions` table (id, subject_id, session_date, component, status, note, created_at, updated_at)
  - [x] Foreign keys enabled via `PRAGMA foreign_keys = ON;` with cascade deletion
  - [x] Check constraints (name non-empty, threshold in (0, 1], valid calculation methods, at least one subject component enabled, valid session component & status)
  - [x] Schema versioning (v1) and typed DAOs/methods in `AppDatabase`
- [x] Implement Workstream A: Flutter project foundation & architecture
  - [x] Feature-first modular folder structure (`app`, `core`, `features/semesters`, `features/subjects`, `features/attendance`, `features/onboarding`, `features/shell`)
  - [x] Core bootstrap, centralized error handling (`AppFailure`, `ValidationFailure`, `DatabaseFailure`, `NotFoundFailure`), and Riverpod initialization
  - [x] GoRouter configuration (`/`, `/onboarding`, `/semester-setup`, `/home`) with dynamic redirects
  - [x] Clean separation: Presentation, State, Domain, and Data
  - [x] Repository interfaces and implementations: `SemesterRepositoryImpl`, `SubjectRepositoryImpl`
- [x] Implement Workstream C: Splash screen and onboarding
  - [x] Splash screen (`SplashScreen`) with smooth initialization and auto-redirection
  - [x] Onboarding (`OnboardingScreen`) with 3 screens explaining Lecture/Lab tracking, Safe Absences, and History management
  - [x] Local persistence of onboarding completion via `SharedPreferences`
- [x] Implement Workstream E: Semester management
  - [x] Create semester with validation (name, optional dates, threshold default 75%, calculation method: Raw Combined or Component Average)
  - [x] List semesters & active semester selection (`SemesterSwitcherSheet`)
  - [x] Edit semester details (`SemesterFormSheet`)
  - [x] Archive/Unarchive and delete semester with confirmation
- [x] Implement Workstream F: Subject management
  - [x] Add subject with validation (name, lecture/lab toggles, prevents disabling both)
  - [x] View subjects in active semester (`SubjectsScreen`)
  - [x] Edit subject details (`SubjectFormSheet`)
  - [x] Delete subject with confirmation dialog
- [x] Implement Workstream G: Initial application navigation
  - [x] Main screen layout with floating bottom dock (`MainShellScreen` hosting Home, Subjects, Quick Log action, History, Insights)
  - [x] Home setup/first-use state displaying active semester config and subject count without fake attendance statistics
  - [x] Real Subjects screen reading and writing to the Drift database
  - [x] Honest placeholder states for Quick Log (Phase 2), History (Phase 2), and Insights (Phase 3/4)
- [x] Comprehensive automated test coverage:
  - [x] 12 Database tests (`test/core/database/app_database_test.dart`)
  - [x] 6 Semester repository tests (`test/features/semesters/data/semester_repository_test.dart`)
  - [x] 4 Subject repository tests (`test/features/subjects/data/subject_repository_test.dart`)
  - [x] 3 Semester state tests (`test/features/semesters/state/semesters_provider_test.dart`)
  - [x] 1 Subject state test (`test/features/subjects/state/subjects_provider_test.dart`)
  - [x] 1 Splash screen widget test (`test/features/onboarding/widget/splash_screen_test.dart`)
  - [x] 1 Onboarding screen widget test (`test/features/onboarding/widget/onboarding_screen_test.dart`)
  - [x] 2 Semester setup widget tests (`test/features/semesters/widget/semester_setup_screen_test.dart`)
  - [x] 1 Subjects screen widget test (`test/features/subjects/widget/subjects_screen_test.dart`)
  - [x] 1 Navigation dock widget test (`test/features/shell/widget/navigation_dock_test.dart`)
- [x] Quality verification:
  - [x] `dart format .` (60 files cleanly formatted)
  - [x] `flutter analyze` (0 issues found)
  - [x] `flutter test` (32 tests passing out of 32)

---

## Implemented Features
1. **Bootstrap & State Architecture:**
   - SharedPreferences-backed initial state and Riverpod-powered dependency injection.
   - Centralized `AppRouter` with route protection and reactive redirection.
   - Clean domain entities with immutability, validation, and domain failures.
2. **Custom Design System (Soft Colorful Modern Minimalism):**
   - Centralized palette: Brand Violet (`#9278F2`), Mint (`#8BE4D0`), Coral (`#FF929B`), Peach (`#FFB49F`), Warm White (`#FFFAF9`), Deep Ink (`#30263F`), Muted Ink (`#827B8D`).
   - Plus Jakarta Sans bundled font with tabular figures support for metrics.
   - Unified Hugeicons iconography with consistent stroke and rounded styling.
   - Elevated floating bottom navigation dock with central pill Quick Log trigger.
   - Custom components: `AppButton`, `AppTextField`, `AppSegmentedControl`, `AppSwitchTile`, `AppProgressBar`, `AppProgressRing`, `AppBottomSheet`, `AppToast`, `AppEmptyState`, `AppLoadingState`.
3. **Local Database (Drift SQLite):**
   - Tables: `Semesters`, `Subjects`, `AttendanceSessions`.
   - Constraints: Foreign key enforcement, cascade deletion, calculation method enum constraints, attendance threshold boundaries `(0.0, 1.0]`, and minimum component validation (at least one of lecture/lab active).
   - In-memory testing support with custom native sqlite3 bindings.
4. **Onboarding & Splash:**
   - Branded splash screen with reactive initialization.
   - 3-screen animated onboarding carousel highlighting core value propositions.
   - First-run completion persistence avoiding repeat prompts.
5. **Semester Management:**
   - First semester onboarding setup screen.
   - Bottom sheet semester switcher with active indicator, create, edit, and archive flows.
   - Support for Raw Combined and Component Average (50/50) calculation algorithms.
6. **Subject Management:**
   - Subject creation and editing modal sheets.
   - Independent Lecture and Lab toggles with validation rule preventing both from being disabled.
   - Subject deletion with cascading session cleanup and confirmation dialog.
7. **Main Navigation Shell:**
   - 5-destination floating dock (Home, Subjects, Quick Log, History, Insights).
   - Real, functional Home and Subjects screens.
   - Honest Phase 2 / Phase 3 placeholder sheets for Quick Log, History, and Insights.

---

## Project Structure
```text
lib/
├── main.dart                                 # Application entrypoint & ProviderScope initialization
├── app/
│   ├── app.dart                              # Root AttendlyApp widget with MaterialApp.router & theme
│   ├── bootstrap/
│   │   └── app_bootstrap.dart                # Async pre-run initialization & service wiring
│   └── router/
│       └── app_router.dart                   # Declarative go_router configuration & route redirection
├── core/
│   ├── database/
│   │   ├── app_database.dart                 # Drift database definition, migrations & DAOs
│   │   ├── app_database.g.dart               # Generated Drift code
│   │   ├── connection/
│   │   │   └── open_connection.dart          # Platform SQLite connection (sqlite3_flutter_libs)
│   │   └── tables/
│   │       ├── semesters_table.dart          # Semesters schema & check constraints
│   │       ├── subjects_table.dart           # Subjects schema & foreign key relationships
│   │       └── attendance_sessions_table.dart# Attendance sessions schema & status enums
│   ├── errors/
│   │   └── app_failure.dart                  # Typed domain failure classes
│   ├── shared/
│   │   └── widgets/                          # Reusable design system UI components
│   │       ├── app_bottom_sheet.dart
│   │       ├── app_button.dart
│   │       ├── app_empty_state.dart
│   │       ├── app_floating_dock.dart
│   │       ├── app_loading_state.dart
│   │       ├── app_progress.dart
│   │       ├── app_section_header.dart
│   │       ├── app_segmented_control.dart
│   │       ├── app_switch.dart
│   │       ├── app_text_field.dart
│   │       └── app_toast.dart
│   └── theme/
│       ├── app_colors.dart                   # Reconciled color tokens
│       ├── app_icons.dart                    # Unified Hugeicons icon mappings
│       ├── app_radius.dart                   # Border radius tokens
│       ├── app_spacing.dart                  # 8-point rhythm spacing scale
│       ├── app_theme.dart                    # Light-only custom ThemeData
│       └── app_typography.dart               # Plus Jakarta Sans typographic scale
└── features/
    ├── attendance/
    │   └── domain/entities/                  # AttendanceSession & enums (calculation method, component, status)
    ├── onboarding/
    │   └── presentation/screens/             # SplashScreen & OnboardingScreen
    ├── semesters/
    │   ├── data/repositories/                # SemesterRepository implementation
    │   ├── domain/entities/ & repositories/  # Semester entity & repository contract
    │   ├── presentation/
    │   │   ├── screens/                      # SemesterSetupScreen
    │   │   └── widgets/                      # SemesterSwitcherSheet, SemesterFormSheet
    │   └── state/                            # Riverpod providers & SemesterController
    ├── subjects/
    │   ├── data/repositories/                # SubjectRepository implementation
    │   ├── domain/entities/ & repositories/  # Subject entity & repository contract
    │   ├── presentation/
    │   │   ├── screens/                      # SubjectsScreen
    │   │   └── widgets/                      # SubjectFormSheet
    │   └── state/                            # Riverpod providers & SubjectController
    └── shell/
        └── presentation/screens/             # MainShellScreen, HomeScreen, HistoryPlaceholder, InsightsPlaceholder
```

---

## Technical Decisions
- **Framework & Language:** Flutter 3.50.0 / Dart 3.14.0.
- **Architecture:** Offline-only, feature-first Clean Architecture with Riverpod 3.5.0 (`AsyncNotifierProvider` / `StreamProvider`).
- **Database Engine:** SQLite via Drift (`drift: ^2.35.4`, `sqlite3_flutter_libs: ^0.6.0+eol`). Fully reactive query streams for auto-updating UI.
- **Constraints & Cascade:** Hard SQLite foreign keys (`PRAGMA foreign_keys = ON;`) and check constraints enforced at the database level to ensure zero data corruption.
- **Routing:** `go_router` 18.1.4 with GoRoute definitions and declarative redirects based on onboarding and active semester presence.
- **Iconography:** Hugeicons only (`hugeicons: ^4.4.0`) wrapped in an `AppIcons` centralized registry.
- **Typography:** Plus Jakarta Sans variable font bundled locally in `assets/fonts/` with `FontFeature.tabularFigures()` for numbers.
- **Android / Windows Build:** Configured `kotlin.incremental=false` in `android/gradle.properties` to eliminate Windows file-locking exceptions on Kotlin daemon incremental caches during Gradle builds.
- **Zero Remote Dependencies:** Strictly no Firebase, no Supabase, no authentication, no network analytics.

---

## Database Status
- **Current Schema Version:** 1
- **Tables Implemented:**
  1. `semesters`: `id`, `name`, `start_date`, `end_date`, `attendance_threshold`, `calculation_method`, `is_archived`, `created_at`, `updated_at`.
  2. `subjects`: `id`, `semester_id`, `name`, `lecture_enabled`, `lab_enabled`, `sort_order`, `created_at`, `updated_at`.
  3. `attendance_sessions`: `id`, `subject_id`, `session_date`, `component`, `status`, `note`, `created_at`, `updated_at`.
- **Migrations Implemented:** Initial baseline schema (Version 1).
- **Outstanding Database Tasks for Phase 2:** Implement attendance logging DAO queries, transaction methods for batch session marking, and undo logging.

---

## Tests and Validation
- **Total Tests:** 32 passing tests across 10 test suites.
- **Database Tests (`test/core/database/app_database_test.dart`):** 12 tests
  - Verifies schema version 1, table insertions, retrievals, blank name rejections, threshold bounds validation, calculation method validation, lecture/lab component toggles validation, foreign key cascade deletions, invalid session status/component rejections, and disk reopening persistence.
- **Repository Tests:** 10 tests
  - `SemesterRepositoryImpl` (6 tests): create, get, watch, update, archive, and validation error handling.
  - `SubjectRepositoryImpl` (4 tests): create, get, watch by semester, update, delete, and validation error handling.
- **State Management Tests:** 4 tests
  - `SemestersProvider` (3 tests): semester creation, active semester switching, and archive fallback.
  - `SubjectsProvider` (1 test): subjects stream reactivity on creation.
- **Widget & Screen Tests:** 6 tests
  - `SplashScreen`: Initialization and auto-navigation.
  - `OnboardingScreen`: Page scrolling, indicator updates, button text transition to "Get Started", and completion persistence.
  - `SemesterSetupScreen` (2 tests): Validation error triggers on blank inputs, successful semester creation and transition to home.
  - `SubjectsScreen`: Empty state rendering, subject creation via bottom sheet, and list updates.
  - `NavigationDock`: Tab switching between Home, Subjects, History, Insights, and Quick Log bottom sheet presentation.
- **Static Analysis:**
  - `dart format .`: 60 files checked, 100% formatted.
  - `flutter analyze`: **0 issues found**.
  - `flutter test`: **32/32 tests passed**.

---

## Known Issues
- None. All Phase 1 requirements, design constraints, and database contracts are fully implemented and verified.

---

## Next Steps (Phase 2 Readiness)
1. **Wait for user explicit approval** before initiating Phase 2.
2. Once Phase 2 commences:
   - Implement Attendance Logging UI and state management (`QuickLogSheet`, timetable or direct subject session logging).
   - Implement Single-tap Present/Absent recording with instant feedback.
   - Implement Lecture vs. Lab attendance session segregation.
   - Implement Bulk date marking / multi-session logs.
   - Implement Attendance History screen with chronological session list, filters, and edit/delete capability.
   - Implement Instant Undo functionality via `AppToast`.

---

## Last Updated
2026-11-15
