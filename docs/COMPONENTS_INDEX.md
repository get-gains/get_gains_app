# Component Library Index

> **Purpose**: Central hub for Get Gains reusable Flutter components. Each component is documented in its own file for maintainability and scalability.
>
> **Design Reference**: All components use tokens from [DESIGN_STYLE.md](./DESIGN_STYLE.md).

---

## Quick Reference

| Category | Components | Status |
|----------|-----------|--------|
| Core | Button, Card, TextField | ✅ Complete |
| Identity | Avatar, Badge, Chip | ✅ Complete |
| Feedback | BottomSheet, Dialog, Progress, Toast | ✅ Complete |
| Navigation | NavBar, TopBar, ListTile, Tabs | ✅ Complete |
| Input | Switch, Checkbox, Radio, Slider, DatePicker | ✅ Complete |
| Data Display | Image | ✅ Complete |
| Layout | EmptyState | ✅ Complete |

---

## Core Components

### [AppButton](./components/BUTTON.md)
Primary interactive element for user actions.

| Variant | Purpose |
|---------|---------|
| `primary` | Main CTA, highest visual priority |
| `secondary` | Supporting actions |
| `ghost` | Tertiary actions, minimal weight |
| `outline` | Secondary with defined boundaries |
| `destructive` | Dangerous/irreversible actions |
| `link` | Navigation, inline actions |
| `icon` | Compact icon-only buttons |
| `loading` | Async operation in progress |

**Sizes**: `sm` (36px) · `md` (44px) · `lg` (52px)

---

### [AppCard](./components/CARD.md)
Container for grouping related content with visual hierarchy.

| Variant | Purpose |
|---------|---------|
| `elevated` | Standard container with subtle elevation |
| `outlined` | Border emphasis, no fill |
| `flat` | Minimal, blends with background |
| `interactive` | Clickable cards (navigation, selection) |
| `gradient` | Feature cards, promotional content |

**Specialized**: `AppListItemCard` · `AppStatsCard`

**Sizes**: `sm` (12px padding) · `md` (20px) · `lg` (24px)

---

### [AppTextField](./components/TEXT_FIELD.md)
Text input component for forms and data entry.

| Variant | Purpose |
|---------|---------|
| `outlined` | Standard input with border |
| `filled` | Filled background, no visible border |
| `underlined` | Minimal, bottom border only |

**Specialized**: `password` · `search` · `textArea`

**States**: `normal` · `focused` · `error` · `disabled` · `success`

---

## Identity Components

### [AppAvatar](./components/AVATAR.md)
Displays user images, initials, or icons consistently.

| Variant | Purpose |
|---------|---------|
| `image` | User profile photos |
| `initials` | Fallback when no image |
| `icon` | Generic/action avatars |
| `custom` | Flexible content display |

**Sizes**: `xs` (24px) · `sm` (32px) · `md` (40px) · `lg` (48px) · `xl` (64px) · `xxl` (96px)

**Status**: `online` · `offline` · `away` · `busy`

---

### [AppBadge & AppChip](./components/BADGE_CHIP.md)
Status indicators and selection/filter elements.

**AppBadge Variants**:
`secondary` · `primary` · `success` · `warning` · `error` · `info` · `outline` · `dot`

**AppChip Variants**:
`filled` · `outlined` · `tonal`

---

## Feedback Components

### [AppBottomSheet](./components/BOTTOM_SHEET.md)
Modal sheets that slide up from the bottom.

| Variant | Purpose |
|---------|---------|
| `standard` | Custom content container |
| `confirm` | Confirmation dialogs |
| `action` | List of options/actions |

**Helpers**: `showAppBottomSheet` · `showAppConfirmSheet` · `showAppActionSheet`

---

### [AppDialog](./components/DIALOG.md)
Modal dialogs for alerts, confirmations, and input.

| Variant | Purpose |
|---------|---------|
| `alert` | Information display |
| `confirm` | User confirmation |
| `input` | Text input collection |
| `selection` | Single selection from list |
| `loading` | Async operation indicator |

**Helpers**: `showAppAlertDialog` · `showAppConfirmDialog` · `showAppInputDialog` · `showAppSelectionDialog` · `showAppLoadingDialog`

---

### [AppProgress](./components/PROGRESS.md)
Visual indicators for progress, loading, and multi-step flows.

| Variant | Purpose |
|---------|---------|
| `linear` | Progress along a track |
| `circular` | Compact progress indicator |
| `ring` | Goal/stat display with center content |
| `step` | Multi-step flow indicator |
| `skeleton` | Loading placeholder with shimmer |

