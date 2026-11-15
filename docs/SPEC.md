# Software Specification (SPEC)

**Product:** Student Attendance Tracker\
**Document status:** Baseline functional specification\
**Version:** 1.0\
**Depends on:** `PRD.md`\
**Platform:** Flutter mobile application

------------------------------------------------------------------------

## 1. Purpose

This document translates the product requirements in `PRD.md` into
precise, implementable application behavior. It defines user flows,
screen responsibilities, business rules, validation, state transitions,
and expected outcomes.

This document does not select packages, define the Flutter architecture,
or prescribe visual styling. Those belong in `TECH_STACK.md`,
`ARCHITECTURE.md`, and `DESIGN.md`.

## 2. Source-of-truth rules

1.  `PRD.md` defines product goals, scope, and high-level requirements.
2.  This document defines detailed functional behavior consistent with
    the PRD.
3.  If an implementation detail is not specified here, do not invent a
    product behavior that changes attendance meaning.
4.  If two requirements conflict, record the conflict and resolve it
    explicitly before implementation.
5.  Attendance calculations must use the rules in Section 8. Do not
    create separate formulas for different screens.

## 3. Actors and permissions

### Student

A student can: - Create and manage their own semesters. - Create and
manage subjects within their semesters. - Record, edit, and delete
sessions in their own semesters. - View attendance summaries, analytics,
and history. - Run hypothetical scenarios.

Student data is private to the local device installation. No multi-user access control is needed because the app has no accounts or authentication.

There are no administrator, faculty, or institution roles in the initial
release.

## 4. Core domain rules

### 4.1 Semester

A semester is the container for: - Its name. - Its attendance
threshold. - Its attendance calculation method. - Its subjects and
session records. - Its lifecycle status (active or archived).

A student may have multiple semesters. The application must make the
currently selected semester clear wherever semester-specific data is
shown.

### 4.2 Subject and component

A subject belongs to exactly one semester.

Each subject can enable: - Lecture only. - Lab only. - Both Lecture and
Lab.

Lecture and Lab are separate attendance components. They must never be
merged in storage in a way that prevents independent calculation.

A component that is disabled for a subject cannot be selected when
creating a new session for that subject.

### 4.3 Session

A session represents one class that actually took place.

Required session attributes: - Subject. - Component (`lecture` or
`lab`). - Date. - Status (`present` or `absent`).

Multiple sessions for the same subject, component, and date are valid.
For example, two Machine Learning lectures can be recorded on the same
day.

A session cannot have a `not_conducted` status. A class that did not
take place is represented by the absence of a session record.

A date with no session records is not proof that no classes were
scheduled; it simply has no attendance data.

## 5. Navigation and screen specification

The initial app should provide access to these primary destinations:

1.  **Dashboard**
2.  **Log Attendance**
3.  **Calendar / History**
4.  **Analytics**
5.  **Settings / Semester Management**

The What-if Simulator must be reachable from the dashboard and
analytics. It may be a dedicated screen or a clearly separated section,
as long as it does not modify actual attendance records.

### 5.1 Dashboard

**Purpose:** Give the student an at-a-glance view of their selected
semester.

Must display: - Selected semester name. - Overall attendance percentage
or an explicit "Not available" state. - Threshold percentage. - Attended
and conducted counts when those counts are meaningful for the selected
method. - Difference from threshold in percentage points. - Safe
additional absences, if calculable. - Recovery guidance when below
threshold. - Subject attendance summaries.

Behavior: - Changing the selected semester refreshes all dashboard
content. - Tapping a subject summary opens that subject's attendance
detail. - Tapping a safe-absence or recovery summary opens an
explanation or simulator view. - The dashboard must not treat unrecorded
classes as absences. - A percentage must never be displayed as 0% merely
because no sessions have been recorded.

### 5.2 Semester management

The student must be able to: - View existing semesters. - Create a
semester. - Select a semester. - Edit its name, threshold, and
calculation method. - Archive a semester.

Create/edit fields: - Semester name: required, trimmed, non-empty. -
Threshold: required, numeric, greater than 0 and at most 100. -
Calculation method: required; `raw_combined` or `component_average`.

Default threshold: 75%.

