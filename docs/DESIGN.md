# Attendly Design System (DESIGN.md)

## 1. Product Vision & UX Philosophy

**Attendly** is an autonomous, offline-first attendance companion engineered for college and university students.

The interface adheres to **Apple's Human Interface Guidelines (HIG)**:
- **Restraint & Purpose:** Every visual element serves a clear functional purpose. Zero decorative bloat, zero AI gimmicks, and zero cartoonish styling.
- **Apple HIG Inset Grouped Composition:** Content is structured into clean, rounded inset cards (`AppleInsetGroup`) separated by hairline dividers, framed against an authentic grouped canvas.
- **High Data Density with Calm Hierarchy:** Key academic metrics (attendance percentage, safe absences, recovery targets) are prominent, scannable, and rendered with tabular figures to eliminate layout shift.
- **Tactile iOS-Grade Fluidity:** Native rubber-band scrolling (`BouncingScrollPhysics`), subtle scale compression on tap (`AppMotion.pressScale = 0.97`), light haptic pulses (`HapticFeedback.lightImpact()`), and zero aggressive Material ripples.
- **Absolute Local Privacy:** 100% offline. Zero remote tracking, zero telemetry, and zero accounts.

---

## 2. Color Palette & Dual-Theme Architecture

Attendly provides strict theme parity across **Light** and **Dark** modes via `AppTheme`, `AppThemeColors`, and `AppPalettes`.

### 2.1 Theme Palette Specification

| Token Role | Light Theme (`#F2F2F7` Canvas) | Dark Theme (`#000000` True OLED) | Description |
| :--- | :--- | :--- | :--- |
| **`background`** | `#F2F2F7` | `#000000` | Apple Grouped Canvas background |
| **`surface`** | `#FFFFFF` | `#1C1C1E` | Pure White / Apple System Gray 6 card surface |
| **`surfaceSubtle`** | `#E5E5EA` | `#2C2C2E` | Secondary container & chip fill |
| **`surfaceElevated`** | `#FFFFFF` | `#2C2C2E` | Elevated modals, tooltips, dialogs |
| **`textPrimary`** | `#000000` | `#FFFFFF` | Primary headers, values, prominent titles |
| **`textSecondary`** | `#6C6C70` | `#98989D` | Subtitles, metadata, secondary captions |
| **`textTertiary`** | `#AEAEB2` | `#636366` | Placeholders, inactive icons, subtle hints |
| **`divider`** | `#C6C6C8` | `#38383A` | 0.5px hairline separators between inset rows |
| **`border`** | `#E5E5EA` | `#2C2C2E` | Subtle card & container outlines |
| **`track`** | `#E5E5EA` | `#2C2C2E` | Progress tracks & stepper backgrounds |

### 2.2 Canonical Semantic & Brand Accents

Attendly uses canonical Apple System color tokens:

| Semantic Token | Light Hex | Dark Hex | Semantic Meaning |
| :--- | :--- | :--- | :--- |
| **`brandPrimary`** | `#007AFF` | `#0A84FF` | Apple System Blue: Primary actions, active navigation, links |
| **`accentGreen`** | `#34C759` | `#30D158` | Apple System Green: Present session, safe attendance (> threshold) |
| **`accentRed`** | `#FF3B30` | `#FF453A` | Apple System Red: Absent session, critical attendance (< threshold) |
| **`accentOrange`** | `#FF9500` | `#FF9F0A` | Apple System Orange: Warning state, recovery needed, what-if simulator |
| **`systemPurple`** | `#5856D6` | `#5E5CE6` | Apple System Purple: Tools, backups, external links |
| **`systemGray`** | `#8E8E93` | `#8E8E93` | Apple System Gray: Neutral licenses, secondary icon tiles |

---

## 3. Typography System

The typography is rendered in **Plus Jakarta Sans** with negative optical tracking for headers and tabular figures for numbers.

### 3.1 Typographic Scale (`AppTypography`)

```
Scale Name      Size   Weight      Tracking   Line Ht  Primary Role
───────────────────────────────────────────────────────────────────────────────────
largeTitle      34pt   Bold (700)   -0.50     1.20     Hero screen milestone titles
title1          28pt   Bold (700)   -0.35     1.22     Section titles (tabular)
title2          22pt   Bold (700)   -0.25     1.25     Modal headers, secondary metrics
title3          20pt   SemiBold(600)-0.15     1.28     Card group headlines
headline        17pt   SemiBold(600)-0.35     1.32     List item titles, action labels
body            17pt   Regular(400) -0.35     1.45     Default readable body copy
callout         16pt   Regular(400) -0.25     1.40     Actionable tips, summaries
subhead         15pt   Regular(400) -0.20     1.35     Row subtitles, secondary labels
footnote        13pt   Regular(400) -0.10     1.30     Timestamps, badges, hints
caption1        12pt   Medium(500)  +0.10     1.35     Uppercase Inset Group headers
caption2        11pt   Regular(400) +0.10     1.30     Footers, copyright, micro-copy
```

