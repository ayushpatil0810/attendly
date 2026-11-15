# DESIGN.md

## 1. Purpose

This document defines the visual design system, interaction patterns, screen composition, motion principles, and UX standards for the College Attendance Tracker.

It is the design source of truth for implementation. Follow it consistently across screens and features. Do not invent a generic dashboard, apply default Flutter styling, or treat this document as a loose mood board.

The product is a personal, offline-only college attendance tracker for students. Its interface should feel like a carefully art-directed consumer mobile app: clean, colorful, friendly, confident, and professionally composed.

## 2. Product design principles

### 2.1 The intended personality

The visual direction is **soft, colorful, modern minimalism**, using the user's supplied visual reference as the primary inspiration.

The app should feel:
- Approachable and youthful, but not childish.
- Visually expressive, but not noisy.
- Minimal, but not empty or monochrome.
- Data-rich where useful, but easy to scan.
- Distinctive and intentional, not like a default UI kit or an AI-generated template.

### 2.2 Core principles

1. **Clarity before decoration.** Every visual element must help the user understand something or complete an action.
2. **Fast attendance entry.** Daily attendance logging must take as few taps as reasonably possible.
3. **Open compositions.** Use whitespace, typography, alignment, color, and separators to organize information. Do not put every element inside a card or rectangle.
4. **Visual-first communication.** Use progress indicators, charts, labels, and concise numbers instead of paragraphs.
5. **Purposeful color.** Use the pastel brand palette consistently; do not make the interface monochrome.
6. **Motion with restraint.** Use smooth, balanced animations and micro-interactions that reinforce feedback and orientation.
7. **Honest data states.** Never make unavailable or provisional attendance look like a definitive percentage.
8. **One-handed usability.** Prioritize reachable actions and comfortable touch targets.
9. **Consistency without repetition.** Reuse design tokens and interaction patterns, but allow each screen to have a composition suited to its content.

## 3. Visual direction and reference

Use the user-provided screenshot as the primary visual reference for:
- A soft pastel color atmosphere.
- Rounded, friendly visual elements.
- A clear, approachable dashboard hierarchy.
- Expressive but restrained color accents.
- A contemporary mobile-product feel.

Adapt the reference to attendance tracking. Do not copy unrelated task-management content or force its exact layout onto every screen.

The app must not look like a generic template. Avoid:
- Repeating identical rounded cards for every section.
- A grid of boxes containing every statistic.
- Excessive pill-shaped controls.
- Gradients on every surface.
- Heavy drop shadows.
- Random decorative blobs, sparkles, or floating shapes.
- Overuse of emoji.
- Long explanatory copy.
- Default Material component styling.

## 4. Color system

The initial release is **light theme only**. Do not implement a dark theme as part of this design scope.

### 4.1 Brand palette

Use these initial design tokens. They may be tuned during implementation for contrast and visual balance, but preserve their roles and overall character.

| Token | Hex | Role |
|---|---|---|
| `brandViolet` | `#9278F2` | Primary brand accent, selected navigation, primary interactive states |
| `brandMint` | `#8BE4D0` | Positive attendance, healthy progress, positive chart series |
| `brandCoral` | `#FF929B` | Absence, attention-needed states, selected emphasis |
| `brandPeach` | `#FFB49F` | Secondary highlight, supporting chart series |
| `lavender` | `#B9A0F2` | Soft violet tint, secondary surfaces |
| `warmWhite` | `#FFFAF9` | Main screen surface / warm white base |
| `softLavender` | `#F5F1FF` | Subtle tinted surface |
| `softMint` | `#F0FAF7` | Positive tinted surface |
| `softCoral` | `#FFF1F1` | Warning/absence tinted surface |
| `ink` | `#30263F` | Primary text |
| `mutedInk` | `#827B8D` | Secondary text |
| `divider` | `#EEE6EB` | Subtle separators |
| `track` | `#EEEAF2` | Progress track and chart guides |

### 4.2 Color usage

- Use white or warm-white as the dominant background.
- Violet is the main brand and interaction color.
- Mint communicates positive attendance or healthy progress.
- Coral communicates absence or attention-needed states.
- Peach is a supporting accent, not a substitute for warning color.
- Use pastel-tinted surfaces selectively to create grouping.
- Gradients are accents, not default backgrounds. Use them sparingly on selected hero moments, onboarding artwork, or brand surfaces.
- Do not use color alone to communicate status. Pair status colors with text, icons, or other visual cues.
- Check text/background contrast. If a pastel color is too light for readable text, use a darker foreground color rather than darkening every surface.

