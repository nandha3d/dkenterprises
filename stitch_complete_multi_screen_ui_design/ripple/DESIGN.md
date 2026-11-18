---
name: Ripple
colors:
  surface: '#FFFFFF'
  surface-dim: '#dcdad5'
  surface-bright: '#fbf9f4'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3ee'
  surface-container: '#f0eee9'
  surface-container-high: '#eae8e3'
  surface-container-highest: '#e4e2dd'
  on-surface: '#1b1c19'
  on-surface-variant: '#3f4946'
  inverse-surface: '#30312e'
  inverse-on-surface: '#f2f1ec'
  outline: '#6f7976'
  outline-variant: '#bec9c5'
  surface-tint: '#1f695e'
  primary: '#00443b'
  on-primary: '#ffffff'
  primary-container: '#0b5d52'
  on-primary-container: '#8dd3c5'
  inverse-primary: '#8ed4c5'
  secondary: '#4c6700'
  on-secondary: '#ffffff'
  secondary-container: '#c5ee66'
  on-secondary-container: '#506c00'
  tertiary: '#00452a'
  on-tertiary: '#ffffff'
  tertiary-container: '#005f3c'
  on-tertiary-container: '#61dda0'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a9f0e1'
  primary-fixed-dim: '#8ed4c5'
  on-primary-fixed: '#00201b'
  on-primary-fixed-variant: '#005046'
  secondary-fixed: '#c7f169'
  secondary-fixed-dim: '#acd44f'
  on-secondary-fixed: '#151f00'
  on-secondary-fixed-variant: '#394e00'
  tertiary-fixed: '#7ffaba'
  tertiary-fixed-dim: '#61dda0'
  on-tertiary-fixed: '#002112'
  on-tertiary-fixed-variant: '#005233'
  background: '#fbf9f4'
  on-background: '#1b1c19'
  surface-variant: '#e4e2dd'
  surface-tonal: '#ECEFEA'
  hairline: '#E3E1DA'
  ink: '#13201B'
  ink-muted: '#66736C'
  money-mint: '#1FA971'
  money-coral: '#E8505B'
  pending-honey: '#E9A23B'
  info-sky: '#2E90FA'
  critical-ruby: '#D92D20'
  role-driver-primary: '#0E8FB3'
  role-driver-action: '#FFC933'
  role-driver-canvas: '#F3F8FA'
  role-cafe-primary: '#C2542D'
  role-cafe-action: '#F4A62A'
  role-cafe-canvas: '#FBF4EA'
  role-cafe-ink: '#2B1B14'
  role-field-primary: '#3F7D58'
  role-field-action: '#C9F36A'
  dark-canvas: '#0E1512'
  dark-surface: '#17221D'
  dark-surface-tonal: '#1F2E27'
  dark-ink: '#EDF3EF'
  dark-ink-muted: '#93A39B'
typography:
  display-numeral:
    fontFamily: Manrope
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 52px
    letterSpacing: -0.03em
  display-numeral-mobile:
    fontFamily: Manrope
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 26px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-action:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 20px
    letterSpacing: 0.01em
  caption-meta:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  sublabel-regional:
    fontFamily: Noto Sans Tamil
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

The design system establishes a high-performance, human-centered operational framework engineered specifically for frontline enterprise operations—spanning warehouse logisticians, route drivers, cafe counter operators, and field agents. Moving intentionally away from sterile, intimidating industrial telemetry consoles and fragile SaaS aesthetics, the design system combines utilitarian clarity with grounded physical warmth.

### Visual Philosophy & Modern Movement
The visual language operates on a **Tactile Tonalism** paradigm:
- **No Decorative SaaS Tropes:** Explicitly forbids purple/indigo gradients, floating 3D glass blobs, frosted translucencies, and thin-bordered spreadsheet grids.
- **Physical Tonal Separation:** Structure and hierarchy are defined by stacked tonal paper layers rather than sharp container strokes. Elevated white containers sit effortlessly upon organic canvas tones (`#F5F3EE`).
- **High-Stress Ergonomics:** Interfaces are optimized for rapid one-handed physical interaction in glaring outdoor sunlight, humid retail counters, and moving transport cabins. Tap targets default to generous touch slabs, and vital operational totals are rendered in massive, tabular numerals.
- **Bilingual Functional Respect:** English operational strings are structurally paired with secondary script sub-labels (e.g., Tamil script via Noto Sans Tamil) to ensure frictionless readability across regional frontline field teams.

## Colors

