# Testing Strategy

**Product:** Student Attendance Tracker\
**Document status:** Baseline testing specification\
**Version:** 1.0\
**Depends on:** `PRD.md`, `SPEC.md`, `TECH_STACK.md`, `ARCHITECTURE.md`

------------------------------------------------------------------------

## 1. Purpose

This document defines how correctness, reliability, and regression
safety are verified in the Student Attendance Tracker.

Testing is especially important because incorrect attendance
calculations can cause students to make poor academic decisions. The
same business rules must be verified independently of the UI and reused
throughout the application.

## 2. Testing principles

1.  Test business rules before testing presentation.
2.  Attendance calculations must have comprehensive pure Dart unit
    tests.
3.  Test boundary conditions, not only typical examples.
4.  Test that missing records are never interpreted as absences.
5.  Test that simulated sessions never change actual attendance.
6.  Test local persistence and migrations.
7.  Test local persistence and offline behavior thoroughly.
8.  Prefer deterministic tests that do not depend on live network
    services.
9.  Every bug fix should include a regression test where practical.
10. A passing test suite does not replace manual usability and release
    checks.

## 3. Approved testing tools

Use the Flutter/Dart testing ecosystem:

  Test type           Tool
  ------------------- ---------------------------------
  Unit tests          `flutter_test` / Dart test APIs
  Widget tests        `flutter_test`
  Integration tests   `integration_test`
  Mocking and fakes   `mocktail`
  Static analysis     Dart analyzer
  Formatting          `dart format`
  CI automation       GitHub Actions

Use the versions compatible with the pinned Flutter SDK in
`TECH_STACK.md`. Do not add another testing framework without a
documented need.

## 4. Test layers

### 4.1 Domain unit tests

Test pure Dart domain logic without Flutter widgets, Drift, or network access.

Required coverage: - Attendance calculations. - Threshold comparisons. -
Safe-absence calculations. - Recovery calculations. - Scenario
projections. - Session and semester validation. - Component availability
states.

These tests are the highest priority because they protect the meaning of
attendance data.

### 4.2 Data and repository tests

Test repository implementations and local persistence.

Required coverage: - Create, read, update, and delete operations. -
Correct mapping between database records and domain entities. - Multiple
sessions on the same date. - Historical date queries. - Transactions. -
Database migrations. - Archive behavior.


### 4.3 Provider / application-state tests

Test Riverpod providers and notifiers.

Required coverage: - Loading, data, and error states. - Selected
semester changes. - Refresh after successful writes. - Error
propagation. - State isolation between features. - Simulator state reset
and baseline refresh.

Use fake repositories or controlled mocks. Do not mock the calculation
implementation in tests intended to verify calculations.

### 4.4 Widget tests

Test visible behavior and user interactions.

Required coverage: - Form validation. - Present and Absent actions. -
Date selection. - Empty states. - Loading and error states. - Threshold
and status display. - Dashboard and subject summary refresh. - Simulator
controls and projected results. - Accessibility labels for important
controls.

Widget tests should verify that screens display domain results
correctly. They should not reimplement or independently verify
attendance formulas.

### 4.5 Integration tests

Test complete user journeys on a real or representative emulator/device.

Required journeys: - Create a semester and subject. - Record a Present
session. - Record an Absent session. - Add a session for a past date. -
Edit and delete a session. - Confirm dashboard and subject analytics
update. - Run a simulator scenario and verify actual records remain
unchanged. - Restart the app and verify local records persist. - Test
local backup export and restore.

## 5. Attendance calculation test plan

All formulas and edge cases in `SPEC.md` are authoritative. The tests
below are minimum regression coverage, not a replacement for the
specification.

### 5.1 Raw Combined percentage

Formula:

`attendance = attended / conducted * 100`

  Test                  Input                         Expected
  --------------------- ----------------------------- ---------------
  Typical               80 attended / 100 conducted   80%
  All present           10 / 10                       100%
  All absent            0 / 10                        0%
  No sessions           0 / 0                         Not available
  One session present   1 / 1                         100%
  One session absent    0 / 1                         0%

### 5.2 Component Average

  -----------------------------------------------------------------------
  Test                      Lecture                Lab           Expected
  -------------- ------------------ ------------------ ------------------
  Typical               36/40 = 90%         6/10 = 60%                75%

  Equal                  8/10 = 80%          4/5 = 80%                80%
  component                                            
  percentages                                          

  One enabled      36/40 = 90%; Lab                ---                90%
  component                disabled                    

  Lab has no            36/40 = 90%                0/0       Combined Not
  sessions                                             available; Lecture
                                                              provisional

  Both have no                  0/0                0/0      Not available
  sessions                                             

  One component        10/10 = 100%           0/5 = 0%                50%
  all absent                                           
  -----------------------------------------------------------------------