### 4.3 Attendance status semantics

Use the same semantic mapping everywhere:
- Present / positive: mint family.
- Absent / attention: coral family.
- Neutral / not recorded / unavailable: neutral ink and surface colors.
- Primary actions / selected state: violet family.

A session that does not exist is not an absence. The UI must never imply that an unrecorded class was missed.

## 5. Typography

### 5.1 Primary typeface

Use **Plus Jakarta Sans** as the primary application typeface.

Reasons:
- Contemporary and friendly without feeling generic.
- Distinctive geometric character.
- Works well for headings, compact labels, and numerical dashboards.
- Suitable for a polished consumer app.

Bundle the font locally with the application so the interface does not depend on a network connection.

### 5.2 Typographic hierarchy

Use a small, consistent type scale. Suggested starting points:

| Role | Suggested size | Weight |
|---|---:|---|
| Large hero metric | 32–40 sp | Semibold / Bold |
| Screen title | 24–28 sp | Semibold |
| Section title | 17–20 sp | Semibold |
| Card or row title | 14–16 sp | Medium / Semibold |
| Body | 14–16 sp | Regular |
| Supporting label | 12–13 sp | Medium |
| Small metadata | 11–12 sp | Regular / Medium |

These are starting values, not rigid rules. Keep text readable and avoid shrinking labels to fit crowded layouts.

Use tabular numerals for attendance percentages, counts, and other changing numeric values where supported. This prevents layout shifts when values update.

### 5.3 Copy style

- Keep UI copy short, direct, and human.
- Prefer labels and concise phrases over explanatory paragraphs.
- Do not explain obvious features on the screen.
- Use descriptions only when they prevent confusion or help the user make a decision.
- Avoid robotic phrases, generic motivational slogans, and excessive exclamation marks.
- Use consistent terms: semester, subject, lecture, lab, present, absent, conducted, attendance threshold.

## 6. Layout, spacing, and surfaces

### 6.1 Composition

Use an 8-point spacing rhythm as the primary layout guide. A practical spacing set is 4, 8, 12, 16, 20, 24, 32, and 40 logical pixels.

Respect device safe areas and system insets. Design for common phone widths and test narrow devices as well as larger phones.

### 6.2 Do not put everything in cards

This is a high-priority design requirement.

- Cards are optional grouping devices, not the default container for every section.
- Use open layouts for headings, statistics, subject lists, and charts where possible.
- Use whitespace, typography, alignment, and subtle dividers to separate content.
- Reserve filled or bordered surfaces for content that genuinely needs visual grouping, emphasis, or interaction.
- Avoid wrapping every statistic in its own rectangle.
- Avoid repeating the same card shape and padding down the entire screen.
- Do not use a card grid merely because it is easy to implement.

A screen should have a deliberate composition and visual rhythm. Some elements may sit directly on the page background; others may use a tinted surface. Use contrast and spacing to create hierarchy.

### 6.3 Shape and elevation

- Use rounded corners selectively, with a consistent radius scale.
- Use larger radii for prominent grouped surfaces and smaller radii for compact controls.
- Avoid making every control a pill.
- Keep shadows subtle and rare.
- Prefer surface contrast and spacing over elevation.
- Avoid heavy borders around every component.

## 7. Iconography and illustration

### 7.1 Icons

Use **Hugeicons** as the icon family throughout the application.

Implementation requirements:
- Use the appropriate Flutter Hugeicons package and supported icon assets for the project.
- Keep icon references centralized in a shared icon mapping or design-system layer where practical.
- Use a consistent visual style/weight across the app.
- Do not mix Hugeicons with Material Icons, Font Awesome, random SVG icon packs, or emoji as interface icons.
- Choose icons for recognizability, not decoration.
- Keep icon sizes and stroke/visual weight consistent within similar contexts.
- Pair less familiar icons with concise labels.

Do not choose or finalize the application logo or launcher icon in this document. Those will be decided separately later.

### 7.2 Illustrations

Use illustrations sparingly for onboarding and empty states if they materially improve the experience. They should use the same color language and feel custom to the product. Avoid generic stock illustrations and excessive decorative artwork.

## 8. Navigation

### 8.1 Main navigation

Use a **floating bottom navigation dock** on the main app sections.

Primary destinations:
1. Home
2. Subjects
3. Quick Log action (central, prominent action)
4. History
5. Insights