The color architecture is built upon a warm, matte canvas system rather than cold sterile grays. Tonal contrast guides attention without visual fatigue.

### Core Canvas & Surface Logic
- **Canvas Paper (`#F5F3EE`):** The default root background layer. Evokes tactile physical manifest paper and suppresses optical glare under outdoor lighting.
- **Surface (`#FFFFFF`):** High-clarity elevated containers, bento cards, and interactive modal sheets.
- **Surface-2 Tonal (`#ECEFEA`):** Recessed structural groupings, icon backplates, and inactive pill tags.
- **Hairline (`#E3E1DA`):** Reserved exclusively for micro-receipt separators and tabular item dividers. Borders must never be used to encase primary cards.
- **Ink (`#13201B`):** Deep green-black typography delivering crisp contrast against light surfaces.

### Semantic Palette
Operational indicators require uncompromising clarity and cannot rely on color alone; every semantic status maps an icon and label to these tokens:
- **Money-in Mint (`#1FA971`):** Inflow revenue, verified geofences, confirmed delivery matches, and active "Paid" states.
- **Money-out Coral (`#E8505B`):** Shortages, cash drops, fuel expenses, and low-inventory thresholds.
- **Pending Honey (`#E9A23B`):** Cash handovers pending verification, offline queues, and discrepancy variances.
- **Info Sky (`#2E90FA`):** Telemetry updates, system notices, and dispatch milestones.
- **Critical Ruby (`#D92D20`):** Destructive actions, safety emergency alerts, trip cancellations, and security breaches.

### Dynamic Role Skins
While the operational components remain structurally identical across all modules, active CSS/theme tokens dynamically remap core accent colors based on operator role:
- **Admin (Deep Lagoon):** Primary `#0B5D52` with `#C9F36A` Lime accents for consolidated operational metrics.
- **Driver (Aqua Day):** Outdoor-optimized `#0E8FB3` top bars combined with ultra-high contrast `#FFC933` Sun-yellow action slabs set with `#13201B` Ink copy over a `#F3F8FA` cool canvas.
- **Cafe (Chai & Crema):** Food-service `#C2542D` Terracotta with `#F4A62A` Saffron action slabs and warm `#2B1B14` Cocoa typography over `#FBF4EA`.
- **Field Agent (Field Sage):** Earthy `#3F7D58` Sage anchored with `#C9F36A` Lime CTA touchpoints.

## Typography

The typographical engine leverages **Manrope** for primary interface elements and numerical readouts, configured with forced tabular numerals (`font-variant-numeric: tabular-nums`) across all inventory items, currency quantities, and telemetry tickers. **Noto Sans Tamil** delivers native linguistic parity for regional frontline field technicians.

### Numerical Representation & Formatting
- **Indian Number Grouping:** All financial data renders with the Rupee symbol (`₹`) using Indian comma notation (e.g., `₹1,48,500` and `₹24,30,000.00`).
- **Tabular Figures:** Numbers align along baseline monospaced widths to prevent visual hopping during real-time balance calculations and stock counters.
- **Timestamps & Dates:** Standardized as `12 Nov 2026` and `09:34:12 AM` to eliminate operational ambiguity during audit verifications.

### Bilingual Typographic Hierarchy
Whenever regional translations are active, bilingual labels adopt a structured vertical pairing: the primary English command is set in bold Manrope, underpinned by a muted Tamil translation in `Noto Sans Tamil` at 70% opacity directly below the label.

## Layout & Spacing

Designed around a standard mobile viewport baseline (390px × 844px), layouts emphasize dense thumb-reach zones, high-efficiency bento modules, and fixed margins.

### Mobile Grid Philosophy
- **Margins & Gutters:** Strict 16px (`1rem`) horizontal outer margins prevent accidental edge clips. Bento modules leverage a 12px (`0.75rem`) gutter (`gutter`) to preserve tight visual unity.
- **Hero Unit:** Every operational module begins with a single Hero Container encapsulating up to a maximum of 4 essential operational figures (e.g., Target Deliveries, Invoiced Cash, Diesel Telemetry, Outbox Sync Status).
- **Secondary Bento Grid:** Below the Hero module, metrics and quick-action shortcuts organize into flexible 2-column or 1-column bento blocks using the 12px gap.

### Touch Targets & Thumb-Zone Ergonomics
To ensure fail-safe interaction under demanding field conditions:
- **Admin Touch Targets:** Minimum 48px height.
- **Field & Driver Touch Targets:** Minimum 56px height for all interaction points.
- **Primary Attendance Punch Slabs:** Enforced 72px target height.
- **Stepper Counter Controls:** 64px squared/rounded interactive zones for single-handed incrementation.

