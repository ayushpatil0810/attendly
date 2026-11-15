# DATABASE.md

## 1. Purpose

This document defines the local database design for the College Attendance Tracker.

The application is **offline-only**. All student data is stored on the device in a local SQLite database managed through Drift. The app has no account system, remote backend, cloud database, or automatic cloud synchronization.

This document is the source of truth for:
- Local database entities and relationships
- Data types and constraints
- Attendance-session recording rules
- Calculation-method configuration
- Database migrations and integrity
- Local backup and restore expectations

## 2. Database technology

| Concern | Decision |
|---|---|
| Database | SQLite |
| Flutter integration | Drift |
| Persistence location | App-private device storage |
| Schema definition | Drift tables and generated code |
| Migrations | Explicit, versioned Drift migrations |
| Remote persistence | None |
| Authentication | None |
| Cloud synchronization | None |

Use Drift as the only persistence layer for application data. Repositories must access stored data through the local database; UI widgets and presentation providers must not issue raw SQL directly.

## 3. Design principles

1. **Local ownership:** semester, subject, settings, and attendance data belong to the local app installation.
2. **No inferred absences:** an attendance row exists only when the student explicitly records a class that was conducted.
3. **Historical editing:** users can create, update, and delete sessions for past dates.
4. **Separate components:** lecture and lab sessions remain distinguishable.
5. **Exact calculations:** store attendance as discrete present/absent records. Calculate percentages from counts; do not persist rounded percentages as authoritative data.
6. **Stable identity:** use generated integer primary keys or UUIDs consistently. This design uses integer primary keys internally.
7. **Referential integrity:** deleting a semester or subject must not leave orphaned records.
8. **Migration safety:** schema changes must preserve existing local data wherever possible.
9. **Backup portability:** provide a versioned local backup/export format so users can move or restore their data without a server.

## 4. Entity relationship overview

```text
Semester
  ├── Subject
  │     └── AttendanceSession
  └── SemesterSettings
```

- A semester contains one or more subjects.
- Each subject belongs to exactly one semester.
- Each attendance session belongs to exactly one subject.
- A session records one conducted class for one component on one calendar date.
- Semester settings store the attendance threshold and calculation method.

The semester settings may be stored directly on the `semesters` row. This avoids a one-to-one settings table unless settings later become substantially more complex.

## 5. Tables

### 5.1 `semesters`

Stores each academic semester created by the student.

| Column | SQLite type | Required | Description |
|---|---|---:|---|
| `id` | INTEGER | Yes | Primary key; auto-increment |
| `name` | TEXT | Yes | Student-defined semester name, e.g. `Semester 5` |
| `start_date` | TEXT | No | Optional semester start date, ISO `YYYY-MM-DD` |
| `end_date` | TEXT | No | Optional semester end date, ISO `YYYY-MM-DD` |
| `attendance_threshold` | REAL | Yes | Required attendance percentage as a decimal, e.g. `0.75` |
| `calculation_method` | TEXT | Yes | `raw_combined` or `component_average` |
| `created_at` | INTEGER | Yes | UTC Unix timestamp in milliseconds |
| `updated_at` | INTEGER | Yes | UTC Unix timestamp in milliseconds |
| `is_archived` | INTEGER | Yes | Boolean integer, default `0` |

**Constraints**
- `name` must not be blank after trimming.
- `attendance_threshold` must be greater than `0` and less than or equal to `1`.
- `calculation_method` must be one of:
  - `raw_combined`
  - `component_average`
- If both dates are present, `start_date` must be on or before `end_date`.
- `is_archived` must be `0` or `1`.

**Notes**
- Default `attendance_threshold` is `0.75` (75%).
- A semester can be archived without deleting its data.
- Archived semesters remain available for viewing; whether they can be edited is a product/UI decision, not a database limitation.

### 5.2 `subjects`

Stores subjects within a semester and which attendance components apply.

| Column | SQLite type | Required | Description |
|---|---|---:|---|
| `id` | INTEGER | Yes | Primary key; auto-increment |
| `semester_id` | INTEGER | Yes | Foreign key to `semesters.id` |
| `name` | TEXT | Yes | Subject name |
| `lecture_enabled` | INTEGER | Yes | Boolean integer, default `1` |
| `lab_enabled` | INTEGER | Yes | Boolean integer, default `0` |
| `sort_order` | INTEGER | Yes | User-defined display order, default `0` |
| `created_at` | INTEGER | Yes | UTC Unix timestamp in milliseconds |
| `updated_at` | INTEGER | Yes | UTC Unix timestamp in milliseconds |