The dock should:
- Float above the bottom safe area with comfortable spacing from the screen edge.
- Have a clean, softly rounded surface.
- Use a subtle shadow or surface contrast only where needed to separate it from content.
- Clearly distinguish the active destination using violet.
- Keep inactive icons visually quiet.
- Use concise labels where they fit without crowding.
- Remain visually secondary to the screen's main content.

The central quick-log action should be visually prominent and easy to reach. It is an action, not a separate navigation destination.

### 8.2 Navigation behavior

- Use smooth, short transitions between main sections.
- Preserve sensible scroll position and screen state when switching tabs where appropriate.
- Do not animate every element independently during navigation.
- Ensure the floating dock does not cover scrollable content or primary actions.
- Hide or adapt the dock on focused full-screen flows when it would obstruct the task, such as onboarding or a dedicated setup flow.

## 9. Splash screen and first launch

### 9.1 Splash screen

The app must have a short, polished splash experience.

Requirements:
- Use the final app identity once the logo/name are decided.
- Until then, do not invent or lock in a logo or app name.
- Use a clean light surface and a restrained brand-color treatment.
- Include a brief, smooth scale/fade or similar restrained motion when appropriate.
- Keep it short. Do not force an artificial delay merely to show an animation.
- Startup and local database initialization must not be blocked by decorative animation.
- Handle startup errors with a useful recovery state rather than leaving the user on a blank splash screen.

### 9.2 Onboarding

Use **2–3 short introduction screens**, followed by semester setup.

The introduction should communicate only the core value:
- Track lecture and lab attendance.
- Understand attendance and safe absences.
- Review and correct attendance history.

Guidelines:
- One clear headline per screen.
- Very short supporting copy, only where useful.
- A simple visual or illustration, not a wall of text.
- Clear progress indication.
- Skip option if appropriate.
- A clear final action to begin setup.
- Do not make onboarding a tutorial for every feature.

### 9.3 Initial setup

After onboarding, guide the user directly into creating their first semester and adding subjects. Keep the setup flow focused and progressive. Ask only for information needed to start using the app. Use sensible defaults, including the default 75% attendance threshold and the selected default calculation method defined in product requirements.

## 10. Dashboard (Home)

The dashboard should be inspired by the user's supplied reference and the agreed design direction. It should feel friendly, visual, and information-rich without becoming crowded or card-heavy.

### 10.1 Information hierarchy

The dashboard should help the student answer:
1. What is my current overall attendance?
2. Am I above my required threshold?
3. Which subjects need attention?
4. How much room do I have for future absences, or what recovery is needed?
5. How has attendance been changing?

### 10.2 Suggested composition

Use this as a content hierarchy, not a rigid stack of cards:

1. **Greeting and semester context**
   - Brief greeting.
   - Current semester name and a compact semester switcher.
   - Avoid oversized decorative headers.

2. **Overall attendance hero**
   - Large percentage when a valid combined percentage is available.
   - A donut/ring or another clear progress visualization.
   - Show the required threshold for context.
   - Show a concise status such as above target or below target.
   - Include conducted/present/absent counts only if they fit naturally.

3. **Safe absences or recovery**
   - A compact, clearly labeled insight.
   - Do not show a misleading generic number for Component Average when future lecture/lab mix is unknown.
   - Explain assumptions briefly when necessary, such as assuming all future sessions are attended.

4. **Subjects preview**
   - Show a small number of relevant subjects (for example, the 3–4 most useful to surface) with a View all action.
   - Use inline progress bars or compact visual indicators.
   - Prioritize subjects needing attention where appropriate, while keeping ordering predictable and understandable.
   - Do not wrap every subject in a large identical card.

5. **Attendance trend**
   - Include a compact chart only when enough data exists to make it meaningful.
   - Label the time range.
   - Avoid showing a decorative graph with no interpretable scale or meaning.

6. **Quick log**
   - Keep the central dock action accessible.
   - A secondary dashboard action may be present if it improves discoverability, but avoid duplicating prominent calls to action unnecessarily.

### 10.3 Dashboard behavior

- Update visible values immediately after a session is created, edited, deleted, or undone.
- Use subtle number and progress transitions.
- Keep the first viewport focused on the most important attendance information.
- Allow the dashboard to scroll naturally.
- Do not force all dashboard sections into a uniform card pattern.

### 10.4 Empty dashboard

For a new user:
- Show a clear Create semester action.
- Use a short, friendly explanation only if needed.
- Do not show empty charts, zero-percent donut charts, or fake sample statistics.
- Guide the user into setup.

