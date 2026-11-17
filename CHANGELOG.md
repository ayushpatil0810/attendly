# Changelog

All notable changes to the College Attendance Tracker (attendly) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-11-17

### Added
- **Multi-Theme Design System & Dark Mode:**
  - Implemented 8 handcrafted pastel color themes with both Light and Dark mode appearances:
    1. **Lavender Dream (Default):** Soft violet and mint accents.
    2. **Ocean Breeze:** Coastal sky blue and seafoam mint accents.
    3. **Peach Blossom:** Warm apricot, sunny coral, and soft mint accents.
    4. **Sage Garden:** Calm eucalyptus, forest green, and earthy terracotta accents.
    5. **Midnight Blue:** Twilight navy, soft cornflower, and rose accents.
    6. **Buttercream:** Warm golden vanilla, honey amber, and meadow mint accents.
    7. **Rose Quartz:** Powdery dusty rose, cranberry coral, and turquoise accents.
    8. **Graphite Mint:** Sleek slate charcoal, crisp pastel mint, and soft coral accents.
  - **Appearance Section in Settings:**
    - Mode selector: System Default, Light Mode, and Dark Mode.
    - Color Theme selector: Interactive grid displaying all 8 pastel themes with 4-swatch color previews, active checkmark, and instant application.
    - Local persistence using `SharedPreferences` (`pref_theme_mode_v1` and `pref_color_theme_id_v1`), automatically restoring preferences on app restart.
  - **Centralized Design Token Architecture:**
    - Custom `ThemeExtension<AppThemeColors>` managing semantic tokens for brand, secondary, surfaces, backgrounds, text hierarchy, borders, dividers, tracks, dock, and overlays.
    - Integrated with standard Flutter `ThemeData` and `ColorScheme`.
    - Dynamic delegation in `AppColors` enabling existing widgets to immediately respond to active theme and brightness changes.
  - **Tailored Dark Mode Palettes:**
    - Comfort-focused dark backgrounds and elevated surface cards (avoiding plain color inversions).
    - High-contrast readable typography clearing accessibility standards.
    - Consistent semantic attendance colors across all themes (Present = mint/success, Absent = coral/error, Warning = warning, Neutral = neutral).
  - **Android Home Screen Widget Theme Synchronization:**
    - Widget data synchronization via `HomeWidgetService.updateThemeColors` passing active theme ID, dark mode state, and primary/background ARGB colors.
  - **Comprehensive Theme Test Suite:**
    - Unit and widget tests covering all 8 theme palettes, light/dark variants, persistence, restoration, semantic attendance color consistency, and settings interaction.

### Fixed
- **Global Theme Switching & Route Color Synchronization:**
  - Resolved root architectural issue in `AttendlyApp` where `Theme.of(context).brightness` was inspected before `MaterialApp` initialized, preventing dark mode and theme changes from updating existing route trees.
  - Bound effective platform brightness via `MediaQuery.maybePlatformBrightnessOf(context) ?? WidgetsBinding.instance.platformDispatcher.platformBrightness` combined with `themeState.themeMode`.
  - Added reactive `ValueKey` to `MaterialApp.router` ensuring instant, full-tree color reconstitution upon any palette or appearance change without losing navigation state.
  - Updated centralized `AppTheme.buildTheme()` to populate all Material theme surfaces (`canvasColor`, `cardColor`, `dialogBackgroundColor`, `colorScheme`, `bottomSheetTheme`, `dialogTheme`, `popupMenuTheme`) preventing black flashes during route transitions.
  - Refactored reusable core widgets (`AppFloatingDock`, `AppButton`, `AppTextField`, `AppSwitchTile`, `AppProgressBar`, `AppProgressRing`, `AppBottomSheet`, `AppCloseButton`, `AppEmptyState`, `AppErrorState`, `AppLoadingState`, `AppSegmentedControl`, `AppToast`) to derive colors directly from `context.colors`.
  - Fixed theme switching and dark mode synchronization on `InsightsScreen` and its component tree (`InsightsOverviewCard`, `SubjectComparisonCard`, `LectureLabComparisonCard`, `AdvancedTrendCard`, `InsightObservationsSection`, `InsightsFilterBar`):
    - Subscribed all widgets and text styles to `context.colors`.
    - Added explicit color tokens to custom painters (`_AttendanceDistributionPainter`, `_AdvancedTrendLinePainter`, `_TrendLinePainter`) and updated their `shouldRepaint` implementations to detect theme and color changes immediately.
    - Added crisp surface borders (`Border.all(color: colors.divider)`) and adaptive shadows across all insights cards to ensure comfortable card definition and elevation across all 8 light and dark palettes.
    - Updated `MainShellScreen`'s `IndexedStack` to recreate child elements reactively on theme updates.

