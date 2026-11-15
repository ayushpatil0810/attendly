# Application Architecture

**Product:** Student Attendance Tracker\
**Document status:** Baseline architecture decisions\
**Version:** 2.0\
**Depends on:** `PRD.md`, `SPEC.md`, `TECH_STACK.md`

------------------------------------------------------------------------

## 1. Purpose

This document defines the structural design of the Flutter application:
its layers, feature boundaries, dependency direction, data flow,
persistence responsibilities, and integration points.

The architecture must keep attendance rules consistent, make the
application testable, and support reliable local-only use.

This is a practical feature-first architecture with clear domain and
data boundaries. It is not intended to introduce unnecessary
abstractions or a large enterprise framework.

## 2. Architectural decisions

  Concern                          Decision
  -------------------------------- -------------------------------------------------
  Overall style                    Feature-first, layered architecture
  UI                               Flutter presentation layer
  State and dependency injection   Riverpod
  Navigation                       go_router
  Business rules                   Domain layer, independent of Flutter UI
  Data access                      Repository interfaces and implementations
  Local persistence                Drift / SQLite (sole persistence source)
  Attendance calculations          Shared domain services/use cases
  Testing                          Unit, repository, widget, and integration tests

### Key principles

1.  UI widgets do not contain business rules or database queries.
2.  Attendance calculations exist in one shared domain implementation.
3.  The domain layer does not depend on Flutter or Drift.
4.  Features access data through repository interfaces.
5.  Local persistence is the sole data source for the application.
6.  The application is fully offline-only; there is no remote backend,
    cloud sync, or authentication service.
7.  Derived attendance values are calculated from session records and
    semester settings.
8.  Use the simplest design that meets the requirements; do not add
    abstractions without a concrete need.

## 3. High-level architecture

``` mermaid
flowchart TD
    UI[Flutter UI / Screens / Widgets]
    STATE[Riverpod Providers and Notifiers]
    USE[Domain Use Cases and Services]
    REPO[Repository Interfaces]
    IMPL[Repository Implementations]
    LOCAL[Drift Local Database]

    UI --> STATE
    STATE --> USE
    USE --> REPO
    REPO --> IMPL
    IMPL --> LOCAL
```

The diagram represents logical responsibilities. All data is persisted
locally; there is no remote backend or authentication layer.

### Dependency direction

``` text
Presentation → Application/Domain → Repository contracts
                                      ↑
Data implementations ─────────────────┘
```

-   Presentation depends on application/domain APIs.
-   Application/domain depends on repository abstractions.
-   Data implementations satisfy those abstractions.
-   Domain code must not import Flutter widgets, Drift generated code,
    or UI packages.
-   Data code may depend on domain models and repository contracts.
-   Avoid circular feature dependencies.

## 4. Recommended project structure

Use a feature-first layout. Shared infrastructure belongs in `core`;
product capabilities belong in `features`.

``` text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   └── bootstrap/
│       └── app_bootstrap.dart
│
├── core/
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   └── migrations/
│   ├── backup/
│   │   ├── backup_service.dart
│   │   └── backup_format.dart
│   ├── errors/
│   ├── utils/
│   └── shared/
│       ├── widgets/
│       └── formatters/
│
├── features/
│   ├── semesters/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── use_cases/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── subjects/
│   │   └── [same domain/data/presentation structure]
│   │
│   ├── attendance/
│   │   └── [same domain/data/presentation structure]
│   │
│   ├── calendar/
│   │   └── [same domain/data/presentation structure]
│   │
│   ├── analytics/
│   │   └── [same domain/data/presentation structure]
│   │
│   ├── simulator/
│   │   └── [same domain/data/presentation structure]
│   │
│   └── settings/
│       └── [same domain/data/presentation structure]
│
└── generated/
    └── [generated files only, if project tooling requires this]
```

The repeated `[same ... structure]` notation is explanatory, not a
literal folder name.

### Folder responsibilities

-   `app/`: Application startup, app widget, and route configuration.
-   `core/`: Infrastructure and genuinely reusable capabilities shared
    by multiple features.
-   `features/<feature>/domain/`: Entities, repository contracts,
    calculation rules, and use cases.
-   `features/<feature>/data/`: Drift data sources, data
    models, mapping, and repository implementations.
-   `features/<feature>/presentation/`: Screens, feature widgets, and
    Riverpod state.