Also verify: - Lecture and Lab are averaged independently. - Different
session counts do not change the 50/50 component weighting. - Disabled
components are not treated as enabled components with zero attendance. -
A component with no sessions is neither 0% nor 100%.

### 5.3 Threshold status

Test: - Attendance exactly equals threshold. - Attendance is just below
threshold. - Attendance is just above threshold. - Display rounding
differs from the exact underlying value. - Threshold changes without
modifying session records. - Threshold values at the permitted minimum
and 100%.

The status must be based on unrounded values.

### 5.4 Safe additional absences --- Raw Combined

Formula for a student currently meeting the threshold:

`x = max(0, floor(attended / threshold - conducted))`

The implementation must verify the boundary against:

`attended / (conducted + x) >= threshold`

and, where `x` is positive:

`attended / (conducted + x + 1) < threshold`

Minimum test cases:

    Attended   Conducted   Threshold   Expected safe absences
  ---------- ----------- ----------- ------------------------
          80         100         75%                        6
          75         100         75%                        0
          90         100         75%                       20
          60         100         75%       0; below threshold
         100         100         75%                       33
           0           0         75%            Not available

Also test: - Fractional intermediate results. - Floating-point boundary
precision. - 100% threshold. - No division by zero. - One more absence
always violates the threshold when a positive maximum is reported.

For Component Average, test that the app requires a specified future
component or scenario rather than using the Raw Combined formula.

### 5.5 Recovery calculations --- Raw Combined

Formula when below threshold and threshold is less than 100%:

`x = ceil((threshold * conducted - attended) / (1 - threshold))`

Minimum test cases:

    Attended   Conducted   Threshold   Expected consecutive Presents
  ---------- ----------- ----------- -------------------------------
          60         100         75%                              60
          70         100         75%                              20
          74         100         75%                               4
          75         100         75%                               0
          80         100         75%                               0
           0          10         75%                              30

Also test: - One fewer Present remains below threshold when recovery is
required. - The reported number reaches or exceeds the threshold. - 100%
threshold with an existing absence is reported as impossible through
attendance alone. - 100% threshold with no absences reports zero
recovery sessions. - No sessions returns an appropriate unavailable or
no-data state, not a misleading recovery count.

For Component Average, test explicit future Lecture/Lab mixes. Never
expect a generic recovery count without a defined mix.

### 5.6 Simulator calculations

Test: - No hypothetical sessions produces the baseline result. - A
hypothetical Present changes only projected values. - A hypothetical
Absent changes only projected values. - Multiple future sessions are all
included exactly once. - Mixed Lecture/Lab scenarios use the selected
method. - Clearing a scenario restores the baseline projection. - Actual
saved sessions remain unchanged. - Changing actual attendance while a
scenario is open refreshes or invalidates the baseline according to the
implementation. - Projected results are clearly distinguished from
actual results.

## 6. Domain validation tests

### Semester

-   Reject blank name.
-   Reject threshold less than or equal to 0.
-   Reject threshold greater than 100.
-   Accept valid threshold.
-   Accept each supported calculation method.
-   Archiving preserves associated records.

### Subject

-   Reject blank name.
-   Reject neither Lecture nor Lab enabled.
-   Accept Lecture only.
-   Accept Lab only.
-   Accept both components.
-   Disabling a component does not delete its historical sessions.
-   Archived subject cannot receive new sessions.

### Attendance session

-   Reject missing subject.
-   Reject subject from a different semester.
-   Reject archived subject for new sessions.
-   Reject disabled component for new sessions.
-   Reject invalid component or status.
-   Accept Present and Absent.
-   Accept multiple sessions for the same subject, component, and date.
-   Editing a historical session replaces its previous contribution.
-   Deleting a session removes its contribution.
-   No session record contributes nothing to either attended or
    conducted totals.

## 7. Database and repository test plan

Use a test database isolated from development and production data.

