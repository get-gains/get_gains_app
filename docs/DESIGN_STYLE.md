# Get Gains - Design System

> **Purpose**: This document serves as the single source of truth for all visual design decisions in the Get Gains Flutter application. Reference this guide when building any new page, feature, or component.

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Color Palette](#color-palette)
3. [Typography](#typography)
4. [Spacing System](#spacing-system)
5. [Border & Radius](#border--radius)
6. [Shadows & Elevation](#shadows--elevation)
7. [Component Patterns](#component-patterns)
8. [Variant Naming Conventions](#variant-naming-conventions)
9. [State Definitions](#state-definitions)
10. [Animation Guidelines](#animation-guidelines)
11. [Usage Guidelines](#usage-guidelines)

---

## Design Philosophy

The Get Gains app follows a **modern, sleek dark-first design** inspired by premium fintech and fitness applications. Key principles:

- **Dark Mode Primary**: Optimized for low-light environments and OLED screens
- **High Contrast**: Ensure readability with strategic color usage
- **Subtle Depth**: Use soft shadows and surface elevation for hierarchy
- **Warm Accents**: Coral/orange primary color adds energy and warmth
- **Clean Hierarchy**: Clear visual structure through typography and spacing
- **Rounded & Soft**: Generous border radius for approachable, modern feel

---

## Color Palette

### Dark Mode (Primary)

| Token | OKLCH Value | Hex Equivalent | Usage |
|-------|-------------|----------------|-------|
| `background` | `oklch(0.1448 0 0)` | `#1A1A1A` | Main app background |
| `foreground` | `oklch(1.0 0 0)` | `#FFFFFF` | Primary text on dark |
| `card` | `oklch(0.1822 0 0)` | `#252525` | Card/surface backgrounds |
| `cardForeground` | `oklch(1.0 0 0)` | `#FFFFFF` | Text on cards |
| `primary` | `oklch(0.6646 0.2046 37.76)` | `#E07D3B` | Primary actions, accents |
| `primaryForeground` | `oklch(1.0 0 0)` | `#FFFFFF` | Text on primary |
| `secondary` | `oklch(0.2393 0 0)` | `#363636` | Secondary surfaces, subtle elements |
| `secondaryForeground` | `oklch(1.0 0 0)` | `#FFFFFF` | Text on secondary |
| `muted` | `oklch(0.2393 0 0)` | `#363636` | Disabled backgrounds, subtle fills |
| `mutedForeground` | `oklch(0.7118 0.0129 286.07)` | `#A1A1AA` | Secondary text, placeholders |
| `accent` | `oklch(0.7878 0.1792 153.68)` | `#4ADE80` | Success states, positive indicators |
| `accentForeground` | `oklch(1.0 0 0)` | `#FFFFFF` | Text on accent |
| `destructive` | `oklch(0.3958 0.1331 25.72)` | `#7F1D1D` | Error backgrounds (muted) |
| `destructiveForeground` | `oklch(1.0 0 0)` | `#FFFFFF` | Text on destructive |
| `border` | `oklch(0.2393 0 0)` | `#363636` | Default borders |
| `input` | `oklch(0.2393 0 0)` | `#363636` | Input field backgrounds |
| `ring` | `oklch(0.7351 0.168 40.25)` | `#E8844A` | Focus rings |

#### Extended Dark Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `surface0` | `#1A1A1A` | Base background |
| `surface1` | `#252525` | Elevated surface (cards) |
| `surface2` | `#2E2E2E` | Higher elevation (modals, popovers) |
| `surface3` | `#363636` | Highest elevation (dropdowns, tooltips) |
| `textPrimary` | `#FFFFFF` | Main text |
| `textSecondary` | `#A1A1AA` | Secondary/muted text |
| `textTertiary` | `#71717A` | Hints, captions |
| `success` | `#4ADE80` | Success states |
| `successMuted` | `#166534` | Success backgrounds |
| `warning` | `#FBBF24` | Warning states |
| `warningMuted` | `#854D0E` | Warning backgrounds |
| `error` | `#F87171` | Error states |
| `errorMuted` | `#7F1D1D` | Error backgrounds |

### Light Mode (Secondary)

| Token | OKLCH Value | Hex Equivalent | Usage |
|-------|-------------|----------------|-------|
| `background` | `oklch(0.9702 0 0)` | `#F5F5F5` | Main app background |
| `foreground` | `oklch(0.1448 0 0)` | `#1A1A1A` | Primary text on light |
| `card` | `oklch(1.0 0 0)` | `#FFFFFF` | Card/surface backgrounds |
| `cardForeground` | `oklch(0.1448 0 0)` | `#1A1A1A` | Text on cards |
| `primary` | `oklch(0.7351 0.168 40.25)` | `#E8844A` | Primary actions, accents |
| `primaryForeground` | `oklch(1.0 0 0)` | `#FFFFFF` | Text on primary |
| `secondary` | `oklch(0.9276 0.0058 264.53)` | `#E4E4E7` | Secondary surfaces |
| `secondaryForeground` | `oklch(0.1448 0 0)` | `#1A1A1A` | Text on secondary |
| `muted` | `oklch(0.967 0.0029 264.54)` | `#F4F4F5` | Disabled backgrounds |
| `mutedForeground` | `oklch(0.551 0.0234 264.36)` | `#71717A` | Secondary text |
| `accent` | `oklch(0.9819 0.0181 155.83)` | `#ECFDF5` | Success backgrounds (light) |
| `accentForeground` | `oklch(0.4479 0.1083 151.33)` | `#166534` | Text on accent |
| `destructive` | `oklch(0.6368 0.2078 25.33)` | `#DC2626` | Error/destructive actions |
| `destructiveForeground` | `oklch(1.0 0 0)` | `#FFFFFF` | Text on destructive |
| `border` | `oklch(0.9276 0.0058 264.53)` | `#E4E4E7` | Default borders |
| `input` | `oklch(0.9276 0.0058 264.53)` | `#E4E4E7` | Input field borders |
| `ring` | `oklch(0.7351 0.168 40.25)` | `#E8844A` | Focus rings |

### Chart Colors

For data visualization consistency:

| Token | Dark Mode | Light Mode | Usage |
|-------|-----------|------------|-------|
| `chart1` | `#E8844A` | `#E8844A` | Primary data series |
| `chart2` | `#F5E6B3` | `#EAB308` | Secondary data series (cream/gold) |
| `chart3` | `#D4EDDA` | `#22C55E` | Tertiary (green) |
| `chart4` | `#D1E7F5` | `#3B82F6` | Quaternary (blue) |
| `chart5` | `#4A4A4A` | `#A855F7` | Quinary |

---

## Typography

### Font Families

```dart
// Primary font for UI
static const String fontFamilySans = 'Poppins';

// Serif font for editorial/feature content
static const String fontFamilySerif = 'Roboto Serif';

// Monospace for numbers, code
static const String fontFamilyMono = 'JetBrains Mono';
```

### Type Scale

| Style | Size | Weight | Line Height | Letter Spacing | Usage |
|-------|------|--------|-------------|----------------|-------|
| `displayLarge` | 48px | 700 | 1.1 | -0.02em | Hero numbers, splash |
| `displayMedium` | 36px | 700 | 1.15 | -0.01em | Large feature numbers |
| `displaySmall` | 32px | 600 | 1.2 | -0.01em | Section headers |
| `headlineLarge` | 28px | 600 | 1.25 | -0.01em | Page titles |
| `headlineMedium` | 24px | 600 | 1.3 | -0.01em | Card titles |
| `headlineSmall` | 20px | 600 | 1.35 | 0 | Subsection headers |
| `titleLarge` | 18px | 600 | 1.4 | 0 | List item titles |
| `titleMedium` | 16px | 500 | 1.45 | 0.01em | Emphasized body text |
| `titleSmall` | 14px | 500 | 1.4 | 0.01em | Labels, captions |
| `bodyLarge` | 16px | 400 | 1.5 | 0.01em | Primary body text |
| `bodyMedium` | 14px | 400 | 1.5 | 0.01em | Secondary body text |
| `bodySmall` | 12px | 400 | 1.4 | 0.02em | Captions, helper text |
| `labelLarge` | 14px | 500 | 1.4 | 0.02em | Button text |
| `labelMedium` | 12px | 500 | 1.35 | 0.02em | Chip text, badges |
| `labelSmall` | 10px | 500 | 1.3 | 0.03em | Tiny labels, overlines |

### Typography Usage Guidelines

```dart
// Large monetary values - Use mono for numbers
Text(
  '\$14,390.75',
  style: TextStyle(
    fontFamily: AppTypography.fontFamilyMono,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
  ),
)

// Greeting/names - Use sans-serif
Text(
  'Hi Michael',
  style: AppTypography.headlineLarge.copyWith(
    color: AppColors.foreground,
  ),
)

// Secondary info
Text(
  'You have 5 notifications',
  style: AppTypography.bodyMedium.copyWith(
    color: AppColors.mutedForeground,
  ),
)
```

---

## Spacing System

Based on a **4px base unit** with a standard scale:

| Token | Value | Usage |
|-------|-------|-------|
| `spacing-0` | 0px | No spacing |
| `spacing-1` | 4px | Tight inline spacing |
| `spacing-2` | 8px | Icon-to-text gaps |
| `spacing-3` | 12px | Compact element spacing |
| `spacing-4` | 16px | Standard element padding |
| `spacing-5` | 20px | Card internal padding |
| `spacing-6` | 24px | Section spacing |
| `spacing-8` | 32px | Large section gaps |
| `spacing-10` | 40px | Page section breaks |
| `spacing-12` | 48px | Major layout gaps |
| `spacing-16` | 64px | Hero sections |

### Common Patterns

```dart
// Screen padding
const EdgeInsets screenPadding = EdgeInsets.symmetric(
  horizontal: 20,  // spacing-5
  vertical: 16,    // spacing-4
);

// Card padding
const EdgeInsets cardPadding = EdgeInsets.all(20);  // spacing-5

// List item padding
const EdgeInsets listItemPadding = EdgeInsets.symmetric(
  horizontal: 16,  // spacing-4
  vertical: 12,    // spacing-3
);

// Button padding
const EdgeInsets buttonPadding = EdgeInsets.symmetric(
  horizontal: 24,  // spacing-6
  vertical: 16,    // spacing-4
);

// Compact button padding
const EdgeInsets buttonPaddingCompact = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 12,
);

// Gap between stacked elements
const double stackGap = 12;  // spacing-3

// Gap between sections
const double sectionGap = 24;  // spacing-6
```

---

## Border & Radius

### Border Radius Scale

| Token | Value | Usage |
|-------|-------|-------|
| `radius-none` | 0px | Sharp corners |
| `radius-sm` | 8px | Small elements (chips, badges) |
| `radius-md` | 12px | Buttons, inputs |
| `radius-lg` | 16px | Cards, containers |
| `radius-xl` | 20px | Large cards, modals |
| `radius-2xl` | 24px | Feature cards |
| `radius-full` | 9999px | Pills, avatars, circular buttons |

### Border Widths

| Token | Value | Usage |
|-------|-------|-------|
| `border-none` | 0px | No border |
| `border-thin` | 1px | Subtle dividers, default borders |
| `border-medium` | 2px | Focus states, active elements |
| `border-thick` | 3px | Heavy emphasis |

### Border Usage

```dart
// Card border (dark mode)
Border.all(
  color: AppColors.border,
  width: 1,
)

// Focus ring
Border.all(
  color: AppColors.ring,
  width: 2,
)

// Avatar circle
borderRadius: BorderRadius.circular(9999),
// or
shape: BoxShape.circle,
```

---

## Shadows & Elevation

### Dark Mode Shadows

Shadows in dark mode are more subtle and use lower opacity:

| Level | Definition | Usage |
|-------|------------|-------|
| `shadow-none` | None | Flat elements |
| `shadow-xs` | `0 1px 2px rgba(0,0,0,0.15)` | Subtle lift |
| `shadow-sm` | `0 2px 4px rgba(0,0,0,0.20)` | Cards, buttons |
| `shadow-md` | `0 4px 8px rgba(0,0,0,0.25)` | Dropdowns, popovers |
| `shadow-lg` | `0 8px 16px rgba(0,0,0,0.30)` | Modals, dialogs |
| `shadow-xl` | `0 12px 24px rgba(0,0,0,0.35)` | Toast notifications |

### Light Mode Shadows

| Level | Definition | Usage |
|-------|------------|-------|
| `shadow-none` | None | Flat elements |
| `shadow-xs` | `0 1px 2px rgba(0,0,0,0.03)` | Subtle lift |
| `shadow-sm` | `0 2px 4px rgba(0,0,0,0.05)` | Cards, buttons |
| `shadow-md` | `0 4px 8px rgba(0,0,0,0.08)` | Dropdowns, popovers |
| `shadow-lg` | `0 8px 16px rgba(0,0,0,0.10)` | Modals, dialogs |
| `shadow-xl` | `0 12px 24px rgba(0,0,0,0.15)` | Toast notifications |

### Implementation

```dart
// Card shadow (dark mode)
BoxDecoration(
  color: AppColors.card,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.20),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ],
)

// Elevated button shadow
BoxDecoration(
  color: AppColors.primary,
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.30),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
)
```

---

## Component Patterns

### Cards

Observed card patterns from reference:

1. **Credit Card Style**: Gradient background with rounded corners, balance display
2. **Transaction Card**: Horizontal layout, icon + text + amount
3. **Stats Card**: Large number with label, optional trend indicator
4. **Section Card**: Title + content grouping

```dart
// Base card structure
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
  ),
  child: content,
)
```

### Buttons

1. **Primary Filled**: Solid primary color background
2. **Secondary/Ghost**: Transparent with border or no border
3. **Pill Button**: Full radius, used for filters/tabs
4. **Icon Button**: Circular with icon only
5. **Destructive**: Error color for dangerous actions

### Avatars

- Circular shape with border
- Sizes: small (32px), medium (48px), large (64px)
- Stack pattern for multiple users

### Lists

- Consistent padding (16px horizontal, 12px vertical)
- Dividers between items (optional)
- Leading icon/avatar + title + subtitle + trailing element

### Charts

- Bar charts with rounded tops
- Cream/tan color (#F5E6B3) for data bars on dark
- Subtle grid lines or none
- Labels below x-axis

### Feedback & Notifications

**Preferred: AppToast (Top Overlay)**

For all user feedback messages (errors, success, warnings, info), use `AppToast` with top positioning. This provides:
- Non-intrusive notification that doesn't block content
- Slides down from top of screen
- Auto-dismisses after duration
- Supports swipe-to-dismiss
- Consistent cross-platform behavior

```dart
// ✅ Preferred - Use AppToast
AppToast.error(context, 'Failed to save changes');
AppToast.success(context, 'Workout completed!');
AppToast.warning(context, 'Connection unstable');
AppToast.info(context, 'New features available');

// ❌ Avoid - Don't use Snackbar
ScaffoldMessenger.of(context).showSnackBar(...);
```

**Toast Position**: Always use top position (default)

| Variant | Use Case |
|---------|----------|
| `error` | API failures, validation errors |
| `success` | Completed actions, saved data |
| `warning` | Degraded states, caution |
| `info` | Neutral information, tips |

---

## Variant Naming Conventions

Use consistent naming across all components:

### Visual Variants

| Name | Description |
|------|-------------|
| `primary` | Main action, filled with primary color |
| `secondary` | Supporting action, muted appearance |
| `ghost` | Minimal, transparent background |
| `outline` | Transparent with border |
| `destructive` | Dangerous/delete actions |
| `link` | Text-only, appears as link |

### Size Variants

| Name | Description |
|------|-------------|
| `xs` | Extra small (compact UIs) |
| `sm` | Small |
| `md` | Medium (default) |
| `lg` | Large |
| `xl` | Extra large |

### State Variants

| Name | Description |
|------|-------------|
| `default` | Normal resting state |
| `hover` | Mouse over (desktop) |
| `pressed` | Active/pressed |
| `focused` | Keyboard focused |
| `disabled` | Non-interactive |
| `loading` | Async operation in progress |
| `error` | Error state |
| `success` | Success state |

---

## State Definitions

### Interactive States

```dart
// Default state
backgroundColor: AppColors.primary,
foregroundColor: AppColors.primaryForeground,

// Hover state (desktop)
backgroundColor: AppColors.primary.withOpacity(0.9),
// or lighten/darken by 10%

// Pressed state
backgroundColor: AppColors.primary.withOpacity(0.8),
transform: Matrix4.translationValues(0, 1, 0), // slight press effect

// Focused state
decoration: BoxDecoration(
  // ... base styles
  border: Border.all(
    color: AppColors.ring,
    width: 2,
  ),
),

// Disabled state
opacity: 0.5,
// or specific disabled colors:
backgroundColor: AppColors.muted,
foregroundColor: AppColors.mutedForeground,
```

### Input States

```dart
// Default
border: Border.all(color: AppColors.border),
fillColor: AppColors.input,

// Focused
border: Border.all(color: AppColors.ring, width: 2),

// Error
border: Border.all(color: AppColors.error),
fillColor: AppColors.errorMuted.withOpacity(0.1),

// Disabled
fillColor: AppColors.muted,
textColor: AppColors.mutedForeground,
```

---

## Animation Guidelines

### Duration Scale

| Token | Value | Usage |
|-------|-------|-------|
| `duration-instant` | 0ms | Immediate feedback |
| `duration-fast` | 100ms | Micro-interactions |
| `duration-normal` | 200ms | Standard transitions |
| `duration-slow` | 300ms | Emphasis transitions |
| `duration-slower` | 400ms | Page transitions |

### Easing Curves

```dart
// Standard easing for most animations
curve: Curves.easeInOut,

// Enter animations (elements appearing)
curve: Curves.easeOut,

// Exit animations (elements disappearing)
curve: Curves.easeIn,

// Bounce/spring effects
curve: Curves.elasticOut,

// Decelerate (coming to rest)
curve: Curves.decelerate,
```

### Common Animations

```dart
// Button press feedback
AnimatedScale(
  scale: isPressed ? 0.98 : 1.0,
  duration: const Duration(milliseconds: 100),
  curve: Curves.easeInOut,
  child: button,
)

// Fade in element
AnimatedOpacity(
  opacity: isVisible ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeOut,
  child: content,
)

// Slide in from bottom
AnimatedSlide(
  offset: isVisible ? Offset.zero : const Offset(0, 0.1),
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOut,
  child: content,
)
```

---

## Usage Guidelines

### Applying the Design System

#### 1. Always Use Theme Colors

```dart
// ✅ Correct
color: Theme.of(context).colorScheme.primary,
// or
color: AppColors.primary,

// ❌ Avoid
color: Color(0xFFE8844A),
```

#### 2. Use Typography Scale

```dart
// ✅ Correct
style: Theme.of(context).textTheme.headlineMedium,
// or
style: AppTypography.headlineMedium,

// ❌ Avoid
style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
```

#### 3. Use Spacing Constants

```dart
// ✅ Correct
padding: AppSpacing.cardPadding,
// or
padding: const EdgeInsets.all(20),

// ❌ Avoid - magic numbers
padding: const EdgeInsets.all(17),
```

#### 4. Consistent Border Radius

```dart
// ✅ Correct
borderRadius: BorderRadius.circular(AppRadius.lg), // 16
// or
borderRadius: BorderRadius.circular(16),

// ❌ Avoid
borderRadius: BorderRadius.circular(13),
```

### Dark Mode First Development

When building components:

1. Design and test in dark mode first
2. Verify all colors have sufficient contrast
3. Test text readability at all sizes
4. Ensure touch targets are at least 44x44px
5. Add light mode colors after dark mode is complete

### Accessibility Checklist

- [ ] Text contrast ratio ≥ 4.5:1 for normal text
- [ ] Text contrast ratio ≥ 3:1 for large text
- [ ] Touch targets ≥ 44x44px
- [ ] Focus indicators visible
- [ ] Color not sole indicator of meaning
- [ ] Support for screen readers (Semantics)

---

## Quick Reference: Flutter Implementation

### Accessing Theme

```dart
// Get color scheme
final colors = Theme.of(context).colorScheme;
colors.primary
colors.onPrimary
colors.surface
colors.error

// Get text theme
final textTheme = Theme.of(context).textTheme;
textTheme.headlineMedium
textTheme.bodyLarge

// Use AppColors directly (for custom colors)
AppColors.card
AppColors.chart1
AppColors.success
```

### Theme Extension Example

```dart
// Define extension for custom colors
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color success;
  final Color warning;
  final Color chart1;
  final Color chart2;
  
  const AppColorsExtension({
    required this.success,
    required this.warning,
    required this.chart1,
    required this.chart2,
  });
  
  @override
  ThemeExtension<AppColorsExtension> copyWith({...}) {...}
  
  @override
  ThemeExtension<AppColorsExtension> lerp(...) {...}
}

// Access in widgets
final appColors = Theme.of(context).extension<AppColorsExtension>()!;
appColors.success
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-23 | Initial design system documentation |

---

> **Next Steps**: See `COMPONENTS.md` for detailed component implementations following this design system.