-   `generated/`: Only generated artifacts if a selected tool requires a
    centralized generated directory. Otherwise generated files stay
    beside their source according to package conventions.

Do not create empty folders for every possible layer. Add files and
subfolders when a feature needs them.

## 5. Feature boundaries

### 5.1 Semesters

Owns: - Semester creation, editing, selection, and archiving. -
Attendance threshold. - Calculation method. - Semester lifecycle state.

Does not own: - Attendance percentage formulas. - Session persistence
implementation. - Calendar rendering.

### 5.2 Subjects

Owns: - Subject creation, editing, and archiving. - Enabled Lecture/Lab
components. - Subject validation.

Does not own: - Attendance calculations. - Session status transitions.

### 5.3 Attendance

Owns: - Creating, editing, and deleting actual sessions. - Session
validation. - Attendance domain calculations. - Overall, subject, and
component attendance summaries. - Safe-absence and recovery
calculations.

This is the authoritative home for attendance business rules. Dashboard,
analytics, subject detail, and simulator must reuse these domain
services.

### 5.4 Calendar

Owns: - Calendar navigation and selected date state. - Querying sessions
for a date or date range. - Calendar presentation indicators derived
from attendance records.

Does not own: - Attendance status meaning. - Attendance calculations. -
Assumptions about unrecorded dates.

### 5.5 Analytics

Owns: - Preparing time-grouped and comparison views from domain
summaries. - Analytics presentation and chart state.

Does not own: - Independent attendance formulas. - Persisted attendance
totals.

### 5.6 Simulator

Owns: - Temporary hypothetical sessions. - Scenario editing and reset. -
Projected attendance presentation.

Uses the same attendance calculation services as actual attendance. It
must not save simulated sessions through the actual attendance
repository.

### 5.7 Settings

Owns app-level preferences and settings that are not semester domain
data. Semester threshold and calculation method remain part of the
semester and are managed by the Semesters feature.

## 6. Domain model relationships

``` mermaid
erDiagram
    SEMESTER ||--o{ SUBJECT : contains
    SUBJECT ||--o{ ATTENDANCE_SESSION : has

    SEMESTER {
        uuid id
        string name
        decimal threshold
        string calculation_method
        string status
    }
    SUBJECT {
        uuid id
        uuid semester_id
        string name
        boolean lecture_enabled
        boolean lab_enabled
        string status
    }
    ATTENDANCE_SESSION {
        uuid id
        uuid subject_id
        date session_date
        string component
        string status
        datetime created_at
        datetime updated_at
    }
```

This is a conceptual relationship diagram. The exact local schema,
indexes, foreign keys, and constraints are defined in `DATABASE.md`.

### Domain entities

**Semester** - ID - Name - Attendance threshold - Calculation method -
Lifecycle status

**Subject** - ID - Semester ID - Name - Lecture enabled - Lab enabled -
Lifecycle status

**AttendanceSession** - ID - Subject ID - Session date - Component -
Status - Creation and update timestamps

**AttendanceSummary** - Derived result, not an authoritative persisted
attendance record. - May include attended count, conducted count,
percentage availability, percentage, threshold status, and component
summaries.

**AttendanceScenario** - Temporary in-memory collection of hypothetical
sessions and projected results. - Must remain separate from persisted
actual sessions.

## 7. Repository pattern

Features define repository contracts in their domain layer. Data-layer
implementations provide the actual persistence.

Example conceptual contracts:

``` dart
abstract interface class SemesterRepository {
  Future<List<Semester>> getSemesters();
  Future<Semester?> getSemesterById(String id);
  Future<void> createSemester(Semester semester);
  Future<void> updateSemester(Semester semester);
  Future<void> archiveSemester(String id);
}

abstract interface class SubjectRepository {
  Future<List<Subject>> getSubjects(String semesterId);
  Future<void> createSubject(Subject subject);
  Future<void> updateSubject(Subject subject);
  Future<void> archiveSubject(String id);
}

abstract interface class AttendanceRepository {
  Future<List<AttendanceSession>> getSessionsForDate(
    String semesterId,
    DateTime date,
  );

  Future<List<AttendanceSession>> getSessionsForRange(
    String semesterId,
    DateTime start,
    DateTime end,
  );

  Future<void> createSession(AttendanceSession session);
  Future<void> updateSession(AttendanceSession session);
  Future<void> deleteSession(String sessionId);
}
```

These are illustrative contracts. Final method signatures and ID/date
types must match the domain models and database decisions.

