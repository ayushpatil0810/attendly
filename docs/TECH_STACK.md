# Technical Stack

**Product:** Student Attendance Tracker\
**Document status:** Baseline technical decisions\
**Version:** 1.1\
**Platform:** Flutter mobile application\
**Depends on:** `PRD.md`, `SPEC.md`

------------------------------------------------------------------------

## 1. Purpose

This document defines the approved technologies and technical
conventions for implementing the Student Attendance Tracker.

It is intended to prevent AI coding agents and contributors from
independently choosing competing libraries or introducing unnecessary
dependencies.

The stack prioritizes: - A maintainable Flutter codebase. - Reliable
attendance data and calculations. - Offline attendance logging. -
Local data backup and restore. - Testable
business logic. - A small, practical dependency set.

## 2. Stack overview

  -----------------------------------------------------------------------
  Area                                Selected technology
  ----------------------------------- -----------------------------------
  Mobile framework                    Flutter, stable channel

  Language                            Dart, version bundled with selected
                                      Flutter SDK

  State management                    Riverpod (`flutter_riverpod`)

  Navigation                          `go_router`

  Local database                      Drift (SQLite)

  Data models / serialization         Dart models with `freezed` and
                                      `json_serializable` where useful

  Date and number formatting          `intl`

  Calendar UI                         `table_calendar`

  Charts                              `fl_chart`

  Unit and widget testing             Flutter test framework

  Mocking                             `mocktail`

  Static analysis                     Dart analyzer + `flutter_lints`

  CI                                  GitHub Actions

  Local file picking & export         `file_picker` & `share_plus`
  -----------------------------------------------------------------------

**Version policy:** Use the latest mutually compatible stable
Flutter/Dart SDK and package releases at project initialization. Pin the
Flutter SDK and all direct dependencies in the repository. Commit
`pubspec.lock` for the application. Do not use beta, dev, or dependency
override versions without an explicit documented reason.

Do not copy package version numbers from old AI-generated examples.
Verify current compatibility with the selected Flutter SDK before adding
or upgrading a package.

## 3. Flutter and Dart

### Decision

-   Build the application in Flutter.
-   Use Dart only for application code.
-   Target Android first while keeping the codebase compatible with iOS.
-   Use the stable Flutter channel.
-   Keep the Flutter SDK version pinned for local development and CI.

### Rules

-   Do not mix native Android/iOS application logic into the codebase
    unless a required platform capability cannot be implemented through
    Flutter packages.
-   Platform-specific code must be isolated behind a small interface.
-   Keep platform configuration and signing secrets out of source
    control.
-   Do not upgrade Flutter or Dart as an incidental part of an unrelated
    feature.

## 4. State management --- Riverpod

### Decision

Use `flutter_riverpod` for application state and dependency management.

### Responsibilities

Riverpod should manage: - Selected semester. - Semester and subject
lists. - Attendance session data. - Derived attendance summaries. -
Dashboard and analytics state. - Simulator state. - Loading and error
state. - Repository and service dependencies.

### Rules

-   UI widgets must not contain attendance calculation formulas.
-   Widgets should read state and invoke application actions.
-   Keep business logic in testable providers, services, or domain use
    cases.
-   Avoid global mutable variables and manually managed singleton state.
-   Use the current recommended Riverpod APIs consistently; do not mix
    multiple state-management systems.
-   Do not introduce `Provider`, `Bloc`, `GetX`, or another
    state-management framework alongside Riverpod.

## 5. Navigation --- go_router

### Decision

Use `go_router` for declarative navigation.

### Responsibilities

-   Primary app navigation.
-   Nested routes where needed.
-   Passing stable entity identifiers between screens.
-   Handling unknown or invalid routes.

### Rules

-   Pass IDs or small route parameters, not entire mutable database
    objects.
-   A destination screen must load the latest entity state through its
    repository/provider.
-   Keep route definitions in a centralized routing module.
-   Do not introduce a second navigation package.

## 6. Local persistence --- Drift / SQLite

### Decision

Use Drift as the local relational database.