**Constraints**
- `semester_id` references `semesters.id`.
- `name` must not be blank after trimming.
- At least one of `lecture_enabled` or `lab_enabled` must be `1`.
- Component flags must be `0` or `1`.

**Indexes**
- Index on `semester_id`.
- Optional unique index on `(semester_id, name)` if the product decides subject names must be unique within a semester. Do not add this constraint unless duplicate names are explicitly disallowed in the UI.

### 5.3 `attendance_sessions`

Stores one explicitly recorded, conducted class.

| Column | SQLite type | Required | Description |
|---|---|---:|---|
| `id` | INTEGER | Yes | Primary key; auto-increment |
| `subject_id` | INTEGER | Yes | Foreign key to `subjects.id` |
| `session_date` | TEXT | Yes | Local calendar date in ISO `YYYY-MM-DD` |
| `component` | TEXT | Yes | `lecture` or `lab` |
| `status` | TEXT | Yes | `present` or `absent` |
| `note` | TEXT | No | Optional student note |
| `created_at` | INTEGER | Yes | UTC Unix timestamp in milliseconds |
| `updated_at` | INTEGER | Yes | UTC Unix timestamp in milliseconds |

**Constraints**
- `subject_id` references `subjects.id`.
- `component` must be `lecture` or `lab`.
- `status` must be `present` or `absent`.
- A `lecture` session is allowed only when the subject has `lecture_enabled = 1`.
- A `lab` session is allowed only when the subject has `lab_enabled = 1`.
- `session_date` must be a valid ISO calendar date.
- `UNIQUE (subject_id, session_date, component)` constraint: duplicate attendance sessions for the same subject, date, and component are strictly rejected at the database level.
- `id` remains the primary key for auto-incrementing stable entity identification.

**Indexes**
- Unique index on `(subject_id, session_date, component)` (`idx_attendance_sessions_unique`).
- Index on `session_date` (`idx_attendance_sessions_date`) for calendar queries.

The composite unique constraint on `(subject_id, session_date, component)` enforces duplicate protection while supporting legitimate separate lecture and lab sessions on the same day. Accidental duplicate submissions are guarded in the presentation layer via debouncing, instant UI duplicate feedback, and undo actions.

**Important behavior**
- Creating a row means a class was conducted and the student recorded its attendance.
- `present` increments both conducted and attended counts.
- `absent` increments conducted count only.
- A class that did not happen, was not scheduled, or was not entered has no row and must not be counted as an absence.
- Editing a historical record updates the existing row; it must not create a duplicate.
- Deleting a row removes that session from all attendance calculations.

### 5.4 Optional future `app_metadata`

Do not create this table unless a concrete local requirement appears. Database version is already managed by Drift's schema version. If later needed, this table may hold non-user-facing local metadata such as a backup-import marker. It must not be used to store credentials or remote-sync state.

## 6. Attendance calculation data

Attendance totals and percentages are **derived data**. Do not store them as authoritative values in the database.

For each subject and component:

- `conducted_count` = count of all sessions for that subject and component.
- `present_count` = count of sessions whose status is `present`.
- `absent_count` = `conducted_count - present_count`.
- `attendance_percentage` = `present_count / conducted_count * 100`, when `conducted_count > 0`.
- If `conducted_count = 0`, percentage is unavailable (`null` / Not available), not `0%`.

### 6.1 Raw Combined method

For the semester, count all lecture and lab sessions equally:

\[
\text{Attendance} =
\frac{\text{Total Present Sessions}}{\text{Total Conducted Sessions}} \times 100
\]

A lecture and a lab each contribute one session to the numerator/denominator according to their status.

### 6.2 Component Average method

For a subject or semester where both components are enabled and have recorded sessions:

\[
\text{Combined Attendance} =
\frac{\text{Lecture Percentage} + \text{Lab Percentage}}{2}
\]

Rules:
- If only lecture is enabled, use lecture attendance.
- If only lab is enabled, use lab attendance.
- If both are enabled but either component has zero conducted sessions, combined attendance is **Not available**.
- In that case, the component with data may be displayed as provisional, but must not be treated as the final combined attendance.
- Never substitute `0%` or `100%` for a component with no recorded sessions.

The selected calculation method is stored on the semester. The domain layer owns all calculation logic; SQL may retrieve counts, but should not become the source of business-rule behavior.

## 7. Safe absences and recovery

These values are derived at runtime and are not stored.