### Repository rules

-   UI and widgets must not call Drift directly.
-   Repositories return typed domain data, not raw SQL rows.
-   Repository implementations handle mapping and persistence errors.
-   Use transactions for multi-record operations.
-   Prefer streams/watch queries for data that should update reactively;
    use one-shot futures for commands or one-time reads.
-   Do not create a repository for every class or helper. Use
    repositories around meaningful domain data boundaries.

## 8. Attendance calculation architecture

All attendance math must be implemented in shared, pure Dart domain
logic.

Recommended responsibilities:

``` text
attendance/domain/
├── entities/
│   ├── attendance_session.dart
│   ├── attendance_summary.dart
│   └── attendance_scenario.dart
├── repositories/
│   └── attendance_repository.dart
├── services/
│   ├── attendance_calculator.dart
│   ├── safe_absence_calculator.dart
│   ├── recovery_calculator.dart
│   └── scenario_calculator.dart
└── use_cases/
    ├── record_attendance_session.dart
    ├── update_attendance_session.dart
    ├── delete_attendance_session.dart
    ├── get_attendance_summary.dart
    └── simulate_attendance_scenario.dart
```

### Calculation responsibilities

-   `AttendanceCalculator`: Raw Combined and Component Average
    percentages, component availability, and threshold status.
-   `SafeAbsenceCalculator`: Safe absence results under the selected
    method and explicit future-session assumptions.
-   `RecoveryCalculator`: Required consecutive attendance under
    supported assumptions.
-   `ScenarioCalculator`: Apply hypothetical sessions to a baseline
    without persisting them.

The exact formulas and edge cases are defined in `SPEC.md`. This
architecture does not redefine them.

### Critical rules

-   Use exact unrounded values for comparisons.
-   Do not duplicate formulas in Riverpod providers or widgets.
-   Do not persist attendance percentages as the source of truth.
-   Simulator calculations must call the same calculation services as
    real attendance.
-   Every projection must carry its assumptions.
-   Return an explicit not-available/provisional state rather than
    inventing a percentage.

## 9. Application and state flow

Riverpod coordinates state and dependencies. It is not the location for
complex domain formulas.

### Read flow

``` mermaid
sequenceDiagram
    participant UI as Screen
    participant P as Riverpod Provider
    participant UC as Use Case
    participant R as Repository
    participant DB as Drift

    UI->>P: Watch dashboard state
    P->>UC: Request attendance summary
    UC->>R: Load semester, subjects, sessions
    R->>DB: Query local database
    DB-->>R: Local records
    R-->>UC: Typed domain data
    UC-->>P: Derived attendance summary
    P-->>UI: Loading / data / error
```

### Write flow

``` mermaid
sequenceDiagram
    participant UI as Screen
    participant N as Riverpod Notifier
    participant UC as Use Case
    participant R as Repository
    participant DB as Drift

    UI->>N: Save session command
    N->>UC: Validate and record session
    UC->>R: Create session
    R->>DB: Insert in transaction
    DB-->>R: Commit result
    R-->>UC: Success
    UC-->>N: Success
    N-->>UI: Updated state
```

### State management rules

-   Use Riverpod providers for dependency access and reactive reads.
-   Use Notifiers/AsyncNotifiers for feature actions and state
    transitions where appropriate.
-   Represent loading, data, and error states explicitly.
-   Keep transient UI state (such as an open dialog or selected tab)
    local to the widget when it does not need to be shared.
-   Keep selected semester state in a shared application-level provider
    because multiple features depend on it.
-   Avoid storing duplicate copies of the same database entity in
    multiple unrelated providers.
-   After a write, update through reactive database queries or
    invalidate the relevant providers. Do not manually patch several
    unrelated screens with separate copies of attendance math.

## 10. Local data flow

The local database is the sole persistence path.

``` mermaid
flowchart TD
    ACTION[User records or edits attendance]
    VALIDATE[Domain validation]
    WRITE[Write to Drift]
    COMMIT[Local transaction committed]
    UI[Reactive UI updates]

    ACTION --> VALIDATE --> WRITE --> COMMIT
    COMMIT --> UI
```

### Local write rules

-   A local write must complete before the UI reports that the
    attendance record is saved.
-   If local persistence fails, do not report success.
-   Use stable IDs so records can be reliably referenced and exported.

## 11. Backup and export architecture

Backup and export is an infrastructure capability in the core layer,
not a screen-specific feature.

