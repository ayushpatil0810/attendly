# Changelog

All notable changes to the College Attendance Tracker are documented in this file.

This project uses a Keep a Changelog-style format. Entries describe user-visible behavior, important technical changes, and fixes. Dates use `YYYY-MM-DD`.

The project is currently in its pre-release development phase. Do not invent release history or claim features are complete until they have been implemented and verified.

## [Unreleased]

### Added
- Initial project documentation set covering product requirements, functional specification, technology stack, architecture, database, design, testing, and AI-agent working conventions.
- Product direction for an individual-student attendance tracker.
- Offline-only product constraint: student data is stored locally using Drift/SQLite; no login, hosted backend, or cloud synchronization.
- Product requirements for semester and subject management, separate lecture/lab attendance, historical attendance entry and editing, attendance analytics, configurable thresholds, and a hypothetical attendance simulator.
- Design direction for a light-theme interface with a white/warm-white background, violet/mint/coral/peach palette, Plus Jakarta Sans typography, Hugeicons, and a floating bottom navigation dock.
- UX direction for immediate attendance saving with Undo and calendar-based historical corrections.
- Local backup/export and restore/import requirements.

### Changed
- Reconciled all documentation files (`PRD.md`, `SPEC.md`, `TECH_STACK.md`, `ARCHITECTURE.md`, `DATABASE.md`, `DESIGN.md`, `TESTING.md`, `AGENTS.md`, `CHANGELOG.md`) to establish a 100% offline-only architecture using Drift/SQLite as the sole persistence source.
- Standardized local backup and restore requirements (versioned JSON export/import with validation and transactional rollback) across all documentation.

### Fixed

### Deprecated

### Removed
- Removed obsolete architecture decisions and documentation references to Supabase, Supabase Auth, PostgreSQL remote database, cloud synchronization queues, multi-device conflict resolution, and connectivity tracking from `PRD.md`, `SPEC.md`, `TECH_STACK.md`, `ARCHITECTURE.md`, and `TESTING.md`.

### Security

## Release notes guidelines

When making a change, update the `[Unreleased]` section under the appropriate heading.

Use these categories:
- **Added** — new user-facing features or capabilities.
- **Changed** — changes to existing behavior or design.
- **Fixed** — bug fixes.
- **Deprecated** — functionality that will be removed in a future release.
- **Removed** — removed functionality.
- **Security** — security and privacy-related changes.

When publishing a release:
1. Create a version heading using the project's chosen versioning scheme, for example `## [1.0.0] - YYYY-MM-DD`.
2. Move the relevant entries from `[Unreleased]` into that release section.
3. Leave a fresh `[Unreleased]` section at the top.
4. Ensure the release notes describe only changes that are actually implemented and validated.
5. Link release headings to repository tags only if the repository uses those tags.

## Contributor and AI-agent rules

- Keep entries concise and understandable to students and maintainers.
- Record meaningful behavior, schema, architecture, dependency, and design changes.
- Mention database migrations when a release changes the local database schema.
- Mention backup-format changes when export/import compatibility changes.
- Do not record routine formatting-only changes unless they are part of a significant maintenance release.
- Do not claim tests passed unless they were run.
- Do not include secrets, personal attendance records, or private device data.
- Keep the changelog consistent with `PRD.md`, `SPEC.md`, `DATABASE.md`, `DESIGN.md`, and `AGENTS.md`.
- The app is offline-only. Do not add changelog entries describing cloud sync, hosted authentication, or remote persistence unless the product direction is explicitly changed by the user.