For Raw Combined:
- Let `A` be present sessions, `C` be conducted sessions, and `t` be the threshold as a decimal.
- When currently at or above threshold, safe additional absences are:

\[
\max(0,\lfloor A/t - C \rfloor)
\]

- The implementation must verify the boundary: the returned number of absences must preserve the threshold, and one more absence must drop below it when applicable.
- When below threshold and `t < 1`, required consecutive future presents to recover are:

\[
\left\lceil \frac{tC-A}{1-t} \right\rceil
\]

- At a 100% threshold, if any absence exists, recovery through attendance alone is impossible.
- Recovery assumes every future session is attended and no further absences occur.

For Component Average, do not show a single generic safe-absence or recovery number without a specified future component mix. Use the simulator to model explicit future lecture/lab sessions.

## 8. Date and time storage

Attendance is associated with a **calendar date**, not a time of day.

- Store `session_date` as ISO `YYYY-MM-DD`.
- Treat it as a date-only value. Do not convert it to UTC or apply timezone offsets.
- Store audit timestamps (`created_at`, `updated_at`) as UTC Unix milliseconds.
- Convert audit timestamps to local time only for display.
- Validate dates using a real calendar-date parser; a regex alone is insufficient.

This prevents a session recorded near midnight from appearing on the previous or next date because of timezone conversion.

## 9. Relationships and deletion behavior

Enable SQLite foreign-key enforcement for every database connection.

Recommended deletion behavior:
- Deleting a semester: cascade-delete its subjects and their attendance sessions, after a clear confirmation in the UI.
- Deleting a subject: cascade-delete its attendance sessions, after a clear confirmation in the UI.
- Archiving a semester: retain all subjects and sessions.
- Deleting an attendance session: delete only that row.

Use Drift foreign-key declarations with `ON DELETE CASCADE` where supported by the chosen schema design. Test that foreign keys are enabled and cascades behave as expected.

## 10. Drift implementation guidance

Suggested Drift table classes:
- `Semesters`
- `Subjects`
- `AttendanceSessions`

Suggested database class:
- `AppDatabase`

Suggested repository boundaries:
- `SemesterRepository`
- `SubjectRepository`
- `AttendanceRepository`

Repository implementations should use Drift DAOs or typed database queries. Keep calculation rules in domain services rather than duplicating them in widgets, providers, or SQL statements.

Suggested query capabilities:
- List active semesters, ordered by most recently updated or a stable user-defined order.
- Fetch a semester with its subjects.
- Fetch subject sessions within a date range.
- Fetch attendance counts grouped by subject and component.
- Fetch sessions for a calendar month.
- Watch relevant records so dashboard and analytics update after create, edit, or delete operations.

Use transactions for operations that modify multiple related records. For example, any future bulk import must validate and write the imported dataset atomically or clearly report partial failure.

## 11. Local backup and restore

Because the app is offline-only, users need a way to protect their data from app deletion, device loss, or device migration.

The product should provide manual **Export Backup** and **Import/Restore Backup** functionality. A backup must be stored at a user-accessible location selected through the platform's file picker/share facilities. Do not silently upload backups.

### 11.1 Backup format

Use a documented, versioned JSON format rather than copying the live SQLite database file as the only supported backup format.

Suggested top-level structure:

```json
{
  "format": "college-attendance-tracker-backup",
  "formatVersion": 1,
  "exportedAt": "2026-01-01T12:00:00.000Z",
  "data": {
    "semesters": [],
    "subjects": [],
    "attendanceSessions": []
  }
}
```

The example is structural only. Define exact serialized field names and validation rules in the backup implementation.

Requirements:
- Include all user-created semesters, subjects, settings, and attendance sessions.
- Include the backup format version.
- Do not include generated database primary keys as the only identity mechanism if import needs to remap IDs safely. Either use stable export IDs or maintain an explicit old-to-new ID mapping during import.
- Validate the complete file before modifying the live database.
- Reject unsupported future format versions with a clear message.
- Use a transaction for restore.
- Offer a clear restore policy: replace existing local data, or merge only if a reliable duplicate-resolution strategy is implemented. Do not silently merge.
- Preserve date-only session values exactly.
- Never include secrets, credentials, or remote-service tokens.

### 11.2 Restore validation

Before writing:
- Verify the format identifier and supported version.
- Verify required arrays and field types.
- Validate threshold ranges and calculation-method enum values.
- Validate subject-to-semester references.
- Validate session-to-subject references.
- Validate component and status enum values.
- Validate that each subject enables the component of each imported session.
- Validate session integrity and reject malformed or corrupted records.
- Validate date strings as real dates.
- Enforce reasonable file-size and record-count limits to protect the app from malformed files.