Validation: - Reject a blank name. - Reject non-numeric thresholds. -
Reject thresholds less than or equal to 0 or greater than 100. -
Preserve existing sessions when the threshold or method changes. -
Recalculate all displayed results after a threshold or method change.

Archiving: - Requires confirmation. - Preserves all data. - Removes the
semester from the default active-semester selection. - Must not silently
delete sessions or subjects.

If the currently selected semester is archived, select another active
semester if one exists; otherwise show the empty-semester state.

### 5.3 Subject management

The student must be able to: - View subjects in the selected semester. -
Add a subject. - Edit a subject name and enabled components. - Archive a
subject.

Create/edit fields: - Subject name: required, trimmed, non-empty. -
Lecture enabled: boolean. - Lab enabled: boolean. - At least one
component must be enabled.

Validation: - Reject blank subject names. - Reject a subject with
neither component enabled. - Prevent new sessions for disabled
components. - If a component with existing sessions is disabled, retain
its history and include an explicit confirmation explaining that the
component will no longer be available for new session logging. -
Re-enabling a component makes it available for new sessions again; it
does not alter old sessions.

Archiving a subject: - Requires confirmation. - Preserves all session
history. - Prevents new sessions from being added to the archived
subject. - Keeps archived subject history available for historical
review and semester calculations.

### 5.4 Log Attendance

**Purpose:** Record actual sessions with minimal effort.

The flow must support two entry points: - Log for today. - Log for a
date selected from Calendar / History.

The student must be able to: 1. Choose a subject. 2. Choose an enabled
component (Lecture or Lab). 3. Confirm or select the session date. 4.
Choose Present or Absent. 5. Save the session.

The UI may streamline the steps, but it must preserve the same required
information and validation.

Rules: - Default the date to today when entering from the daily logging
action. - When entering from a calendar date, prefill that selected
date. - Do not preselect a subject or component in a way that can cause
a session to be saved against the wrong course. - Allow more than one
session for the same subject/component/date. - After a successful save,
provide clear confirmation and update visible totals. - If saving fails,
retain the user's entered values and show an actionable error. - Do not
display a success state until the save has succeeded.

### 5.5 Calendar / History

**Purpose:** Navigate historical attendance and correct records.

The calendar must: - Allow navigation between months. - Allow selection
of a date. - Show recorded sessions for the selected date. - Distinguish
a date with recorded Present sessions, recorded Absent sessions, a
mixture, and no records. - Avoid implying that a date with no records is
a confirmed holiday or a confirmed absence.

On a selected date, the student can: - Add a session for that date. -
Edit an existing session. - Delete an existing session.

Editing: - The student can change subject, component, date, or status,
subject to current validation. - The destination subject must belong to
the same semester. - The selected component must be enabled for that
subject, unless editing a historical record of a now-disabled component.
Historical records must remain editable without forcing deletion or data
loss; the UI should explain that the component is disabled for new
sessions. - Saving an edit updates all affected calculations.

Deleting: - Requires confirmation. - Removes the session from attendance
totals after successful deletion. - If deletion fails, retain the
existing record and communicate the error.

### 5.6 Subject detail

A subject detail view must show: - Subject name. - Subject attendance
percentage under the selected semester method. - Threshold status. -
Lecture counts and percentage when Lecture is enabled. - Lab counts and
percentage when Lab is enabled. - A list or calendar view of its
sessions. - A way to add a session for that subject. - Safe-absence or
recovery information only when it can be calculated accurately.

### 5.7 Analytics

Analytics must be derived from saved sessions and current semester
settings.

Required views: - Overall semester attendance. - Subject-level
attendance. - Lecture versus Lab attendance where applicable. - Attended
and conducted counts. - Attendance trend over time, based only on
recorded sessions.

Rules: - Do not invent attendance for dates without records. - Do not
interpolate missing sessions as absences. - A trend must use a clearly
defined time grouping (for example, week or month) and must not imply
that days with no records had zero attendance. - All displayed
percentages must use the selected semester calculation method where the
metric is an overall or subject-level percentage. - Component-specific
percentages always use that component's own records.

### 5.8 What-if Simulator

**Purpose:** Model possible future attendance without changing saved
data.