### 3.2 Tabular Figures Rule
All numbers that change dynamically—attendance percentages (`82.4%`), conducted class counts (`14/17`), safe absence allowances, and timers—**must** use tabular figures (`FontFeature.tabularFigures()`) to prevent horizontal jitter during updates.

---

## 4. Spacing, Geometry & Radii

### 4.1 Spacing Rhythm (`AppSpacing`)
Follows an 8-point harmonic grid:
- `xxs`: `4.0` px
- `xs`: `8.0` px
- `sm`: `12.0` px
- `md`: `16.0` px (Standard content & card padding)
- `screenHorizontal`: `20.0` px (Standard left/right screen gutters)
- `xl`: `24.0` px (Section separation)
- `xxl`: `32.0` px
- `safeDockClearance`: `140.0` px (Bottom scroll clearance to float freely above the navigation dock)

### 4.2 Border Radii (`AppRadius`)
- `sm` (`8.0` px): `AppleIconTile` squircle containers, small tags, tooltips.
- `md` (`12.0` px): Form inputs (`AppTextField`), segmented control sliders.
- `lg` (`16.0` px): `AppleInsetGroup` card containers, dialogs.
- `xl` (`20.0` px): Hero summary cards, preview panels.
- `xxl` (`24.0` px): Modal sheet top corners (`AppRadius.sheetTop`).
- `pill` (`999.0` px): Floating dock, buttons, badge pills, sheet drag handle.

### 4.3 Concentric Geometry Rule
Nested curved containers follow strict concentric radii (`innerRadius = outerRadius - padding`):
- Floating Dock: `outerRadius` = 32px, `padding` = 6px, `innerRadius` = 26px.

---

## 5. Core Architectural Components

### 5.1 `AppleInsetGroup`
The primary layout pattern in Attendly.
- Uppercase header in `AppTypography.caption1` with 16px horizontal inset.
- Rounded container (`16px` radius) with `colors.surface` background and subtle hairline border.
- Automatically inserts 0.5px hairline dividers (`colors.divider`) between rows with a 16px left indent.

### 5.2 `AppleListTile` & `AppleIconTile`
- `AppleListTile`: Row component with leading widget, `title`, `subtitle`, trailing widget/badge, and disclosure arrow (`AppIcons.caretRight`).
- `AppleIconTile`: Standard Apple-style squircle (30×30px, 8px radius) with solid colored background (`brandPrimary`, `accentGreen`, `systemPurple`, etc.) and a centered 18px white icon.

### 5.3 `AppFloatingDock`
- Capsule navigation dock floating above the bottom edge.
- Glassmorphic backdrop filter with 16px gaussian blur (`BackdropFilter`).
- Concentric 32px pill geometry with hairline border and dual ambient drop shadows.
- Fluid active tab indicator with light haptic feedback.
- Central quick-action trigger (`+ Quick Log`).

### 5.4 `AppBottomSheet` (`showAppBottomSheet`)
- Modals slide from the bottom with top 24px rounded corners (`AppRadius.sheetTop`).
- Center drag handle pill (`36×4px`, `colors.divider`).
- Optional header row with bold title and `AppCloseButton`.
- Safe area keyboard insets handling (`viewInsets.bottom`).

### 5.5 `AppButton`
- Clean, accessible buttons (primary, secondary, outline, text, destructive).
- Minimum touch target: 44×44px (WCAG 2.5.5).
- Tactile spring scale compression on press (`AppMotion.pressScale = 0.97`).

---

## 6. Motion & Feedback Guidelines (`AppMotion`)

- **Scroll Physics:** Exclusively `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())` across all scroll views for natural iOS rubber-banding.
- **Haptics:** `HapticFeedback.lightImpact()` on all primary interactive moments:
  - Quick-log attendance logging (Present / Absent / Cancel)
  - Tab navigation switching
  - Inset tile taps and external link launches
  - Threshold slider increments
- **Transitions:**
  - Micro: `120ms` (Highlight and tap states)
  - Short: `180ms` (Segmented control slider transitions)
  - Medium: `260ms` (Card expand/collapse)
  - Sheet: `320ms` (Modal sheet entrance and exit)
- **Curves:** `Curves.easeOutCubic` for natural spring deceleration.
- **No Material Ripples:** `splashFactory: NoSplash.splashFactory` and `splashColor: Colors.transparent` across the entire app. Visual feedback uses subtle `highlightColor` overlays.

---

## 7. Accessibility & Inclusion

- **Contrast:** Every text and badge pairing strictly meets WCAG AA (minimum 4.5:1 for body, 3.0:1 for large headers).
- **Redundant Encoding:** Status is never communicated by color alone. Every attendance state is paired with an icon (`checkCircle`, `close`, `alert`) and clear textual status ("Present", "Absent", "Provisional").
- **Reduced Motion:** When `MediaQuery.disableAnimations` is enabled, all `AppMotion` durations collapse to `Duration.zero`.