---
### [AppToast](./components/TOAST.md)
Non-intrusive notifications for brief feedback.

| Variant | Purpose |
|---------|----------|
| `info` | Neutral information |
| `success` | Positive feedback |
| `warning` | Caution messages |
| `error` | Error messages |

**Position**: `top` · `bottom`

**Helpers**: `AppToast.show` · `AppToast.success` · `AppToast.error` · `AppToast.warning` · `AppToast.info`

---
## Navigation Components

### [AppNavigation](./components/NAVIGATION.md)
App-wide navigation components.

| Component | Purpose |
|-----------|---------|
| `AppBottomNavBar` | Primary tab navigation |
| `AppTopBar` | Page header with actions |
| `AppSliverHeader` | Large scrollable header |

---

### [AppListTile](./components/LIST_TILE.md)
List item components for displaying data in lists.

| Variant | Purpose |
|---------|---------|
| `default` | Standard list item |
| `selectable` | Item with checkbox indicator |
| `menu` | Settings/menu style item |

**Grouping**: `AppListSection` · `AppListGroup`

**Density**: `compact` (44px) · `standard` (56px) · `comfortable` (72px)

---

## Input Components

### [AppSwitch](./components/SWITCH.md)
Toggle switch for binary on/off states with immediate effect.

| Variant | Purpose |
|---------|---------||
| `default` | Standard toggle switch |
| `labeled` | Switch with on/off labels |
| `icon` | Switch with icons for states |

**Companion**: `AppSwitchListTile` for settings lists

**Sizes**: `sm` (20px) · `md` (24px) · `lg` (28px)

---

### [AppCheckbox](./components/CHECKBOX.md)
Checkbox for selecting multiple items or acknowledging terms.

| Variant | Purpose |
|---------|---------|
| `default` | Standard checkbox with label |
| `indeterminate` | Parent with mixed child states |
| `card` | Checkbox within selectable card |

**Companion**: `AppCheckboxListTile` · `AppCheckboxGroup`

**Sizes**: `sm` (16px) · `md` (20px) · `lg` (24px)

---

### [AppRadio](./components/RADIO.md)
Radio buttons for single selection from mutually exclusive options.

| Variant | Purpose |
|---------|---------|
| `default` | Standard radio with label |
| `card` | Radio within selectable card |
| `segment` | Segmented control appearance |

**Companion**: `AppRadioListTile` · `AppRadioGroup` · `AppRadioCard`

**Sizes**: `sm` (16px) · `md` (20px) · `lg` (24px)

---
### [AppSlider](./components/SLIDER.md)
Input control for selecting values or ranges.

| Component | Purpose |
|-----------|----------|
| `AppSlider` | Single value selection |
| `AppRangeSlider` | Range selection (min/max) |
| `AppLabeledSlider` | Slider with header and value display |

**Sizes**: `sm` (2px track) · `md` (4px track) · `lg` (6px track)

---

## Layout Components

### [AppEmptyState](./components/EMPTY_STATE.md)
Display helpful feedback when there's no content to show.

| Variant | Purpose |
|---------|----------|
| `AppEmptyState` | Generic empty state |
| `AppSearchEmptyState` | No search results |
| `AppErrorState` | Error scenarios |
| `AppOfflineState` | Connection issues |

**Sizes**: `sm` (48px icon) · `md` (64px icon) · `lg` (96px icon)

---

## Data Display Components

### [AppImage](./components/IMAGE.md)
Optimized image loading with placeholders and error handling.

| Component | Purpose |
|-----------|---------|
| `AppImage` | Base image with loading/error states |
| `AppImage.network` | Network image loading |
| `AppImage.asset` | Asset image display |
| `AppImage.file` | File-based images |
| `AppImagePlaceholder` | Shimmer loading placeholder |

**Shapes**: `rectangle` · `rounded` · `roundedLg` · `circle`

**Sizes**: `thumbnail` (48px) · `small` (64px) · `medium` (120px) · `large` (200px) · `hero` (full width)

---

## Input Components (Extended)

### [AppDatePicker](./components/DATE_PICKER.md)
Date selection for scheduling and tracking.

| Component | Purpose |
|-----------|---------|
| `showAppDatePicker` | Date picker dialog |
| `showAppDateRangePicker` | Date range selection |
| `AppDateField` | Text field with picker |
| `AppDateChip` | Compact date display |
| `AppDateRangeChip` | Compact date range display |