If validation fails, leave the current database unchanged and show actionable feedback.

### 11.3 Backup privacy

Backups contain personal academic records. Explain this to the user before export and restore. The app should not transmit backup contents to any server. If encryption is added later, document key derivation, recovery implications, and compatibility before implementation; do not invent a password-recovery mechanism.

## 12. Migrations and schema versioning

Use Drift's `schemaVersion` and migration strategy.

Rules:
1. Increment `schemaVersion` for every schema change.
2. Implement explicit migrations from each supported previous version.
3. Never rely on destructive table recreation for normal upgrades.
4. Preserve existing semesters, subjects, and sessions.
5. Test migrations using a database created with the previous schema version.
6. Test both empty-database creation and upgrades containing realistic data.
7. Keep generated Drift code in sync with table definitions.
8. Document each migration in the project's changelog.

Potential future migration examples:
- Adding a subject color or icon.
- Adding session start/end times or period sequence tags.
- Adding optional semester metadata.
- Changing backup serialization independently of the SQLite schema.

A backup format version is separate from the SQLite schema version. They must not be conflated.

### 12.1 Migration history

- **Schema Version 1 (Phase 1):** Initial database structure containing `semesters`, `subjects`, and `attendance_sessions` tables with check constraints and foreign keys.
- **Schema Version 2 (Phase 2):** Added `UNIQUE (subject_id, session_date, component)` table constraint to `AttendanceSessions` with index `idx_attendance_sessions_unique` and added `idx_attendance_sessions_date` on `session_date` for fast calendar navigation. Upgrade migration preserves all existing v1 data.

## 13. Data integrity and validation

Enforce validation at both the application/domain boundary and, where practical, through SQLite constraints.

Minimum validation:
- Semester and subject names are non-empty after trimming.
- Threshold is in `(0, 1]`.
- Calculation method is a supported enum.
- A subject has at least one enabled component.
- Session component is enabled for its subject.
- Session status is `present` or `absent`.
- Session date is valid.
- Duplicate sessions are rejected with a helpful UI message.
- Foreign-key constraints are enabled.
- Updates refresh `updated_at`.

Do not permit a session row with an unknown or disabled component.

## 14. Performance considerations

The expected dataset is small for an individual student, but queries should still be indexed sensibly.

- Index foreign-key columns.
- Index session date and subject/date lookups.
- Use grouped count queries for analytics rather than loading all records unnecessarily.
- Avoid persisting cached percentages until profiling proves it necessary.
- If derived values are cached in the future, treat them as disposable and recompute them after any session or settings change.

## 15. Required database tests

### Schema and constraints
- A semester can be inserted and retrieved.
- Invalid threshold values are rejected.
- Invalid calculation methods are rejected.
- A subject must enable at least one component.
- A session cannot use a disabled component.
- Invalid session status/component values are rejected.
- Duplicate subject/date/component sessions are rejected.
- Foreign keys prevent orphaned records.

### Attendance semantics
- Present session increments conducted and present counts.
- Absent session increments conducted count only.
- No row means no class is counted.
- Deleting a session removes it from derived totals.
- Editing a session updates calculations.
- A component with no sessions has an unavailable percentage, not zero.

### Relationships
- Deleting a subject cascades to its sessions.
- Deleting a semester cascades to its subjects and sessions.
- Archiving a semester preserves its data.

### Dates
- A date-only session remains on the same calendar date across timezone changes.
- Past-date sessions can be inserted and edited.
- Month/calendar queries return the correct date range.

### Migrations and backups
- Fresh database creation succeeds.
- Each supported migration preserves existing data.
- Export includes all required data.
- Invalid backup import leaves the database unchanged.
- Restore correctly remaps relationships.
- Duplicate or malformed backup records are rejected.
- Replace restore follows the explicit confirmation policy.
- Exported data can be restored into a fresh installation.

## 16. Explicitly out of scope

The database must not include:
- Supabase or another hosted database
- Supabase Auth or any login/registration tables
- Remote user profiles
- Cloud synchronization queues
- Server-side row-level security policies
- Remote API cache tables
- Connectivity-dependent persistence behavior
- Analytics or telemetry tables that transmit student records

The app is a personal, device-local attendance tracker. Any future proposal to add online services requires an explicit product decision and updates to the product requirements, architecture, privacy model, and this document.