### Responsibilities

The `BackupService` in `core/backup/` is responsible for:
-   Exporting all application data to a versioned JSON format.
-   Importing data from a previously exported JSON backup.
-   Restoring data within a database transaction to ensure consistency.
-   Validating backup file format and version before import.

### Backup boundaries

-   The backup service uses repository interfaces to read and write
    domain data. It does not access Drift tables directly.
-   The `BackupFormat` defines the versioned JSON schema for exports,
    including a version identifier, export timestamp, and all domain
    entities.
-   Import must validate referential integrity (e.g., every subject
    references an existing semester in the backup) before committing.
-   Export and import operations run within database transactions so
    that a failure leaves the database unchanged.
-   The Settings feature provides the UI entry point for triggering
    backup export and import. The core backup service owns the logic.

### Backup rules

-   Do not silently overwrite existing data on import without user
    confirmation.
-   Include a format version in every export so future versions can
    migrate older backups.
-   Do not include derived values (percentages, summaries) in the
    export; they are recalculated from raw session data on import.
-   Test backup round-trips: export then import must produce an
    identical data set.

## 12. Error handling

Use typed application/domain failures for expected conditions, such
as: - Validation failure. - Entity not found. - Archived entity cannot
receive new sessions. - Local persistence failure.

Rules: - Convert low-level Drift exceptions at the data boundary. - Do
not expose raw database exception text to users. - Preserve diagnostic
context for development without logging secrets or attendance details
unnecessarily. - UI maps expected failures to clear user-facing messages
and recovery actions.

## 13. Date and time boundaries

-   Attendance sessions represent a calendar date, not a precise class
    start time.
-   Store and compare session dates consistently as date-only values.
-   Do not apply UTC conversion that changes the selected calendar day.
-   Audit timestamps are UTC instants.
-   Date range queries must use inclusive/exclusive boundaries
    consistently and be tested at month/year boundaries.
-   The date displayed to the user follows the device's local calendar
    context.

## 14. Testing architecture

### Domain tests

Test pure domain behavior without Flutter or Drift: - Both
attendance methods. - Empty and provisional component states. -
Threshold comparisons. - Safe absences. - Recovery calculations. -
Scenario calculations. - Validation rules.

### Repository tests

Test: - Domain-to-database mapping. - Drift persistence. -
Transactions. - Historical session queries. - Multiple same-day
sessions. - Edit and delete behavior. - Migrations.

### Provider tests

Test: - Loading, data, and error states. - Selected semester changes. -
Provider refresh after writes. - Repository error propagation. -
Scenario state isolation.

### Widget tests

Test screen behavior and user interaction, not the calculation formulas
themselves.

### Integration tests

Test critical end-to-end flows: - Create semester and subject. - Record
a session. - Edit a historical session. - View updated dashboard. - Run
a scenario without changing actual records. - Export and re-import a
backup.

## 15. Architecture rules for contributors and AI agents

1.  Do not put database queries in widgets.
2.  Do not put attendance formulas in screens, providers, or chart
    builders.
3.  Do not introduce a second state-management, routing, or database
    framework.
4.  Do not make the domain layer depend on Flutter or data-layer
    packages.
5.  Do not persist derived percentages as authoritative attendance
    records.
6.  Do not treat missing session records as absences.
7.  Do not let simulator sessions reach the actual attendance
    repository.
8.  Do not create cross-feature circular dependencies.
9.  Do not add generic base classes, service locators, or abstractions
    without a concrete use case.
10. Keep changes within the owning feature unless a shared domain or
    core responsibility genuinely requires a change.
11. Update tests and relevant documentation when architecture or
    behavior changes.

## 16. Architecture decision boundaries

The following are intentionally deferred:

-   Exact Drift tables, indexes, constraints, and migrations:
    `DATABASE.md`.
-   Exact colors, typography, spacing, responsive layouts, and component
    styling: `DESIGN.md`.
-   Exact package versions and environment setup: `TECH_STACK.md`.
-   Agent workflow, command policy, and change protocol: `AGENTS.md`.
-   Release signing and deployment pipeline: developer/release
    documentation.

------------------------------------------------------------------------

**Non-negotiable architecture rule:** The attendance domain is the
single source of truth for attendance meaning and calculations. Every
screen, report, and simulator must use it. Local persistence is the
sole data source. The application is offline-only; there is no remote
backend, cloud synchronization, or authentication service.