## 11. Attendance logging — highest-priority interaction

Attendance logging is the most frequently used and most important flow. Optimize it for speed, clarity, and one-handed use.

### 11.1 Entry point

The central `+` action in the floating bottom dock opens a compact bottom sheet or similarly quick surface. It should not send the user through a multi-screen form.

### 11.2 Default flow

1. Select a subject.
2. Select Lecture or Lab when both are enabled. If only one component is enabled, preselect it and avoid an unnecessary choice.
3. Tap Present or Absent.
4. Save immediately.

The date defaults to today. Provide a discreet way to change the date when needed, but keep historical corrections primarily in the History/Calendar section.

### 11.3 Immediate save and Undo

This is a confirmed product decision.

- Selecting Present or Absent saves the session immediately.
- Do not require a separate Save button.
- Show a brief success toast/snackbar with an Undo action.
- Undo reverses only the just-completed logging action.
- Update attendance summaries and charts immediately.
- Keep feedback visible long enough to use, but do not block the next action.
- Provide appropriate haptic feedback where supported.
- Do not show a confirmation dialog for ordinary valid attendance logging.

### 11.4 Duplicate protection and multiple sessions

Multiple sessions for the same subject, component, and date are valid and supported (for example, two Machine Learning lectures on the same day).

To prevent accidental double-submits:
- Debounce rapid repeated taps on the Present/Absent action targets.
- Provide clear immediate visual feedback (e.g. snackbar with session details and Undo action).
- If a session is already recorded for that subject/component today, entering another session clearly indicates that an additional session is being recorded.
- Provide easy access to Undo or the History view if an accidental duplicate session was added.

### 11.5 Quick logging UX details

- Put the most likely choices within easy thumb reach.
- Use large, clearly differentiated Present and Absent targets.
- Use both color and text/icon labels.
- Preserve the user's current semester context.
- Remember recent subject selection where appropriate, but never silently record against an unexpected subject.
- Keep the flow visually compact.
- Do not add explanatory paragraphs or unnecessary fields.

## 12. Subjects

The Subjects section contains the full subject list for the selected semester.

### 12.1 Subject list

Each subject row/item should communicate:
- Subject name.
- Overall subject attendance, when available.
- A compact progress visualization.
- A clear visual cue if attention is needed.

Use a clean list composition with varied emphasis where appropriate. Do not place every subject in a large boxed card.

### 12.2 Subject detail

The subject detail screen should provide:
- Subject attendance summary.
- Lecture and lab breakdown when enabled.
- Conducted, present, and absent counts.
- Attendance trend or history visualization when meaningful.
- Safe absence/recovery information only when the calculation method supports a reliable result.
- A clear way to open the subject's attendance history.
- A quick way to log a session for that subject.

If a component is enabled but has no recorded sessions, show Not available or an equivalent concise state. Do not display 0% as though classes were conducted and all were missed.

## 13. History and calendar

The History section is the primary place to review and correct attendance records, including historical dates.

### 13.1 Calendar overview

- Use a clean monthly calendar.
- Show visual attendance indicators on dates with recorded sessions.
- Distinguish days with present/absent records without overcrowding the calendar.
- Use a clear selected-date state.
- Provide month navigation with smooth, restrained transitions.
- Do not imply that a date without a record represents an absence.

### 13.2 Selected date

When a date is selected:
- Show the recorded sessions for that date.
- Display subject, component, and Present/Absent status.
- Allow the user to edit the status.
- Allow the user to delete an incorrectly recorded session.
- Allow the user to add a historical session for a subject/component enabled for that subject.
- Prevent accidental duplicate submissions while permitting legitimate repeated sessions on that date.
- Keep edit and delete actions clear and deliberate.

### 13.3 Editing and deletion

- Editing a record should be straightforward and should update analytics immediately.
- Deletion should require an appropriate confirmation or an easily reversible interaction; do not make destructive actions too easy to trigger accidentally.
- Provide clear feedback after successful changes.
- Do not put historical editing controls into the daily quick-log flow unless needed to resolve a duplicate.

## 14. Insights and analytics

The Insights section is for understanding attendance patterns, not for repeating the dashboard.

Use visualizations only when they answer a useful question.

Recommended visualizations:
- Overall attendance donut/ring with threshold marker.
- Subject comparison bars.
- Lecture versus lab comparison.
- Attendance trend over time.
- Calendar activity/attendance visualization.
- Simulator projection visualization.

### 14.1 Chart design