The simulator must: - Start from the selected semester's current saved
attendance. - Allow the student to add hypothetical future sessions. -
Require each simulated session to specify a subject, enabled component,
and outcome (Present or Absent). - Support multiple simulated
sessions. - Display the projected overall and affected subject/component
results. - Use the selected semester calculation method. - Show whether
the projection meets the threshold. - Allow the scenario to be cleared
or reset.

Rules: - Simulated sessions must never be saved as actual attendance. -
Leaving the simulator must not change saved data. - Editing actual
attendance while a scenario is open must either refresh the scenario's
baseline or clearly ask the student to refresh it; never silently
combine stale baseline data with new actual records. - Scenario output
must be labeled "Projected" or "Scenario". - A projection must not
assume future classes exist unless the student adds them to the
scenario.

Supported scenario examples: - Miss 1 Lecture. - Attend 5 Lectures. -
Attend 2 Labs and miss 1 Lab. - Attend all specified future sessions.

## 6. Attendance status and counting

Only two persisted statuses are valid: - `present` - `absent`

Counting: - Present contributes 1 to attended and 1 to conducted. -
Absent contributes 0 to attended and 1 to conducted. - No record
contributes 0 to attended and 0 to conducted.

For a component: - `attended = count(status == present)` -
`conducted = count(status in [present, absent])`

A session is counted exactly once. A session edit must replace its
previous contribution, not add another contribution.

## 7. Calculation method behavior

The semester selects one method. Every overall and subject-level
percentage must use that method.

### 7.1 Raw Combined

For a semester or subject:

`attendance = total_present_sessions / total_conducted_sessions * 100`

Lecture and Lab sessions each carry equal weight.

If conducted sessions equal zero: - Percentage state is
`not_available`. - Do not display 0%. - Safe absences and recovery are
unavailable until sufficient data exists.

### 7.2 Component Average (50/50)

Calculate enabled components independently.

For each enabled component: -
`component_attendance = component_present / component_conducted * 100`,
if conducted is greater than zero. - Otherwise, that component is
`not_available`.

Combination: - If only one component is enabled, use that component's
percentage once it has conducted sessions. - If both Lecture and Lab are
enabled, the combined percentage is available only when both have at
least one conducted session. - When both are available,
`combined = (lecture_percentage + lab_percentage) / 2`. - If one enabled
component has no conducted sessions, show the available component's
percentage as provisional and the combined result as `not_available`.

Do not: - Treat a component with no sessions as 0%. - Treat a component
with no sessions as 100%. - Substitute Raw Combined calculations for
Component Average.

### 7.3 Threshold status

Use unrounded values.

-   `meeting`: attendance is greater than or equal to threshold.
-   `below`: attendance is less than threshold.
-   `not_available`: attendance cannot yet be calculated.

Display rounding must not change the status. Where a rounded display
could be misleading, show additional decimal precision or a clear status
label.

## 8. Safe-absence and recovery behavior

### 8.1 Raw Combined safe absences

Inputs: - `A`: current attended count. - `C`: current conducted count. -
`t`: threshold divided by 100.

If current attendance is below threshold, show zero safe additional
absences and prioritize recovery guidance.

Otherwise:

`x = max(0, floor(A / t - C))`

The implementation must correct for floating-point precision and verify
the final result:

`A / (C + x) >= t`

Also verify that one more absence would fail the threshold when the
result is positive:

`A / (C + x + 1) < t`

If no sessions have been conducted, show this metric as unavailable
rather than presenting an unqualified number.

### 8.2 Raw Combined recovery

If current attendance meets or exceeds the threshold, required recovery
sessions = 0.

If below threshold and threshold is less than 100%:

`x = ceil((t * C - A) / (1 - t))`

Verify that: - The projected percentage after `x` consecutive Presents
meets the threshold. - The projected percentage after `x - 1` Presents
remains below the threshold, when `x > 0`.

At a 100% threshold: - If any absence exists, recovery by merely
attending future sessions is impossible. - Explain this rather than
dividing by zero or displaying an invalid number. - If no absence
exists, the student is already at 100%.

Recovery assumptions must be displayed: - Every future session in the
calculation is attended. - No additional absences occur. - The
calculation is for Raw Combined sessions, where each future session has
equal weight.

