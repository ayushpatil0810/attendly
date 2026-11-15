# Product Requirements Document (PRD)

**Product:** Student Attendance Tracker\
**Document status:** Baseline product requirements\
**Version:** 1.0\
**Platform:** Flutter mobile application\
**Audience:** Individual college students\
**Primary purpose:** Help students record attendance accurately and
understand whether they are meeting their college's attendance
requirement.

------------------------------------------------------------------------

## 1. Product overview

The application lets a student create a semester, add subjects, enable
lecture and/or lab components for each subject, and record attendance
for classes that actually took place.

The application does **not** require a timetable. Students add a class
session when it is conducted and mark it Present or Absent. If no
session is recorded, it is not included in attendance calculations.

The app turns those records into clear attendance summaries,
subject-level analytics, safe-absence calculations, recovery
calculations, and what-if scenarios.

## 2. Product goals

1.  Make daily attendance logging fast and straightforward.
2.  Allow students to record or correct attendance for past dates.
3.  Calculate attendance accurately using the student's selected college
    policy.
4.  Show how close the student is to, above, or below the required
    threshold.
5.  Help students understand the impact of future absences and
    attendance recovery.
6.  Keep attendance data private, reliable, and recoverable.

## 3. Target users

**Primary user:** A college student managing their own attendance across
one or more semesters.

The initial product is for individual students, not college
administrators, faculty, or institution-wide attendance management.

## 4. Core terminology

-   **Semester:** A student's academic period containing subjects and
    attendance settings.
-   **Subject:** A course such as Machine Learning or Networks and
    Security.
-   **Component:** The type of class for a subject: Lecture or Lab.
-   **Session:** One actual class meeting that took place.
-   **Conducted session:** A session with a recorded status of Present
    or Absent.
-   **Attendance threshold:** The minimum attendance percentage the
    student wants to maintain, normally 75%.
-   **Unrecorded session:** A class that has not been entered in the
    app. It is not assumed to be an absence and is not counted.

## 5. Product principles

-   **No timetable dependency:** Do not require weekly timetable setup
    or infer that a class took place.
-   **Actual sessions only:** Count only sessions explicitly recorded as
    Present or Absent.
-   **Lecture and Lab are distinct:** Each component has its own
    attendance totals and percentage.
-   **Correctable history:** Students can add or edit sessions for
    previous dates.
-   **Transparent calculations:** Show the counts and calculation method
    behind every percentage and prediction.
-   **No misleading certainty:** Future projections must state their
    assumptions.

## 6. Scope

### 6.1 MVP --- required

1.  Create, edit, archive, and select a semester.
2.  Configure a semester attendance threshold (default 75%).
3.  Select the semester calculation method:
    -   Raw Combined
    -   Component Average (50/50)
4.  Add, edit, and archive subjects.
5.  Enable Lecture, Lab, or both for each subject.
6.  Record a session against a subject, component, and date.
7.  Set a recorded session to Present or Absent.
8.  View and edit attendance by selecting a date in a calendar.
9.  View overall, subject-level, and component-level attendance.
10. Calculate safe additional absences where the selected calculation
    method supports a definitive answer.
11. Calculate consecutive attended sessions needed to reach the
    threshold under clearly stated assumptions.
12. Provide a what-if simulator for future attendance scenarios.
13. Persist data reliably on the local device.

### 6.2 Not in the initial scope

-   College or faculty portals.
-   Automatic timetable import or timetable-based attendance generation.
-   GPS, geofencing, QR-code, face-recognition, or classroom check-in.
-   Social feeds, leaderboards, and student-to-student comparisons.
-   Fee management, academic marks, assignments, or learning management
    features.
-   AI-generated attendance predictions based on inferred schedules.
-   Institution-specific integrations.

## 7. Functional requirements

### FR-01: Semester management

-   A student can create a semester with a name.
-   A semester has a configurable attendance threshold, defaulting to
    75%.