Required tests: 1. Semester CRUD. 2. Subject CRUD. 3. Session CRUD. 4.
Query sessions by date. 5. Query sessions by date range. 6. Query
sessions by semester and subject. 7. Multiple same-day sessions are
preserved. 8. Transactions do not leave partial data after failure. 9.
Foreign-key relationships prevent orphan records. 10. Archive operations
preserve history. 11. Migrations preserve existing records. 12.
Date-only values remain on the intended calendar date across timezone
changes. 13. Reopening the database preserves saved attendance.

### Migration tests

For every schema migration: - Start with a database using the previous
schema. - Insert representative data. - Apply the migration. - Verify
records and relationships remain valid. - Verify new defaults and
constraints. - Verify the upgraded database can perform normal reads and
writes.

Never validate migrations only against an empty database.

## 8. Backup and restore tests

Testing backup and restore is critical because the application is offline-only
and local export/import is the primary safeguard against data loss.

### Export tests

-   Export produces valid, well-formed JSON matching the documented backup format.
-   Export includes all user semesters, subjects, settings, and attendance sessions.
-   Export includes the correct backup format identifier and format version.
-   Export preserves date-only ISO strings (`YYYY-MM-DD`) without timezone drift.
-   Export handles an empty database safely (empty arrays).
-   Export does not include remote credentials, tokens, or device-specific secrets.

### Restore validation tests

-   Import validates the format identifier and rejects unrecognized files.
-   Import rejects unsupported or future backup format versions with a clear error.
-   Import rejects malformed JSON or corrupted files without altering the database.
-   Import validates required fields, types, and schema constraints.
-   Import validates relational integrity (subjects reference valid semesters; sessions reference valid subjects).
-   Import validates component and status enum values (`lecture`/`lab`, `present`/`absent`).
-   Import validates that each session's component was enabled for its subject.
-   Import rejects or resolves duplicate `(subject, date, component)` records.
-   Import validates date strings as real calendar dates.
-   File size and record count limits are enforced against denial-of-service/memory exhaustion.

### Restore execution and transaction tests

-   Restore operations execute within a single database transaction.
-   If any validation or insertion error occurs during restore, the entire operation is rolled back and existing database records remain untouched.
-   Restore correctly replaces existing local data after explicit user confirmation.
-   Restored data produces attendance percentages and counts identical to the source data.
-   App functionality, queries, and reactive providers operate normally after a restore.

## 9. Provider and state tests

Verify: - Providers expose loading before data is available. - Providers
expose typed data after repository success. - Providers expose a
recoverable error after repository failure. - Creating a session
refreshes affected attendance summaries. - Editing a session refreshes
both old and new date/subject summaries when relevant. - Deleting a
session refreshes all affected summaries. - Switching semesters does not
leak the previous semester's data. - Simulator changes do not invalidate
or mutate actual attendance providers. - Resetting the simulator clears
hypothetical state.

## 10. Widget test plan

Minimum screen-level checks:

### Semester screens

-   Create form validation.
-   Threshold input validation.
-   Calculation method selection.
-   Archive confirmation.

### Subject screens

-   Component toggles.
-   At least one component required.
-   Disabled component history is not hidden or deleted.

### Attendance logging

-   Correct selected date.
-   Correct subject and component.
-   Present and Absent actions.
-   Save feedback.
-   Failed save does not show success.
-   Multiple sessions can be added on one date.

### Calendar/history

-   Month navigation.
-   Date selection.
-   Empty date state.
-   Mixed Present/Absent date indicator.
-   Historical edit and delete actions.

### Dashboard and analytics

-   Not available state for no data.
-   Correct threshold status.
-   Subject/component values display the supplied domain summaries.
-   No-record dates are not displayed as absences.

### Simulator

-   Scenario inputs update projected values.
-   Actual values remain visually distinguishable.
-   Reset clears hypothetical inputs.
-   Scenario is not saved as real attendance.

## 11. Integration and end-to-end scenarios

The following journeys should be automated on a representative Android
emulator before each major release.

### Journey A: First use

1.  Launch app.
2.  Complete onboarding and initial semester setup.
3.  Create a semester.
4.  Set threshold and calculation method.
5.  Add a subject with Lecture and Lab.
6.  Confirm the dashboard shows Not available before any sessions.

### Journey B: Daily logging

1.  Open attendance logging.
2.  Add a Lecture as Present.
3.  Add a Lab as Absent.
4.  Verify both sessions are visible.
5.  Verify counts and percentages update correctly.

### Journey C: Backdated correction

1.  Open calendar.
2.  Select a previous date.
3.  Add an Absent session.
4.  Edit it to Present.
5.  Verify the historical record and all derived results update.