## [1.1.0] - 2026-11-16

### Added
- **Attendance Goals & Milestones:**
  - Set personal attendance goals per semester (default: 85%, customizable from 50% to 100% with 80%, 85%, 90%, 95% presets).
  - Kept personal ambition independent from official university attendance threshold.
  - Added `GoalMilestonesCard` on the dashboard displaying current attendance vs. goal, a dual-colored progress track with goal marker tick, and consecutive classes needed calculation (`RecoveryCalculator.calculateGoalRecovery`).
  - Added personal goal indicators on `SubjectDetailSheet` showing subject progress towards the goal.
  - Milestone system celebrating 75%, 80%, 85%, 90%, 95%, and 100% marks with subtle scale and fade animated celebration dialog (`MilestoneCelebrationDialog`) and horizontal achievement badge chips on the dashboard.
  - Milestone achievement status tracked per-semester in local offline storage (`MilestoneService`).
  - Correctly handled unavailable Component Average calculations with honest guidance directing students to scenario simulations.
  - Updated Drift SQLite database schema to version 5 with safe migration adding `target_goal` to `Semesters` table.
  - Included personal goal preservation in QR code export/import (`SemesterQrPayload`).
- **Android Home Screen Widgets:**
  - Designed and built three resizable native Android home screen widgets:
    - **Small (2x2):** Overall attendance percentage, circular determinate progress ring, semester title, and threshold status badge.
    - **Medium (4x2):** Semester name, overall attendance %, present/absent count chips, total recorded sessions, and a one-tap Quick Log button.
    - **Large (4x4):** Semester name, attendance %, threshold status badge, personal goal progress advice, subject-wise breakdown (top 4 subjects with present/conducted stats and status pills), and Quick Log button.
  - Native Android widget layouts, drawables, and color resources adhering strictly to the Attendly design system (Plus Jakarta Sans, soft pastels, WCAG AA contrast).
  - Kotlin widget providers: `SmallAttendanceWidgetProvider`, `MediumAttendanceWidgetProvider`, and `LargeAttendanceWidgetProvider`.
  - Reactive background widget synchronization via `HomeWidgetService` triggered upon attendance logging, undo, deletion, or semester changes.
  - Deep linking support (`attendly://quick-log`) launching directly into the Quick Log sheet.
  - 100% offline-only and private: no cloud sync, no tracking, and simulator data strictly isolated from home widgets.

## [1.0.0-rc.1] - 2026-11-15

### Added
- **Official Application Icon & Android Adaptive Icons:**
  - Configured Android Adaptive Icons (`mipmap-anydpi-v26/ic_launcher.xml` and `ic_launcher_round.xml`) with warm-white background (`#FFFAF9`) and centered transparent calendar foreground layer inside the 72dp safe zone.
  - Rasterized `attendly_calendar_symbol_transparent.svg` into transparent adaptive foregrounds across all 5 mipmap densities (`mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher_foreground.png`).
  - Generated legacy fallback icons (`ic_launcher.png` and `ic_launcher_round.png`) across all 5 mipmap densities.
  - Generated Play Store assets (`assets/icons/app_icon.png` 512px, `assets/icons/app_icon_1024.png` 1024px).
  - Added automated icon & splash regeneration tool `tool/generate_icons.py`.
- **Primary Splash Screen Logo:**
  - Integrated `attendly_primary_splash_logo.svg` across Flutter `SplashScreen` (`assets/images/splash_logo.png`) and Android native cold-start launch screen (`android/app/src/main/res/drawable/launch_image.png` + `launch_background.xml`).
