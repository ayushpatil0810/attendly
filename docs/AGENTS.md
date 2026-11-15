# AI Agent Working Conventions

**Product:** Student Attendance Tracker\
**Document status:** Baseline agent instructions\
**Version:** 1.0\
**Platform:** Flutter mobile application\
**Depends on:** All project documentation

------------------------------------------------------------------------

## 1. Purpose

This document provides mandatory operational instructions for AI coding agents and contributors working on the Student Attendance Tracker. 

The instructions in this document ensure consistency, prevent architectural drift, protect critical domain calculations, and enforce verified project decisions.

## 2. Mandatory document review before development

Before writing any Flutter code, defining database tables, adding packages, or modifying screens, you **must read all project documentation**:

1.  [`PRD.md`](file:///d:/attendly/docs/PRD.md) — Product requirements, student persona, core features, calculation rules, safe-absence and recovery formulas.
2.  [`SPEC.md`](file:///d:/attendly/docs/SPEC.md) — Detailed functional specification, user flows, validation rules, error/empty states, acceptance scenarios.
3.  [`TECH_STACK.md`](file:///d:/attendly/docs/TECH_STACK.md) — Approved technologies, dependency management rules, code generation, linting, CI.
4.  [`ARCHITECTURE.md`](file:///d:/attendly/docs/ARCHITECTURE.md) — Feature-first layered architecture, data flow, layer boundaries, repository pattern.
5.  [`DATABASE.md`](file:///d:/attendly/docs/DATABASE.md) — Drift/SQLite schema, table definitions, date-only storage, cascade behaviors, migrations, backup/restore.
6.  [`DESIGN.md`](file:///d:/attendly/docs/DESIGN.md) — Visual design system, color tokens, Plus Jakarta Sans typography, Hugeicons, floating dock, open layouts, motion.
7.  [`TESTING.md`](file:///d:/attendly/docs/TESTING.md) — Testing strategy, unit calculation tests, database tests, backup tests, release checklist.
8.  [`CHANGELOG.md`](file:///d:/attendly/docs/CHANGELOG.md) — Project change log, pre-release tracking, update conventions.
9.  [`AGENTS.md`](file:///d:/attendly/docs/AGENTS.md) — This document.

Do not guess requirements, invent undocumented features, or rely on outdated assumptions.

## 3. Core architectural rules (Non-negotiable)

### 3.1 100% Offline-only architecture

The application is strictly **offline-only**. All application data is stored locally on the user's device.

The following are strictly prohibited:
- **No Supabase** or Supabase Auth.
- **No Firebase** or Google Mobile Services dependencies.
- **No hosted backend** or remote web servers.
- **No remote database** (PostgreSQL, MySQL, etc.).
- **No user login, registration, or account management**.
- **No cloud synchronization** or multi-device sync protocols.
- **No background sync queues** or network retry mechanisms.
- **No remote API dependencies** for core application capabilities.
- **No transmission of student attendance records** to external analytics or telemetry services.

### 3.2 Approved technology stack

Only use the approved tech stack:
- **Framework:** Flutter (stable channel).
- **Language:** Dart.
- **State Management & DI:** Riverpod (`flutter_riverpod`).
- **Routing & Navigation:** `go_router`.
- **Local Persistence:** Drift with SQLite (`sqlite3_flutter_libs`).
- **Data Models:** Typed Dart classes with `freezed` and `json_serializable` where appropriate.
- **Formatting:** `intl`.
- **Calendar UI:** `table_calendar`.
- **Charts:** `fl_chart`.
- **Icons:** `hugeicons`.
- **Typography:** Plus Jakarta Sans (bundled locally).
- **Testing:** `flutter_test`, `mocktail`, `integration_test`.

Do not introduce alternative state management (`Bloc`, `GetX`, `Provider`), navigation packages, or database solutions (`Hive`, `Isar`, `ObjectBox`, `shared_preferences` for relational data).

### 3.3 Layer responsibilities and dependency direction

Follow the feature-first layered architecture:

``` text
UI (Presentation) → Riverpod Providers → Domain / Use Cases → Repository Contracts
                                                                     ↑
Data Implementations (Drift / SQLite / Local Backup) ────────────────┘
```

1. **Presentation Layer:** Widgets display data and dispatch user actions. **No attendance math or SQL queries in widgets.**
2. **Application / State Layer:** Riverpod Notifiers/Providers coordinate user interactions and reactive state.
3. **Domain Layer:** Pure Dart entities, use cases, and calculation services. Independent of Flutter and database packages.
4. **Data Layer:** Drift DAOs, database tables, and repository implementations. Converts low-level rows into domain entities.
5. **Persistence Source:** Drift/SQLite is the sole persistence source.

## 4. Product & attendance calculation rules

You must strictly preserve all functional and calculation requirements:

### 4.1 Attendance sessions

- An attendance session represents a class that **actually took place** and was explicitly recorded.
- Valid recorded statuses are **`present`** and **`absent`**.
- Unrecorded classes must **NEVER** be counted or interpreted as absences. No session record means no class data exists.
- Lecture and Lab components must be tracked independently.
- Multiple sessions on the same date for the same subject/component are supported.
- Historical attendance logging, editing, and deletion must be fully supported via the calendar/history section.

### 4.2 Calculation methods

Both calculation methods must be implemented in shared, pure Dart domain services:

1. **Method 1: Raw Combined**
   $$\text{Attendance \%} = \frac{\text{Total Present Sessions}}{\text{Total Conducted Sessions}} \times 100$$
   Every conducted lecture and lab session carries equal weight. If conducted sessions $= 0$, attendance is **Not available** (never $0\%$).

2. **Method 2: Component Average (50/50)**
   $$\text{Lecture \%} = \frac{\text{Lecture Present}}{\text{Lecture Conducted}} \times 100$$
   $$\text{Lab \%} = \frac{\text{Lab Present}}{\text{Lab Conducted}} \times 100$$
   $$\text{Combined Attendance \%} = \frac{\text{Lecture \%} + \text{Lab \%}}{2}$$
   - If only one component is enabled, use that component's percentage.
   - If both components are enabled but one has zero conducted sessions: Combined attendance is **Not available**. The component with data is shown as **provisional**. Never treat the missing component as $0\%$ or $100\%$.

### 4.3 Safe absences and recovery

- **Raw Combined safe absences** (when at or above threshold $t$ as decimal):
  $$\max\left(0, \left\lfloor \frac{A}{t} - C \right\rfloor\right)$$
  Verify that $A / (C + x) \ge t$ and $A / (C + x + 1) < t$. When below threshold, safe absences $= 0$.
- **Raw Combined recovery** (when below threshold and $t < 1$):
  $$\left\lceil \frac{t \times C - A}{1 - t} \right\rceil$$
  Consecutive attended sessions assuming zero future absences. If threshold $= 100\%$ and an absence exists, recovery is impossible through attendance alone.
- **Component Average:** Never display a single generic safe absence or recovery number without an explicit future Lecture/Lab mix. Guide the user to the What-if Simulator.

### 4.4 What-if simulator

- Allows modeling hypothetical future sessions (Present/Absent for Lecture/Lab).
- Calculates projected attendance using the semester's calculation method.
- **Simulator data must NEVER be persisted or modify actual attendance records.**

## 5. Local backup and restore

Because there is no cloud sync, local backup and restore protect against device loss or data migration:

- Manual **Export Backup** to a user-selected local file path.
- Manual **Import/Restore Backup** from a user-selected local file.
- Documented, versioned JSON format (`college-attendance-tracker-backup`).
- Complete validation of format version, schema, constraints, and relational references before altering the database.
- Transactional restore: if any record fails, the entire restore rolls back leaving current data intact.
- Explicit confirmation before replacing existing local data.
- Never silently upload backups to external endpoints.

## 6. Design system standards

Follow the visual and interaction standards in [`DESIGN.md`](file:///d:/attendly/docs/DESIGN.md):

- **Theme:** Light theme only for initial release.
- **Background:** White (`#FFFFFF`) / warm-white (`#FFFAF9`) primary surfaces.
- **Palette:** Violet (`#9278F2`), Mint (`#8BE4D0`), Coral (`#FF929B`), Peach (`#FFB49F`), Ink (`#30263F`).
- **Typography:** Plus Jakarta Sans font bundled locally.
- **Iconography:** Hugeicons only. Do not mix with Material icons or FontAwesome.
- **Navigation:** Floating bottom navigation dock with central Quick Log action.
- **Open Layouts:** **Do not put everything inside cards or rectangles.** Use whitespace, typography, alignment, and subtle dividers. Avoid generic AI-template card grids.
- **Avoid Stock Material Styling:** Do not use default Material 3 component appearances. Custom-theme or build components matching the design system.
- **Attendance Logging UX:** Immediate save upon selecting Present/Absent with an actionable Undo snackbar. No separate submit button for daily logging.
- **Branding:** App name, logo, and launcher icon are **intentionally undecided**. Do not finalize branding.

## 7. Development and testing rules

### 7.1 Code quality

- Use `dart format` for all code.
- Ensure strict static analysis with `flutter analyze` (`flutter_lints`).
- Resolve all analyzer warnings and errors.
- Never suppress lints globally.

### 7.2 Testing requirements

- **Unit tests:** Test all attendance formulas, boundaries, safe absences, recovery, and simulator logic in pure Dart domain tests (`test/features/attendance/domain/`).
- **Database tests:** Test Drift CRUD, date-only persistence, constraints, foreign-key cascades, and migrations (`test/core/database/`).
- **Backup tests:** Test backup serialization, schema validation, corruption rejection, and transactional rollback (`test/core/backup/`).
- **Widget tests:** Test UI interactions, loading/empty/error states, form validations, and immediate save with Undo.
- **Integration tests:** Test end-to-end user journeys on emulator/device.

### 7.3 Database migrations

- Increment Drift `schemaVersion` for every table change.
- Write explicit, forward-compatible migration strategies.
- Never drop or recreate tables destructively for production updates.
- Test migrations against populated databases.

## 8. What NOT to do (Strict constraints)

- **DO NOT** introduce any cloud, server, or network dependency.
- **DO NOT** introduce authentication, user registration, or accounts.
- **DO NOT** modify or simplify the attendance calculation formulas.
- **DO NOT** treat unrecorded days or classes as absences.
- **DO NOT** persist derived attendance percentages in the database.
- **DO NOT** let simulator inputs leak into real database records.
- **DO NOT** invent new product features outside the PRD/SPEC scope.
- **DO NOT** create a dark theme (it is deferred).
- **DO NOT** finalize the application branding, logo, or icon.
- **DO NOT** add unapproved dependencies to `pubspec.yaml`.

## 9. Quality gates checklist

Before declaring any feature complete:

- [ ] Requirements match `PRD.md` and `SPEC.md`.
- [ ] Layer boundaries follow `ARCHITECTURE.md`.
- [ ] Database interactions go through Drift repositories (`DATABASE.md`).
- [ ] Calculation logic is shared in the domain layer and tested (`TESTING.md`).
- [ ] UI matches `DESIGN.md` (Plus Jakarta Sans, Hugeicons, light palette, open composition).
- [ ] All unit, widget, and repository tests pass.
- [ ] `dart format` and `flutter analyze` pass cleanly.
- [ ] Changes are documented in `CHANGELOG.md`.
- [ ] The feature operates 100% offline.
