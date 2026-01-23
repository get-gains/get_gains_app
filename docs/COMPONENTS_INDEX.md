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
| Feedback | BottomSheet, Dialog, Progress | ✅ Complete |
| Navigation | NavBar, TopBar, ListTile | ✅ Complete |
| Data Display | *Coming Soon* | 🔄 Planned |

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

## Planned Components

> **Note**: Start a new session to document each component below.

### Data Display
- [ ] `AppImage` - Optimized image loading with placeholders
- [ ] `AppTable` - Data tables with sorting/filtering

### Input
- [ ] `AppSwitch` - Toggle switches
- [ ] `AppCheckbox` - Checkbox inputs
- [ ] `AppRadio` - Radio button groups
- [ ] `AppSlider` - Range input sliders
- [ ] `AppDatePicker` - Date selection

### Feedback
- [ ] `AppToast` - Toast notifications
- [ ] `AppSnackbar` - Snackbar messages

### Layout
- [ ] `AppTabs` - Tab navigation
- [ ] `AppEmptyState` - Empty state displays
- [ ] `AppErrorState` - Error state displays

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
    ├── BUTTON.md            # AppButton documentation
    ├── CARD.md              # AppCard documentation
    ├── TEXT_FIELD.md        # AppTextField documentation
    ├── AVATAR.md            # AppAvatar documentation
    ├── BADGE_CHIP.md        # AppBadge & AppChip documentation
    ├── BOTTOM_SHEET.md      # AppBottomSheet documentation
    ├── DIALOG.md            # AppDialog documentation
    ├── PROGRESS.md          # AppProgress documentation
    ├── NAVIGATION.md        # Navigation components
    └── LIST_TILE.md         # AppListTile documentation
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