-   A semester has exactly one active calculation method at a time.
-   A student can switch between semesters.
-   A student can edit or archive a semester.
-   Archiving a semester must preserve its records and remove it from
    the default active view.

### FR-02: Subject and component management

-   A student can add a subject name within a semester.
-   Each subject can have Lecture enabled, Lab enabled, or both enabled.
-   Lecture and Lab attendance must be tracked independently.
-   A component that is disabled cannot receive new sessions.
-   Existing session history must not be silently deleted when a subject
    or component is edited or archived.
-   Subject names need not be globally unique, but duplicate names
    within a semester should be clearly handled.

### FR-03: Session logging

Each session must be associated with: - A semester and subject. - A
component: Lecture or Lab. - A calendar date. - A status: Present or
Absent.

Requirements: - Students can add multiple sessions for the same
subject/component/date. - Students can add sessions for past dates. -
Students can edit or delete an existing session. - A session can be
marked Present or Absent. - A class that did not take place is not
entered as a session. - An unrecorded class must never be automatically
treated as Absent. - The app should make the selected date and
subject/component clear before saving. - Prevent accidental duplicate
submissions without preventing legitimate multiple sessions on the same
date.

### FR-04: Attendance calendar and history

-   Display a calendar for navigating dates.
-   Selecting a date shows the sessions recorded for that date.
-   Students can add, edit, and delete sessions from a selected past
    date.
-   Calendar indicators may summarize recorded attendance, but must
    distinguish dates with no records from dates with absences.
-   Editing or deleting a historical session must immediately update all
    affected attendance totals, percentages, analytics, and projections.

### FR-05: Dashboard

The dashboard must show: - Selected semester. - Overall attendance
percentage under the selected calculation method. - Attended and
conducted session counts where meaningful. - Required attendance
threshold. - Difference from the threshold in percentage points. - Safe
additional absences or a clear explanation when this cannot be
represented as one number. - Subject-level attendance summaries. - A
clear below-threshold warning when applicable.

Do not label an unrecorded day as a day of absence.

### FR-06: Subject and component analytics

For each subject, show: - Overall subject attendance according to the
semester calculation method. - Lecture attended/conducted counts and
percentage, if enabled and data exists. - Lab attended/conducted counts
and percentage, if enabled and data exists. - Threshold status. - Safe
absences or recovery information where applicable.

Lecture and Lab percentages must remain independently inspectable even
when the semester uses Raw Combined.

### FR-07: Safe-absence calculation

For Raw Combined attendance, define: - `A` = attended sessions. - `C` =
conducted sessions (Present + Absent). - `t` = threshold as a decimal,
e.g. 0.75. - `x` = additional sessions missed.

The maximum additional absences that preserve attendance at or above the
threshold are:

`max(0, floor(A / t - C))`

The implementation must handle floating-point precision safely and
verify the final integer result against the original inequality:

`A / (C + x) >= t`

If current attendance is already below the threshold, the UI must not
imply that the student can safely miss more classes. Show zero safe
absences and prioritize recovery information.

For Component Average, a single safe-absence number is not generally
meaningful because the impact depends on whether the future absence is a
Lecture or Lab. The app must calculate safe absences through a specified
scenario or show separate component-specific scenario results. It must
not apply the Raw Combined formula to Component Average.

### FR-08: Recovery calculation

For Raw Combined attendance, if current attendance is below the
threshold and every future session is attended: - `A` = currently
attended sessions. - `C` = currently conducted sessions. - `t` =
threshold as a decimal. - `x` = additional consecutive sessions
attended.

The minimum sessions required are:

`ceil((t * C - A) / (1 - t))`

The result must be zero if the student already meets the threshold.
Handle threshold values of 100% separately because recovery may be
impossible after an absence.

For Component Average, recovery depends on the future mix of Lecture and
Lab sessions. Require a scenario specifying the future component
sequence or counts. Do not present a single recovery number without
stating the assumed mix.