- Use the brand palette consistently.
- Use readable labels and a clear legend only when needed.
- Keep axes and gridlines subtle.
- Avoid 3D charts, decorative chart effects, excessive gradients, and needless animation.
- Ensure charts remain understandable on narrow screens.
- Provide a concise textual value or summary for accessibility.
- Use tooltips or tap details where they improve comprehension.
- Animate chart entry and updates with restraint.

### 14.2 Calculation transparency

- Use exact underlying values for comparisons; round only for display.
- Make the selected calculation method discoverable.
- Distinguish unavailable, provisional, and final combined results.
- For Component Average, when both components are enabled but one has no conducted sessions, do not fabricate a combined value.
- Do not show generic safe absences/recovery numbers when future component mix is required.

### 14.3 Simulator

The simulator allows the student to model hypothetical future lecture/lab sessions and Present/Absent outcomes.

Design requirements:
- Clearly label the experience as a simulation.
- Make it visually distinct from actual attendance history.
- Show projected attendance and threshold status.
- Make it easy to add/remove hypothetical sessions.
- Never save hypothetical sessions into the actual attendance database.
- Provide a clear reset/exit action.
- Keep controls compact and usable on mobile.

## 15. Motion and micro-interactions

Use **balanced animation intensity**. Motion should make the app feel responsive, polished, and delightful without becoming distracting or slowing down attendance entry.

### 15.1 Motion principles

- Short, purposeful, and consistent.
- Prefer easing that feels natural rather than mechanical.
- Avoid long entrance sequences.
- Avoid constant motion or attention-seeking loops.
- Do not animate every element on every screen.
- Never delay a user's action just to finish an animation.
- Respect the operating system's reduced-motion preference.

### 15.2 Recommended interactions

| Interaction | Motion / feedback |
|---|---|
| Splash | Brief logo/brand mark fade or scale treatment once identity is finalized |
| Onboarding | Smooth horizontal page transition and subtle illustration movement |
| Navigation | Short transition and restrained active-icon/state change |
| Bottom sheet | Smooth slide and fade |
| Present/Absent selection | Immediate selected-state color/scale transition and optional haptic |
| Attendance save | Brief success feedback and Undo toast |
| Undo | Subtle reversal feedback and updated values |
| Donut/progress ring | Smooth value transition when data changes |
| Dashboard metrics | Short count/value transition where it improves comprehension |
| Charts | Restrained reveal or update animation |
| Calendar | Smooth month change and selected-date feedback |
| Buttons | Small press-state response; no exaggerated bounce |
| Subject rows | Subtle pressed/selected feedback |

### 15.3 Motion duration guidance

Use these as approximate implementation ranges, not rigid rules:
- Micro-interaction: 100–180 ms.
- Selection/press feedback: 100–180 ms.
- Bottom sheet: 200–280 ms.
- Screen transition: 180–260 ms.
- Chart/progress transition: 250–450 ms, depending on complexity.

Use reduced or disabled motion when the platform accessibility setting requests it.

## 16. Feedback, errors, and empty states

Every important action needs clear feedback. Keep the wording short and actionable.

Examples:
- Attendance saved — Undo.
- Attendance already recorded for this subject and component.
- Changes saved.
- Session deleted.
- Could not save. Try again.
- No attendance recorded for this date.
- Not enough data yet.
- Combined attendance unavailable until both enabled components have sessions.

### 16.1 Empty states

Design intentional empty states for:
- No semesters.
- Semester with no subjects.
- Subject with no sessions.
- Empty calendar date.
- No trend data.
- No simulator entries.

Empty states should:
- Explain the state in one short sentence if explanation is needed.
- Offer one obvious next action.
- Avoid fake charts or invented data.
- Avoid large generic illustrations unless they add real value.

### 16.2 Error states

- Use plain language.
- Explain what the user can do next.
- Do not expose raw database errors or stack traces.
- Preserve entered information when an operation fails where possible.
- Because the app is offline-only, do not show network, connection, or cloud-sync states.

## 17. Accessibility and usability

- Use readable text sizes and sufficient contrast.
- Maintain comfortable touch targets (aim for at least 44–48 logical pixels for primary touch controls).
- Do not rely on color alone to convey Present/Absent or threshold status.
- Provide semantic labels for icons, charts, and interactive elements.
- Support system text scaling without clipping critical controls.
- Ensure focus and keyboard navigation work where relevant.
- Respect reduced-motion preferences.
- Keep primary actions reachable and usable one-handed.
- Use clear confirmation for destructive actions.

