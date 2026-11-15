# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Individual college and university students managing their personal attendance across academic semesters. Students who need to stay above mandatory attendance thresholds (typically 75% or 80%) to maintain exam eligibility, avoid academic penalties, or make informed decisions about when they can safely take an absence.

## Product Purpose

Attendly exists to give college students accurate, private, and effortless control over their course attendance. Success means a student can log a session in less than three seconds, immediately see their exact status against their university threshold, know precisely how many classes they can safely miss (or need to attend for recovery), and trust that their data is 100% private and offline on their personal device.

## Positioning

Unlike institutional attendance systems (which focus on surveillance, geofencing, or administrative compliance) and generic timetable apps (which require rigid weekly schedules and assume unattended classes were absences), Attendly is an autonomous, student-first attendance companion. It records only classes that actually took place, tracks Lecture and Lab independently, and provides mathematically honest safe absence and recovery calculations under both Raw Combined and Component Average (50/50) university policies.

## Operating Context

- Used in classrooms, lecture halls, campus corridors, and dorm rooms right after class concludes or at the end of the day.
- Fast, one-handed thumb-driven interactions between classes.
- Offline-first: zero requirement for campus Wi-Fi, cellular connectivity, or server uptime.
- Operates on personal smartphones and tablets across Android and iOS with native responsive adaptations.

## Capabilities and Constraints

- **Capabilities:**
  - Semester lifecycle: creation, active switcher, threshold setting (default 75%), calculation method selection, and archiving.
  - Subject management: independent toggle for Lecture and Lab components per course.
  - Fast session logging: Present / Absent marking with immediate save, duplicate tap protection, and single-tap Undo snackbar.
  - Calendar & History: interactive date picker to review, correct, edit, or delete past sessions.
  - Safe Absence calculation: exact count of classes a student can miss without dropping below threshold.
  - Recovery calculation: exact number of consecutive attended classes required to reach threshold.
  - What-If Attendance Simulator: sandbox mode to simulate hypothetical future classes without corrupting real records.
  - Local Backup & Restore: export and import complete database snapshots as structured, versioned JSON files.
- **Technical Constraints:**
  - Offline-only architecture powered by local SQLite (via Drift) and SharedPreferences.
  - Zero remote APIs, analytics tracking, cloud sync, or external server dependencies.
  - Pure Dart/Flutter codebase with Riverpod for state management and GoRouter for declarative routing.
- **Terminology:**
  - **Semester:** Academic term grouping subjects and rules.
  - **Subject:** An enrolled course.
  - **Component:** Lecture or Lab meeting type.
  - **Session:** A single class meeting that actually took place.
  - **Conducted Session:** A recorded session marked Present or Absent.
  - **Unrecorded Session:** A class that has not been entered; strictly never counted as an absence.

## Brand Commitments

- **Name:** Attendly
- **Atmosphere:** Soft pastel modern minimalism, clean, youthful, approachable, and clutter-free (guided by docs/DESIGN.md).
- **Palette:** Violet (`#9278F2`), Mint (`#8BE4D0`), Coral (`#FF929B`), Peach (`#FFB49F`), Soft Lavender (`#F5F1FF`), Warm White (`#FFFAF9`), and Ink (`#30263F`).
- **Typography:** Plus Jakarta Sans with tabular figures for changing numbers.
- **Iconography:** Exclusively HugeIcons stroke rounded set.

## Evidence on Hand

- Functional mobile app implementation in `lib/` with 194 passing automated tests in `test/`.
- Comprehensive architectural and functional documentation in `docs/PRD.md`, `docs/SPEC.md`, `docs/DESIGN.md`, `docs/ARCHITECTURE.md`, `docs/TECH_STACK.md`, and `docs/DATABASE.md`.
- Vector app assets and launcher icons in `assets/` and native directories.

## Product Principles

1. **Actual sessions only:** An unrecorded class is never assumed to be an absence. Only classes marked Present or Absent factor into calculations.
2. **Speed and one-handed reach:** Daily logging must take under three seconds with large touch targets and instant Undo feedback.
3. **Mathematical honesty:** Projections, percentages, and safe absence quotas clearly state their underlying policy and assumptions. No fake certainty.
4. **Absolute local privacy:** The student's academic standing and attendance history belong solely to them, stored securely on device with manual JSON export.
5. **No timetable lock-in:** The app does not demand rigid recurring weekly schedules or break when classes are cancelled, rescheduled, or substituted.

## Accessibility & Inclusion

- Minimum touch target size of 44×44px (48×48px where achievable) across all primary interactive controls.
- Screen reader semantics on all metrics, badges, hero percentages, and interactive cards for TalkBack and VoiceOver.
- Tabular numerals across all data columns to eliminate layout shift.
- WCAG AA contrast compliance across all text and badge combinations against light tinted surfaces.