Every recovery result must state its assumption: all specified future
sessions are attended and no additional absences occur.

### FR-09: What-if simulator

The simulator must allow a student to model future sessions without
changing saved attendance records.

A scenario must support: - Adding future Lecture and/or Lab sessions. -
Marking simulated sessions as Present or Absent. - Viewing the resulting
attendance percentage. - Comparing the projected result with the
semester threshold. - Showing the effect on safe absences and recovery
where applicable. - Resetting or discarding the scenario without
changing real attendance data.

The simulator must use the semester's selected calculation method. It
must clearly label results as projections, not actual attendance.

### FR-10: Data correction and consistency

-   All analytics must be derived from the saved session records and
    semester settings.
-   Changes to a session, subject, threshold, or calculation method must
    update dependent results.
-   The app must not maintain conflicting manually edited attendance
    totals.
-   Deleting a subject or semester must require an explicit confirmation
    and must not happen through an accidental tap.

### FR-11: Local backup and restore

Because the app is offline-only, local backup and restore protect
against data loss.

-   Students can export all attendance data to a local file.
-   Students can import/restore from a previously exported file.
-   The backup format must be versioned.
-   Restore must validate the backup file before modifying the database.
-   Restore must use a database transaction.
-   The app must explain what happens to existing data during restore
    (replace or reject if data exists).
-   Malformed or unsupported backup files must be rejected without
    corrupting existing data.
-   Backups must not be silently uploaded to any server.

## 8. Attendance calculation rules

### 8.1 What counts

-   Present: adds 1 to attended and 1 to conducted.
-   Absent: adds 0 to attended and 1 to conducted.
-   Not conducted / not entered: adds 0 to attended and 0 to conducted.

`Conducted = Present + Absent`

### 8.2 Method A --- Raw Combined

Every Lecture and Lab session has equal weight.

`Attendance % = (Total Present Sessions / Total Conducted Sessions) * 100`

If there are no conducted sessions, attendance is **Not available**, not
0%.

### 8.3 Method B --- Component Average (50/50)

Calculate Lecture and Lab percentages independently:

`Lecture % = Lecture Present / Lecture Conducted * 100`

`Lab % = Lab Present / Lab Conducted * 100`

When both components have at least one conducted session:

`Attendance % = (Lecture % + Lab %) / 2`

For a subject or semester with only one enabled component, use that
component's percentage.

If both components are enabled but one has no conducted sessions yet, do
not silently treat its percentage as 0% or 100%. Display the available
component percentage as provisional and label the combined result **Not
yet available** until both enabled components have at least one
conducted session. This rule must be applied consistently and explained
in the UI.

### 8.4 Threshold comparison and rounding

-   Use unrounded values for all calculations and threshold comparisons.
-   Round only for display.
-   Meeting the threshold means the exact value is greater than or equal
    to the threshold.
-   Display enough precision to avoid a rounded value appearing to meet
    a threshold when the exact value does not.

## 9. UX requirements

-   Attendance logging should require as few steps as practical.
-   The primary logging flow should make subject, component, date, and
    status obvious.
-   Present and Absent actions must be visually distinct.
-   Adding a past session should use the same validation and calculation
    rules as adding today's session.
-   Empty states should explain what the student can do next.
-   Use clear language: "Not recorded" is not the same as "Absent".
-   Important calculations should show their assumptions and, where
    useful, the underlying attended/conducted counts.
-   The interface must remain usable on common phone screen sizes and
    support accessible text sizing.

## 10. Non-functional requirements

### Reliability and data integrity

-   Attendance records must persist across app restarts.
-   Saving, editing, and deleting sessions must be safe against
    accidental duplicate operations.
-   A failed save must be communicated clearly; the UI must not falsely
    indicate that data was saved.
-   Calculations must be deterministic and covered by automated tests.

### Privacy and security