### 8.3 Component Average safe absences and recovery

Do not display one generic number for Component Average.

For any safe-absence or recovery calculation: - Specify which component
receives the hypothetical sessions, or specify the full future
Lecture/Lab mix. - Recalculate each affected component percentage and
the resulting component average. - State the scenario assumptions. - If
no future component mix has been supplied, prompt the student to define
a scenario or use the What-if Simulator.

### 8.4 General projection rules

-   Use exact numeric values internally.
-   Never use rounded display percentages as calculation inputs.
-   Do not count hypothetical sessions in actual attendance totals.
-   Clearly separate actual, projected, and target values.

## 9. Validation and error handling

### 9.1 General validation

-   Trim user-entered names before validation and saving.
-   Reject required fields that are empty.
-   Validate numeric values and allowed ranges.
-   Show validation near the field where possible.
-   Preserve valid form input when a save operation fails.

### 9.2 Session validation

Reject a session if: - The subject does not exist or is not part of the
selected semester. - The subject is archived. - The selected component
is not enabled for new sessions. - The date is missing or invalid. - The
status is not Present or Absent.

Multiple sessions on the same date are allowed. Do not use a uniqueness
rule that blocks legitimate repeated classes.

### 9.3 Operation feedback

Every create, edit, archive, and delete action must have: - A visible
in-progress state where an operation may take time. - A success
confirmation after success. - An error message after failure. - No false
success state.

Destructive actions such as deleting a session or archiving a
semester/subject require confirmation.

## 10. Data integrity and lifecycle behavior

-   Session records are the source of truth for attendance.
-   Do not store independently editable attendance percentages or totals
    as authoritative data.
-   All derived values must be recalculated from sessions and semester
    configuration.
-   Changing a semester threshold changes status and guidance, not
    historical session data.
-   Changing the calculation method changes derived percentages, not
    session data.
-   Renaming a subject must not change its historical session counts.
-   Archiving must preserve historical records.
-   Deletion of a session must remove its contribution from all
    calculations.
-   If permanent deletion of a subject or semester is offered in the
    future, it must have explicit cascade behavior and confirmation. It
    is not required for the MVP.

## 11. Empty, loading, and error states

The application must define clear states for:

  -----------------------------------------------------------------------
  Situation                           Required behavior
  ----------------------------------- -----------------------------------
  No semesters                        Explain how to create the first
                                      semester

  No subjects in semester             Explain how to add a subject

  No sessions recorded                Show attendance as Not available
                                      and offer logging action

  No sessions on selected date        Show "No sessions recorded" and
                                      offer Add Session

  Component has no sessions           Show Not available for that
                                      component

  Component Average missing one       Show available component as
  enabled component                   provisional; combined result Not
                                      available

  Below threshold                     Show below-threshold state and
                                      recovery guidance

  Offline or save failure             Explain that the local save failed;
                                      retain input so the student can
                                      retry

  Archived semester                   Show as archived and prevent new
                                      session logging

  Archived subject                    Preserve history and prevent new
                                      session logging
  -----------------------------------------------------------------------

## 12. Accessibility and usability behavior

-   All actions must have clear text labels or accessible semantic
    labels.
-   Present and Absent must not be distinguished by color alone.
-   Status, threshold, and error information must remain understandable
    with larger system text.
-   Interactive controls must have adequate touch targets.
-   Date selection must be usable without relying only on color-coded
    calendar indicators.
-   Important calculation results must include text explanations, not
    only charts or progress rings.

## 13. Acceptance scenarios

### Scenario A: Create a semester

**Given** the student has no active semester\
**When** they create a semester with a name, 75% threshold, and Raw
Combined method\
**Then** the semester is saved and can be selected\
**And** its attendance is Not available until sessions are recorded.

### Scenario B: Add a subject with lecture and lab

**Given** a selected semester\
**When** the student adds Machine Learning and enables Lecture and Lab\
**Then** both components are available for session logging\
**And** their attendance is tracked independently.

### Scenario C: Record an absence

**Given** a subject with Lecture enabled\
**When** the student records a Lecture as Absent on a date\
**Then** conducted increases by one\
**And** attended does not increase\
**And** the attendance percentage is recalculated.