## Elevation & Depth

Visual depth is achieved through tactile tonal stacking rather than heavy atmospheric drops or artificial lighting models.

### Flat Tonal Stacking
- **Canvas Base (Level 0):** Pure un-elevated background tone (`#F5F3EE` in Admin/Field, `#F3F8FA` in Driver, `#FBF4EA` in Cafe).
- **Card Tier (Level 1):** Solid white (`#FFFFFF`) containers resting directly on the canvas. Boundaries are felt purely through color transition without bounding borders.
- **Recessed Insets:** Visual nesting within white cards is produced using `#ECEFEA` tonal backings.

### Controlled Shadows
Box shadows are forbidden on standard content cards, data tables, and bento tiles. Shadows are strictly restricted to elevated interactive floating apparatus:
- **Floating Pill Bottom Navigation:** A single soft, ambient contact shadow: `box-shadow: 0 8px 24px -4px rgba(19, 32, 27, 0.08)`.
- **Bottom Slide-up Sheets:** `box-shadow: 0 -12px 32px -6px rgba(19, 32, 27, 0.12)`.

## Shapes

The shape hierarchy establishes clear semantic distinctions between containing vessels, input zones, and interactive actions.

### Structural Radius Hierarchy
- **Hero Metric Enclosures (28px):** Broad, expansive corners that ground the top of the interface and frame operational rollups.
- **Bento Modules & Content Cards (20px):** Structural cards, delivery stop tiles, invoice containers, and catalog modules.
- **Form Controls & Inputs (14px):** Interactive input fields, search filters, barcode containers, and dropdown triggers.
- **Interactive Action Slabs & Pills (9999px / Pill):** All primary touch buttons, floating bottom navigations, filter tags, and operational sync status capsules feature completely rounded ends.

## Components

### 1. Action Slabs & Buttons
- **Primary Full-Width Slabs:** Pill-shaped (`border-radius: 9999px`), 56px minimum height (72px for Punch In/Out). Solid role-based accent color (`#FFC933` for Driver, `#C9F36A` for Field, `#F4A62A` for Cafe, `#0B5D52` for Admin). Text is set in bold 16px `#13201B` Ink. Micro-scale down-press feedback (`transform: scale(0.98)`) on interaction.
- **Secondary Outlined Slabs:** Pill-shaped, transparent interior with a 1.5px border colored to the primary role tone. Never use generic gray borders.
- **Disabled State:** Filled with `#ECEFEA` tonal gray, text set in `#66736C` Muted ink at 50% opacity.

### 2. Floating Pill Bottom Navigation
- Anchored 16px above the device bottom home indicator.
- Height of exactly 64px, pill-radiused (`9999px`), background in pure `#FFFFFF` with a soft contact elevation.
- Contains 4 to 5 icon-and-label tabs. Active tab features a role-tinted pill indicator backing (`#ECEFEA` or role tint).

### 3. Status Capsules & Sync Badges
- Pill enclosure with 6px vertical, 12px horizontal padding.
- Strict multi-property requirement: **Icon + Text Label + Semantic Tint**.
- *Sync Indicator Examples:*
  - Synced: Mint background (`#E6F7F0`), Mint text (`#1FA971`), Checkmark icon.
  - Offline / Outbox Pending: Honey background (`#FDF5E8`), Honey text (`#E9A23B`), Cloud-pause icon.
  - Critical Discrepancy: Coral background (`#FDECEE`), Coral text (`#E8505B`), Warning-triangle icon.

### 4. Input Fields & Search Bars
- 52px total height with a 14px border radius.
- Background filled with `#FFFFFF` or `#ECEFEA` tone. No visible perimeter border in resting state.
- Focused state activates a crisp 2px inner ring using the active role color.

### 5. Hero Metric Modules
- Encapsulated within a 28px radius card. For Admin, rendered in `#0B5D52` Deep Lagoon with high-visibility `#C9F36A` Lime display numerals.
- Maximum 4 key statistics arranged in a clean horizontal or quad split.
- Numerals rendered in 40px/48px bold Manrope with tabular formatting (`₹` for Indian currency amounts).

### 6. Stepper Counter Controls
- Designed for rapid stock, crate, and canister tallying.
- 64px total height, containing rounded decrement (`-`) and increment (`+`) tonal buttons flanking a bold center tabular readout.
- Minimum 56px width on touch triggers to facilitate rapid tapping in motion.