Attendance is a relational domain: semesters contain subjects, and
subjects contain many sessions. SQLite provides transactions,
constraints, and reliable local persistence.

### Responsibilities

Drift stores: - Local semester records. - Local subject records. -
Attendance sessions. - Any minimal app settings that need durable local
storage.

### Rules

-   The local database is the source used by the UI for immediate reads
    and writes.
-   Use database transactions for operations that must update multiple
    records together.
-   Define schema migrations for every schema change.
-   Never clear or recreate the production database merely to apply a
    schema update.
-   Keep generated Drift files generated by the documented build
    command; do not hand-edit generated output.
-   Store dates consistently as calendar dates for attendance, not as
    arbitrary UTC timestamps that can shift the day across time zones.
-   Store audit timestamps such as `created_at` and `updated_at` as UTC
    instants.
-   Do not store derived attendance percentages as authoritative
    records. Derive them from sessions and semester configuration.

### Date representation

Attendance is associated with a local calendar date. Persist the date as
a date-only value or a normalized representation such as `YYYY-MM-DD`.

Do not convert an attendance date through UTC in a way that can move it
to the previous or next day.

Audit timestamps are separate from the attendance date and should be
stored in UTC.

## 7. Offline-only architecture

### Decision

The application is fully offline. All data is stored locally on-device
using Drift/SQLite. There is no remote backend, no cloud
synchronization, and no user authentication.

### Data safety

-   Provide a local backup and restore mechanism (versioned JSON
    file export/import) so the user can safeguard their data or migrate
    to a new device.
-   Backup files are self-contained and portable.
-   `file_picker` (13.3.3) provides local file picking for backup import and platform save dialogs.
-   `share_plus` (13.3.1) integrates with the platform-native share sheet for offline local backup export without external network access.

### Rules

-   Do not add any remote networking, cloud database, or authentication
    dependency.
-   Do not design data models or schemas around future synchronization
    unless explicitly revisited in a later decision document.
-   The app must function fully without any network connection at all
    times.

## 8. Data models and serialization

### Decision

Use explicit Dart domain models. Use `freezed` and `json_serializable`
for immutable models and serialization where they reduce boilerplate and
improve safety.

### Rules

-   Keep domain concepts independent of Flutter widgets.
-   Convert database records into typed models at repository boundaries.
-   Validate data at application boundaries.
-   Generated files must be regenerated using the documented build
    command.
-   Do not add code generation for trivial classes if it creates
    unnecessary complexity.

Core entities: - `Semester` - `Subject` - `AttendanceSession` -
`AttendanceSummary` (derived, not authoritative persisted attendance) -
`AttendanceScenario` (temporary simulation state)

Enums: - `AttendanceCalculationMethod`: `rawCombined`,
`componentAverage` - `SessionComponent`: `lecture`, `lab` -
`AttendanceStatus`: `present`, `absent` - `SemesterStatus`: active,
archived - `AttendanceAvailability`: available, provisional,
notAvailable

Persisted enum values must be stable and explicitly mapped. Do not rely
on enum declaration order.

## 9. Date, time, and formatting

### Decision

Use `intl` for locale-aware date, number, and percentage formatting.

### Rules

-   Attendance dates are date-only values.
-   Use the device's local calendar context for date selection and
    display.
-   Use UTC for audit timestamps.
-   Do not hardcode date strings or number formatting in multiple
    screens.
-   Keep date and percentage formatting in shared presentation
    utilities.
-   Calculations use unrounded numeric values; formatting is
    display-only.

## 10. Calendar and chart libraries

### Calendar --- table_calendar

Use `table_calendar` for month navigation and date selection if its
current stable version meets the supported Flutter SDK requirements.

The app owns the meaning of calendar indicators. The calendar package
must not infer attendance status or treat missing records as absences.

### Charts --- fl_chart

Use `fl_chart` for charts where a chart improves understanding, such
as: - Attendance trend over time. - Subject comparison. - Lecture versus
Lab comparison.