**Variants**: `outlined` · `filled` · `underlined`

**Modes**: `calendar` · `input` · `calendarAndInput`

---

### [AppTabs](./components/TABS.md)
Tab navigation for content switching.

| Component | Purpose |
|-----------|---------|
| `AppTabs` | Standard horizontal tab bar |
| `AppIconTabs` | Icon-based tabs |
| `AppTabView` | Tabs with page content |

**Variants**: `underline` · `filled` · `segmented` · `outlined`

**Sizes**: `sm` (36px) · `md` (44px) · `lg` (52px)

---
## Planned Components

> **Note**: Start a new session to document each component below.

### Data Display
- [x] `AppImage` - Optimized image loading with placeholders ✅
- [ ] `AppTable` - Data tables with sorting/filtering

### Input
- [x] `AppSlider` - Range input sliders ✅
- [x] `AppDatePicker` - Date selection ✅

### Feedback
- [x] `AppToast` - Toast notifications ✅
- [ ] `AppSnackbar` - Snackbar messages

### Layout
- [x] `AppTabs` - Tab navigation ✅
- [x] `AppEmptyState` - Empty state displays ✅
- [x] `AppErrorState` - Error state displays ✅

---

## Design Token Reference

Quick reference to commonly used tokens from [DESIGN_STYLE.md](./DESIGN_STYLE.md):

### Colors
| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| `primary` | `#E07D3B` | `#E8844A` | Primary actions |
| `card` | `#252525` | `#FFFFFF` | Card backgrounds |
| `border` | `#363636` | `#E4E4E7` | Default borders |
| `ring` | `#E8844A` | `#E8844A` | Focus rings |

### Spacing
| Token | Value | Usage |
|-------|-------|-------|
| `spacing2` | 8px | Icon-to-text gaps |
| `spacing4` | 16px | Standard padding |
| `spacing5` | 20px | Card padding |
| `spacing6` | 24px | Section spacing |

### Radius
| Token | Value | Usage |
|-------|-------|-------|
| `radiusSm` | 8px | Chips, badges |
| `radiusMd` | 12px | Buttons, inputs |
| `radiusLg` | 16px | Cards |
| `radiusFull` | 9999px | Pills, avatars |

### Animation
| Token | Value | Usage |
|-------|-------|-------|
| `durationFast` | 100ms | Micro-interactions |
| `durationNormal` | 200ms | Standard transitions |
| `curveDefault` | `easeInOut` | Most animations |

---

## File Structure

```
docs/
├── DESIGN_STYLE.md          # Design tokens and guidelines
├── COMPONENTS_INDEX.md      # This file (hub)
├── CONTEXT.md               # Project architecture
└── components/
    ├── AVATAR.md            # AppAvatar documentation
    ├── BADGE_CHIP.md        # AppBadge & AppChip documentation
    ├── BOTTOM_SHEET.md      # AppBottomSheet documentation
    ├── BUTTON.md            # AppButton documentation
    ├── CARD.md              # AppCard documentation
    ├── CHECKBOX.md          # AppCheckbox documentation
    ├── DATE_PICKER.md       # AppDatePicker documentation
    ├── DIALOG.md            # AppDialog documentation
    ├── EMPTY_STATE.md       # AppEmptyState documentation
    ├── IMAGE.md             # AppImage documentation
    ├── LIST_TILE.md         # AppListTile documentation
    ├── NAVIGATION.md        # Navigation components
    ├── PROGRESS.md          # AppProgress documentation
    ├── RADIO.md             # AppRadio documentation
    ├── SLIDER.md            # AppSlider documentation
    ├── SWITCH.md            # AppSwitch documentation
    ├── TABS.md              # AppTabs documentation
    ├── TEXT_FIELD.md        # AppTextField documentation
    └── TOAST.md             # AppToast documentation
```

---

## Adding New Components

1. Create `docs/components/COMPONENT_NAME.md`
2. Follow the template structure (see any existing component file)
3. Add entry to this index under appropriate category
4. Cross-reference tokens from `DESIGN_STYLE.md`
5. Keep file under 500 lines

### Component File Template

```markdown
# ComponentName

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose
[Brief description]

## Variants
[Table or list of variants]

## Specifications
[Token references, not raw values]

## Implementation
[Dart code]

## Usage Examples
[Code snippets]

## Accessibility
[A11y notes]
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0.0 | 2026-01-23 | Modular structure with individual component files |
| 1.0.0 | 2026-01-23 | Initial monolithic COMPONENTS.md |