### Scenario D: Leave a class unrecorded

**Given** a student has not entered a session for a date\
**When** they view attendance\
**Then** no session is added to attended or conducted\
**And** the app does not classify the missing record as an absence.

### Scenario E: Record a past class

**Given** the student selects a date in the past\
**When** they add a Present or Absent session\
**Then** the session is stored against that selected date\
**And** all affected attendance figures update.

### Scenario F: Edit an old absence

**Given** a recorded Absent session\
**When** the student edits its status to Present\
**Then** the old absence contribution is replaced\
**And** attended increases by one while conducted remains unchanged.

### Scenario G: Raw Combined safe absences

**Given** 80 attended out of 100 conducted and a 75% threshold\
**When** the app calculates safe absences\
**Then** it reports 6\
**And** verifies that 6 additional absences leave attendance at or above
75%, while 7 do not.

### Scenario H: Raw Combined recovery

**Given** 60 attended out of 100 conducted and a 75% threshold\
**When** the app calculates recovery\
**Then** it reports 60 consecutive Present sessions\
**And** explains that no further absences are assumed.

### Scenario I: Component Average

**Given** Lecture attendance is 36/40 and Lab attendance is 6/10\
**When** the selected method is Component Average\
**Then** Lecture is 90%, Lab is 60%, and combined attendance is 75%.

### Scenario J: Component Average with missing component data

**Given** Lecture and Lab are both enabled\
**And** Lecture has sessions but Lab has none\
**When** the student views combined attendance\
**Then** the Lecture percentage is shown as provisional\
**And** combined attendance is Not available\
**And** Lab is not treated as 0% or 100%.

### Scenario K: Simulate future attendance

**Given** actual attendance records\
**When** the student adds hypothetical future Present and Absent
sessions in the simulator\
**Then** projected attendance reflects those sessions\
**And** saved attendance records remain unchanged after the scenario is
cleared or the student exits.

### Scenario L: Archive a subject

**Given** a subject with historical sessions\
**When** the student archives it\
**Then** the subject and its history remain available for historical
calculations\
**And** no new sessions can be added to it.

### Scenario M: Local backup and restore

**Given** attendance data exists\
**When** the student exports a backup and then restores it on a fresh
installation\
**Then** all semesters, subjects, and sessions are restored correctly\
**And** attendance calculations match the original data.

## 14. Minimum automated test coverage

Before MVP release, automated tests must cover:

### Calculation unit tests

-   Raw Combined percentage.
-   Component Average percentage.
-   Zero conducted sessions.
-   One enabled component.
-   Two enabled components with one component having zero sessions.
-   Threshold equality.
-   Safe-absence boundary and one-more-absence failure.
-   Recovery boundary and one-fewer-attendance failure.
-   100% threshold behavior.
-   Floating-point boundary behavior.

### Domain and data tests

-   Multiple sessions for the same subject/component/date.
-   Session edit replaces prior contribution.
-   Session deletion removes contribution.
-   Disabled component cannot receive new sessions.
-   Historical records remain available after archiving.
-   Semester method and threshold changes recalculate derived values.

### UI and flow tests

-   Semester creation and validation.
-   Subject creation and component selection.
-   Present/Absent logging.
-   Past-date logging and editing.
-   Calendar empty state.
-   Dashboard and subject detail refresh.
-   Simulator does not persist hypothetical sessions.
-   Error and loading states.

## 15. Explicitly unresolved implementation decisions

These must be decided in the relevant technical documents or before the
related feature is implemented. Do not silently assume an answer:

1.  Exact backup file format and restore policy (replace vs. merge).
2.  Minimum supported Android and iOS versions.
3.  Exact navigation pattern and visual component behavior.
4.  Whether a subject-specific threshold is needed later. The MVP uses
    the semester threshold.
5.  Whether semester dates are required. They are optional in the MVP
    and must not restrict backdated logging.
6.  Whether students can permanently delete archived semesters or
    subjects. Not required for the MVP.

------------------------------------------------------------------------

**Implementation rule:** Any screen or feature that displays attendance
must consume the same calculation rules and derived domain results. Do
not reimplement attendance math inside individual UI screens.