### Journey D: Simulator isolation

1.  Note actual attendance.
2.  Open simulator.
3.  Add hypothetical Present and Absent sessions.
4.  Verify projected attendance changes.
5.  Reset or exit.
6.  Verify actual attendance is unchanged.

### Journey E: Persistence

1.  Record sessions.
2.  Close and relaunch the app.
3.  Verify semester, subject, and session data remain available.
4.  Verify derived attendance is recalculated correctly.

### Journey F: Local backup and restore

1.  Record sessions across multiple subjects.
2.  Export a local backup.
3.  Clear or reinstall the app (simulating clean install or device move).
4.  Import the backup file.
5.  Verify all semesters, subjects, and sessions are restored accurately.
6.  Verify attendance calculations and historical edits match the original data.

## 12. Test data and fixtures

Create reusable deterministic fixtures for: - Empty semester. - Semester
with Lecture only. - Semester with Lab only. - Semester with both
components. - Raw Combined at 80%. - Raw Combined below threshold. -
Component Average with unequal session counts. - Component Average with
one component missing data. - Multiple sessions on the same date. -
Historical sessions across month and year boundaries. - Archived
subjects with historical sessions.

Fixtures must use stable dates and IDs. Avoid tests that depend on the
actual current date unless the clock is explicitly controlled.

Do not share production user data in test fixtures.

## 13. Test naming and organization

Recommended structure:

``` text
test/
├── features/
│   ├── attendance/
│   │   ├── domain/
│   │   │   ├── attendance_calculator_test.dart
│   │   │   ├── safe_absence_calculator_test.dart
│   │   │   ├── recovery_calculator_test.dart
│   │   │   └── scenario_calculator_test.dart
│   │   ├── data/
│   │   │   └── attendance_repository_test.dart
│   │   └── presentation/
│   │       └── attendance_screen_test.dart
│   ├── semesters/
│   ├── subjects/
│   ├── calendar/
│   ├── analytics/
│   └── simulator/
├── core/
│   ├── database/
│   └── backup/
├── integration_test/
└── fixtures/
```

Use descriptive test names that state the condition and expected
behavior.

Example:

``` dart
test(
  'returns six safe absences for 80 attended out of 100 at 75 percent',
  () {
    // Arrange, act, assert.
  },
);
```

The example is illustrative; actual test code must use the final domain
APIs.

## 14. Continuous integration quality gates

GitHub Actions must run on pull requests and relevant branch updates.

Minimum pipeline: 1. Check out repository. 2. Install the pinned Flutter
SDK. 3. Resolve dependencies. 4. Check formatting. 5. Run static
analysis. 6. Run unit tests. 7. Run widget tests. 8. Run
repository/database tests. 9. Build the configured Android target when
practical.

Example command sequence:

``` bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Integration tests may run in a separate emulator-enabled workflow.

CI must not require external services or remote credentials. All tests run against local
Drift/SQLite databases and in-memory test fixtures.

## 15. Definition of done

A feature is not complete until: - Its behavior matches `PRD.md` and
`SPEC.md`. - Relevant unit tests are added or updated. - Relevant
widget/repository/integration tests are added where appropriate. -
Existing tests pass. - Static analysis passes. - Formatting passes. -
Database migrations are tested if the schema changed. - Error, empty,
loading, and success states are handled. - No secrets or real attendance
data are included in tests or logs. - Documentation is updated if a
requirement or technical decision changed.

## 16. Release readiness checklist

Before an MVP release, verify:

-   [ ] All Raw Combined calculation tests pass.
-   [ ] All Component Average calculation tests pass.
-   [ ] Safe-absence boundary tests pass.
-   [ ] Recovery boundary tests pass.
-   [ ] No-session and missing-component states are correct.
-   [ ] Historical session creation and editing work.
-   [ ] Multiple same-day sessions work.
-   [ ] Simulator never changes actual records.
-   [ ] Local persistence survives app restart.
-   [ ] Database migrations are tested.
-   [ ] User data access is protected.
-   [ ] Offline behavior matches the advertised capability.
-   [ ] Local backup and restore tests pass.
-   [ ] Critical user journeys pass on supported devices.
-   [ ] No known critical or high-severity data-loss bugs remain.

------------------------------------------------------------------------

**Non-negotiable rule:** Attendance calculations must be tested as pure
domain logic. A UI test showing the expected percentage is not
sufficient evidence that the calculation engine is correct.