## 18. Flutter implementation requirements

### 18.1 Do not use the default Material look

Flutter may be used as the framework, but the application must not look like a stock Material sample.

- Do not rely on default Material 3 colors, component shapes, typography, elevation, or navigation styling.
- Do not use an uncustomized `NavigationBar`, `FloatingActionButton`, `Card`, `AppBar`, `SnackBar`, or default input decoration as the final visual treatment.
- Build custom-styled components or deeply theme the relevant Flutter primitives to match this design system.
- A component may use Flutter/Material infrastructure internally, but its rendered appearance and behavior must follow this document.
- Use the shared design tokens for colors, typography, spacing, radii, and motion.
- Keep UI components reusable, but do not force every screen into the same template.

### 18.2 Design system architecture

Create a shared design-system layer for:
- Color tokens and semantic colors.
- Typography and text styles.
- Spacing and layout constants.
- Radius and surface styles.
- Motion durations and curves.
- Shared buttons and selection controls.
- Floating bottom navigation dock.
- Toast/snackbar feedback.
- Progress indicators and chart styling.
- Hugeicons mappings.

Avoid scattering raw hex values, arbitrary padding, and one-off animation durations throughout feature screens.

### 18.3 Offline behavior

All UI assets required for core screens, fonts, and icons must be bundled locally. The app must remain fully usable without an internet connection. Do not add remote font loading, remote icon dependencies, or network-dependent design features.

## 19. Screen inventory

The implementation should apply this design language to at least the following screens:

1. Splash screen.
2. Onboarding introduction (2–3 screens).
3. First semester setup.
4. Subject creation/editing.
5. Home dashboard.
6. Quick attendance logging sheet.
7. Subjects list.
8. Subject detail.
9. History/calendar.
10. Selected-date session list.
11. Edit attendance session.
12. Insights/analytics.
13. Attendance simulator.
14. Settings (threshold, calculation method, backup/restore, app preferences).
15. Empty, loading, validation, and error states for relevant screens.

## 20. Design acceptance checklist

A screen is not considered complete until the following are checked:

### Visual quality
- [ ] Uses the agreed light color palette.
- [ ] Uses Plus Jakarta Sans consistently.
- [ ] Uses Hugeicons consistently.
- [ ] Does not look like default Flutter/Material UI.
- [ ] Has a deliberate visual hierarchy.
- [ ] Does not put every element inside a card or rectangle.
- [ ] Uses gradients and shadows selectively.
- [ ] Has balanced spacing and readable typography.
- [ ] Looks polished on narrow and larger phone screens.

### UX quality
- [ ] Primary task is obvious.
- [ ] Important actions are reachable and have comfortable touch targets.
- [ ] Attendance logging is fast and uses immediate save with Undo.
- [ ] Historical editing is available from the calendar/history experience.
- [ ] Empty and unavailable states are honest and understandable.
- [ ] No long or unnecessary explanatory copy.
- [ ] No fake attendance values or misleading visualizations.

### Motion and feedback
- [ ] Motion is purposeful and balanced.
- [ ] Important interactions provide clear feedback.
- [ ] Animations do not delay user actions.
- [ ] Reduced-motion preferences are respected.
- [ ] Haptics are used selectively and only where supported.

### Product consistency
- [ ] The same semantic colors mean the same thing across screens.
- [ ] The selected semester context is clear.
- [ ] Lecture and lab remain distinguishable.
- [ ] Unrecorded sessions are never presented as absences.
- [ ] Component Average unavailable/provisional states are represented correctly.
- [ ] Simulator data is clearly separated from actual records.
- [ ] The app works fully offline.

## 21. Explicit design decisions and deferred items

Confirmed:
- Light theme only for the initial design scope.
- White / warm-white primary background.
- Violet, mint, coral, and peach color palette.
- Plus Jakarta Sans.
- Hugeicons.
- Floating bottom navigation dock.
- Central quick-log action.
- 2–3 short onboarding screens, followed by semester setup.
- Balanced information density.
- Balanced animations and micro-interactions.
- Immediate attendance save with Undo.
- Calendar/history is the place to edit and delete historical attendance.
- Open compositions; do not wrap everything in cards.
- Short splash screen.

Deferred:
- Final application name.
- Logo and launcher icon.
- Final brand mark/illustration system.
- Dark theme.
- Any additional themes or custom user color schemes.

Do not invent or finalize deferred brand assets as part of implementation. Use neutral temporary placeholders only where the app cannot function without them, and keep them easy to replace.