- **Subject Detail Sheet (`SubjectDetailSheet`):** Bottom sheet displaying comprehensive subject-level attendance summary, progress indicator, Lecture/Lab component breakdown, safe absence/recovery metrics, and direct attendance logging.
- **Interactive Subjects Screen:** Live attendance statistics, progress indicators, meeting/below threshold badges, and tap-to-inspect interaction opening the detailed subject breakdown.
- **End-to-End User Journey Test Suite:** 6 comprehensive automated end-to-end integration tests verifying:
  - Journey 1: New student onboarding, semester setup, and empty dashboard state.
  - Journey 2: Quick Log recording, duplicate session protection, and immediate undo.
  - Journey 3: Historical past attendance logging, status editing, and session deletion.
  - Journey 4: Live attendance analytics, threshold modifications, and 50/50 component calculation recalculations.
  - Journey 5: Attendance simulator scenarios with strict database isolation.
  - Journey 6: Full backup export, parity verification, corrupted file rejection, and transaction rollback.
- **Accessibility Enhancements:**
  - Added semantic labels across `AppButton`, `AppFloatingDock`, `DashboardHeader`, and `AttendanceCalendar`.
  - Added reduced-motion support respecting `MediaQuery.disableAnimationsOf(context)` in buttons and floating navigation dock.
  - Guaranteed minimum 40–48px tap targets across primary and secondary controls.
  - Prevented button label `RenderFlex` overflows on narrow phone viewports with flexible text truncation.
- **Pre-release Build Outputs:**
  - Verified Android debug APK (`build/app/outputs/flutter-apk/app-debug.apk`).
  - Verified Android release APK (`build/app/outputs/flutter-apk/app-release.apk`).

### Changed
- Refactored `DashboardSubjectPreview` rows to be interactive, navigating directly to the Subjects screen on tap.
- Enhanced `QuickLogSheet` to accept an optional `initialSubjectId` parameter when launched from subject detail views.

### Removed
- Removed obsolete placeholder widget `QuickLogPlaceholderSheet` left over from Phase 1.

---

## [0.5.0] - Phase 5 (Settings, Local Backup & Data Safety)

### Added
- Local JSON backup export service (`BackupService`) with versioned schema (`college-attendance-tracker-backup` v1).
- Pure Dart multi-stage backup validation (`BackupValidator`) verifying referential integrity, date validity, and entity uniqueness.
- Atomic transactional restore replacing local data with confirmation modal (`BackupSummaryDialog`).
- Four-section `SettingsScreen` covering Semester Settings, App Preferences (Haptic Feedback), Local Backup & Restore, and Privacy/Offline notice.
- Abstracted `PlatformFileService` integrating `file_picker` and `share_plus` for local offline backup export and import.

---

## [0.4.0] - Phase 4 (Insights, Advanced Charts & Attendance Simulator)

### Added
- What-if Attendance Simulator isolated in-memory from the persistent SQLite database.
- Subject attendance comparison charts and Lecture vs Lab performance breakdowns.
- Attendance trend visualizer with date-range filters (All Time, Past 30 Days, Past 7 Days).
- Actionable automated insights with rule-based observations.

---

## [0.3.0] - Phase 3 (Dashboard & Attendance Calculations)

### Added
- Comprehensive attendance calculation engine supporting Raw Combined and Component Average (50/50).
- Safe absence calculator (`calculateSafeAbsences`) and recovery calculator (`calculateRecoverySessions`).
- Main Dashboard screen with hero attendance card, quick action dock, and subject preview rows.
- Semester switcher bottom sheet and active semester resolution provider.

---

## [0.2.0] - Phase 2 (Attendance Management)

### Added
- Quick Log bottom sheet for single-tap Present/Absent recording.
- Full attendance history screen with interactive monthly calendar and date-specific session list.
- Session editing and deletion with snackbar-driven undo mechanism.
- Unique session constraint enforcement preventing accidental duplicates.

---

## [0.1.0] - Phase 1 (Foundation & Architecture)

### Added
- Core architecture with Flutter, Riverpod, Drift (SQLite), and go_router.
- Pure soft pastel design system matching `DESIGN.md` (Violet `#9278F2`, Mint `#8BE4D0`, Coral `#FF929B`, Peach `#FFB49F`, Warm White `#FFFAF9`).
- Initial splash screen, onboarding flow, and semester setup screen.
- Drift database schema v1 with foreign-key support and date-only ISO strings.