-   A student's attendance data is private to the local device installation.
-   All student data remains on the device. The app does not transmit attendance records to external services.
-   Do not expose personal attendance records in logs or analytics.

### Offline behavior

-   The application is fully offline. All features work without an internet connection.
-   All data is stored locally using Drift/SQLite.
-   There is no cloud synchronization, remote backend, or network dependency.

### Performance

-   Common actions such as opening the dashboard, viewing a date, and
    saving a session should feel responsive on supported devices.
-   Recalculating attendance for a normal semester should be near-instantaneous from local data.

### Maintainability

-   Keep calculation rules independent of UI widgets.
-   Use clear domain models and testable business logic.
-   Avoid duplicating calculation logic across dashboard, analytics, and
    simulator.

## 11. Acceptance criteria

The MVP is acceptable when all of the following are true:

1.  A student can create a semester, set a threshold, and choose either
    calculation method.
2.  A student can create subjects and enable Lecture, Lab, or both.
3.  A student can record multiple Present/Absent sessions for the same
    subject, component, and date.
4.  A student can leave a date or class unrecorded without it being
    counted as an absence.
5.  A student can add, edit, and delete past sessions.
6.  Dashboard and subject analytics update correctly after every change.
7.  Raw Combined attendance gives equal weight to each conducted
    session.
8.  Component Average calculates the independent Lecture and Lab
    percentages and handles a component with no sessions according to
    Section 8.3.
9.  Safe-absence and recovery calculations match the formulas and
    assumptions in Sections 7 and 8.
10. The simulator does not modify saved attendance.
11. Student data is private to the local device installation.
12. Core calculation logic has automated unit tests, including boundary
    cases.

## 12. Essential calculation test cases

Use these as minimum regression tests:

  -----------------------------------------------------------------------
  Case                    Input                   Expected result
  ----------------------- ----------------------- -----------------------
  Raw Combined            80 Present / 100        80%
                          Conducted               

  Raw Combined safe       80 / 100, threshold 75% 6
  absences                                        

  Raw Combined recovery   60 / 100, threshold 75% 60 consecutive Presents

  At threshold            75 / 100, threshold 75% 0 safe absences

  No sessions             0 / 0                   Not available

  Component Average       Lecture 36/40, Lab 6/10 75%

  Component Average, one  Lecture 36/40; Lab      90%
  enabled component       disabled                

  Component Average,      Lecture 36/40; Lab 0/0  Combined result not yet
  enabled Lab has no                              available
  sessions                                        

  Historical correction   Change one Absent to    All dependent results
                          Present                 recalculate

  Unrecorded class        No session record       Conducted and attended
                                                  totals unchanged
  -----------------------------------------------------------------------

## 13. Product decisions and assumptions

The following are baseline decisions for consistent implementation:

-   The initial audience is individual college students.
-   The application is built with Flutter.
-   A semester has one selected calculation method and one default
    threshold.
-   The default threshold is 75%, but it is configurable.
-   Each subject can have Lecture, Lab, or both.
-   Sessions are recorded manually; no timetable is required.
-   Only Present and Absent sessions count as conducted.
-   No session record means no attendance data for that class; it does
    not mean Absent.
-   Component Average requires both enabled components to have data
    before showing a combined percentage.
-   Future simulator inputs are hypothetical and never modify actual
    records.

Items that can be finalized in later technical/design documents: -
State management, routing, and dependency injection are decided:
Riverpod, go_router, Drift/SQLite. - Detailed screen layouts,
typography, colors, and interaction specifications. - Local
backup/export format and restore policy. - Supported minimum
Android/iOS versions. - The app is offline-only. Drift/SQLite is the
sole persistence source. No remote backend, authentication, or cloud
sync.

## 14. Definition of success

The MVP succeeds if a student can consistently record actual classes,
trust the displayed attendance calculations, correct missed or mistaken
entries, and use the simulator to make informed attendance decisions
without maintaining a timetable.