Rules: - Do not use charts for information better represented as a
simple number or list. - Provide accessible text summaries alongside
charts. - Charts must use derived domain data, not calculate attendance
themselves. - Do not create misleading trend points for dates with no
recorded sessions.

## 11. Testing stack

Use Flutter's built-in test tooling.

### Unit tests

Required for: - Raw Combined calculations. - Component Average
calculations. - Safe-absence calculations. - Recovery calculations. -
Threshold boundaries. - Empty and provisional states. - Scenario
projections. - Domain validation.

### Repository and database tests

Required for: - Create, read, update, and delete operations. - Drift
persistence. - Database migrations. - Transaction behavior. - Session
uniqueness assumptions and multiple same-day sessions.

### Widget tests

Required for: - Main user flows. - Form validation. - Empty, loading,
and error states. - Attendance status display. - Dashboard and subject
summaries. - Simulator interaction.

### Integration tests

Use `integration_test` for critical end-to-end flows on supported target
platforms.

Use `mocktail` for mocks and fakes where appropriate. Prefer testing
real calculation logic rather than mocking the behavior under test.

## 12. Code quality and developer tooling

### Static analysis

Use: - Dart analyzer. - `flutter_lints`. - Formatting with
`dart format`.

Rules: - Run formatting and static analysis before considering a task
complete. - Resolve analyzer errors. - Do not suppress lints broadly. -
Any targeted suppression must include a reason. - Keep dependencies
minimal and remove unused packages.

### Code generation

If using Drift, Freezed, or JSON serialization, use the standard Dart
build runner workflow.

Generated source files must not be manually edited.

### CI

Use GitHub Actions to run, at minimum: 1. Dependency resolution. 2. Dart
formatting check. 3. Static analysis. 4. Unit and widget tests. 5. Build
validation for the configured target platform(s), as practical.

CI must use the pinned Flutter SDK version.

## 13. Dependency management policy

Before adding a package: 1. Confirm that the feature is required by the
PRD or SPEC. 2. Check that the package supports the pinned Flutter/Dart
SDK. 3. Prefer well-maintained packages with stable releases. 4. Prefer
Flutter/Dart ecosystem packages over custom platform code when quality
is comparable. 5. Check license and transitive dependency implications.
6. Add the package only if it provides meaningful value.

Do not: - Add multiple packages that solve the same problem. - Add a
large UI framework for a small number of components. - Add analytics,
advertising, crash reporting, or tracking SDKs without an explicit
product/privacy decision. - Upgrade unrelated dependencies during
feature work. - use unmaintained or abandoned packages without
documenting and approving the risk.

## 14. Environment and configuration

-   Keep environment-specific configuration separate from source code.
-   Public client configuration may be bundled where required, but
    secrets must never be bundled.
-   Document required environment variables and setup steps in the
    project README or a later developer setup document.
-   Keep `.env` files containing secrets out of version control.
-   Provide a safe example configuration file with placeholder values
    only.

## 15. Recommended project quality gates

A feature is not complete until: - It follows the PRD and SPEC. - It
uses the approved state-management and navigation approach. - Data
access goes through repository boundaries. - Attendance math is in
shared domain logic. - Loading, empty, error, and success states are
handled. - Relevant unit/widget/integration tests pass. - Formatting and
static analysis pass. - No secrets or personal attendance data are
exposed in logs. - Database changes include migrations where needed.

## 16. Decisions deliberately left for later documents

The following should be finalized in `ARCHITECTURE.md`, `DATABASE.md`,
or `AGENTS.md`: - Exact folder structure and dependency direction. -
Exact Drift table definitions and indexes. - Backup/restore file format
and mechanism. - Exact package versions and generated-code commands. -
Logging and crash-reporting provider, if any. - Release signing,
distribution, and store deployment process.

------------------------------------------------------------------------

**Non-negotiable rule:** The Flutter UI must not own persistence rules
or attendance formulas. UI → application/domain logic → repository →
local data source is the intended responsibility flow. The exact
architecture and folder layout will be defined in `ARCHITECTURE.md`.
