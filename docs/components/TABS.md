# AppTabs

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Tab navigation component for switching between different views or content sections within the same context. Ideal for organizing related content like workout categories, stats periods, or settings sections.

---

## Variants

| Component | Purpose |
|-----------|---------|
| `AppTabs` | Standard horizontal tab bar |
| `AppTabBar` | Standalone tab bar without content |
| `AppScrollableTabs` | Horizontally scrollable tabs |
| `AppSegmentedTabs` | Pill/segment style tabs |
| `AppIconTabs` | Icon-only tabs |

---

## Specifications

### Tab Variants

| Variant | Style | Usage |
|---------|-------|-------|
| `underline` | Text with underline indicator | Default, content sections |
| `filled` | Filled background on selected | Emphasized selection |
| `segmented` | Pill/capsule buttons | Filters, toggles |
| `outlined` | Border around tabs | Secondary navigation |

### Size Variants

| Size | Height | Font | Usage |
|------|--------|------|-------|
| `sm` | 36px | `labelSmall` | Compact UIs |
| `md` | 44px | `labelMedium` | Default |
| `lg` | 52px | `labelLarge` | Prominent navigation |

### Indicator Styles

| Style | Appearance |
|-------|------------|
| `underline` | 2px line below text |
| `pill` | Rounded rectangle behind text |
| `dot` | Small dot below text |

### Styling

- **Active tab**: `primary` color
- **Inactive tab**: `mutedForeground` color
- **Indicator**: `primary` color, 2px height
- **Background**: Transparent or `surface1` for segmented
- **Divider**: Optional 1px `border` color below tabs
- **Border radius (segmented)**: `radiusFull`

### States

| State | Visual |
|-------|--------|
| Default | Muted text |
| Selected | Primary color, indicator visible |
| Hovered | Subtle background tint |
| Focused | Focus ring indicator |
| Disabled | 50% opacity |

### Animation

- **Tab switch**: `durationNormal` (200ms)
- **Indicator slide**: `curveDefault` (easeInOut)
- **Content fade**: `durationFast` (100ms)

---

## Implementation

```dart
// lib/widgets/app_tabs.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Tab bar style variants
enum AppTabVariant { underline, filled, segmented, outlined }

/// Tab bar size options
enum AppTabSize { sm, md, lg }

/// Indicator style for tabs
enum AppTabIndicator { underline, pill, dot }

/// A customizable tab bar component
///
/// Example:
/// ```dart
/// AppTabs(
///   tabs: ['All', 'Strength', 'Cardio', 'Flexibility'],
///   selectedIndex: _selectedIndex,
///   onChanged: (index) => setState(() => _selectedIndex = index),
/// )
/// ```
class AppTabs extends StatelessWidget {
  const AppTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.variant = AppTabVariant.underline,
    this.size = AppTabSize.md,
    this.indicator = AppTabIndicator.underline,
    this.isScrollable = false,
    this.showDivider = true,
    this.enabled = true,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final AppTabVariant variant;
  final AppTabSize size;
  final AppTabIndicator indicator;
  final bool isScrollable;
  final bool showDivider;
  final bool enabled;
}

/// Tab bar with icon tabs
class AppIconTabs extends StatelessWidget {
  const AppIconTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.variant = AppTabVariant.underline,
    this.size = AppTabSize.md,
    this.showLabels = false,
    this.enabled = true,
  });

  final List<AppIconTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final AppTabVariant variant;
  final AppTabSize size;
  final bool showLabels;
  final bool enabled;
}

/// Data class for icon tabs
class AppIconTab {
  const AppIconTab({
    required this.icon,
    this.selectedIcon,
    this.label,
    this.badge,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String? label;
  final String? badge;
}

/// Full tab view with content
class AppTabView extends StatefulWidget {
  const AppTabView({
    super.key,
    required this.tabs,
    required this.children,
    this.initialIndex = 0,
    this.variant = AppTabVariant.underline,
    this.size = AppTabSize.md,
    this.isScrollable = false,
    this.keepAlive = false,
    this.physics,
  });

  final List<String> tabs;
  final List<Widget> children;
  final int initialIndex;
  final AppTabVariant variant;
  final AppTabSize size;
  final bool isScrollable;
  final bool keepAlive;
  final ScrollPhysics? physics;
}
```

---

## Usage Examples

### Basic Tabs

```dart
int _selectedTab = 0;

AppTabs(
  tabs: ['All', 'Strength', 'Cardio', 'Flexibility'],
  selectedIndex: _selectedTab,
  onChanged: (index) => setState(() => _selectedTab = index),
)
```

### Segmented Style

```dart
AppTabs(
  tabs: ['Day', 'Week', 'Month', 'Year'],
  selectedIndex: _period,
  onChanged: (index) => setState(() => _period = index),
  variant: AppTabVariant.segmented,
)
```

### Scrollable Tabs

```dart
AppTabs(
  tabs: ['Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Core', 'Full Body'],
  selectedIndex: _muscleGroup,
  onChanged: (index) => setState(() => _muscleGroup = index),
  isScrollable: true,
)
```

### With Icons

```dart
AppIconTabs(
  tabs: [
    AppIconTab(icon: Icons.fitness_center, label: 'Workouts'),
    AppIconTab(icon: Icons.restaurant, label: 'Nutrition'),
    AppIconTab(icon: Icons.trending_up, label: 'Progress'),
    AppIconTab(icon: Icons.person, label: 'Profile'),
  ],
  selectedIndex: _selectedTab,
  onChanged: (index) => setState(() => _selectedTab = index),
  showLabels: true,
)
```

### Icon Tabs with Badges

```dart
AppIconTabs(
  tabs: [
    AppIconTab(icon: Icons.home_outlined, selectedIcon: Icons.home),
    AppIconTab(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      badge: '3',
    ),
    AppIconTab(icon: Icons.settings_outlined, selectedIcon: Icons.settings),
  ],
  selectedIndex: _selectedTab,
  onChanged: (index) => setState(() => _selectedTab = index),
)
```

### Full Tab View

```dart
AppTabView(
  tabs: ['Overview', 'Exercises', 'History'],
  initialIndex: 0,
  children: [
    WorkoutOverviewTab(),
    ExerciseListTab(),
    WorkoutHistoryTab(),
  ],
)
```

### Different Sizes

```dart
// Small
AppTabs(
  tabs: ['S', 'M', 'L', 'XL'],
  selectedIndex: _size,
  onChanged: (i) => setState(() => _size = i),
  size: AppTabSize.sm,
  variant: AppTabVariant.segmented,
)

// Large
AppTabs(
  tabs: ['Workouts', 'Programs', 'Achievements'],
  selectedIndex: _section,
  onChanged: (i) => setState(() => _section = i),
  size: AppTabSize.lg,
)
```

### Filled Variant

```dart
AppTabs(
  tabs: ['Active', 'Completed', 'Archived'],
  selectedIndex: _filter,
  onChanged: (index) => setState(() => _filter = index),
  variant: AppTabVariant.filled,
)
```

### With Controller

```dart
class _MyWidgetState extends State<MyWidget> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTabs(
          tabs: ['Details', 'Reviews', 'Related'],
          selectedIndex: _tabController.index,
          onChanged: (index) {
            _tabController.animateTo(index);
            setState(() {});
          },
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              DetailsTab(),
              ReviewsTab(),
              RelatedTab(),
            ],
          ),
        ),
      ],
    );
  }
}
```

### Disabled Tabs

```dart
AppTabs(
  tabs: ['Free', 'Premium', 'Enterprise'],
  selectedIndex: _plan,
  onChanged: _isPremiumUser ? (i) => setState(() => _plan = i) : null,
  enabled: _isPremiumUser,
)
```

---

## Layout Patterns

### Tabs in App Bar

```dart
AppBar(
  title: Text('Workouts'),
  bottom: PreferredSize(
    preferredSize: Size.fromHeight(48),
    child: AppTabs(
      tabs: ['All', 'Favorites', 'Recent'],
      selectedIndex: _filter,
      onChanged: (i) => setState(() => _filter = i),
      showDivider: false,
    ),
  ),
)
```

### Tabs with Padding

```dart
Padding(
  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
  child: AppTabs(
    tabs: ['Today', 'This Week', 'This Month'],
    selectedIndex: _period,
    onChanged: (i) => setState(() => _period = i),
    variant: AppTabVariant.segmented,
  ),
)
```

### Tabs as Filter

```dart
Column(
  children: [
    AppTabs(
      tabs: ['All Exercises', 'Upper Body', 'Lower Body', 'Core'],
      selectedIndex: _filter,
      onChanged: (index) {
        setState(() => _filter = index);
        _loadExercises(_getFilterType(index));
      },
      isScrollable: true,
    ),
    SizedBox(height: AppTheme.spacing4),
    Expanded(
      child: ExerciseGrid(exercises: _filteredExercises),
    ),
  ],
)
```

---

## Accessibility

### Keyboard Navigation

- **Tab/Shift+Tab**: Move between tabs
- **Arrow keys**: Navigate adjacent tabs
- **Enter/Space**: Select focused tab
- **Home/End**: Jump to first/last tab

### Screen Reader Support

```dart
AppTabs(
  tabs: ['Overview', 'Details', 'Reviews'],
  selectedIndex: _selected,
  onChanged: (i) => setState(() => _selected = i),
  // Semantics automatically provided
)
```

### Considerations

- Each tab has semantic label
- Selected state announced
- Tab count announced (e.g., "Tab 2 of 4")
- Content changes announced when tab switches
- Focus visible on keyboard navigation

---

## Best Practices

1. **Keep tab labels short** - 1-2 words maximum
2. **Limit tab count** - 2-5 tabs, use scrollable for more
3. **Use consistent icons** - All or none, not mixed
4. **Order logically** - Most important/common first
5. **Consider persistence** - Save selected tab in state if appropriate
6. **Animate content** - Smooth transitions between tab content
7. **Handle empty states** - Show appropriate UI when tab has no content

---

## Related Components

- [AppNavigation](./NAVIGATION.md) - Bottom navigation for primary sections
- [AppButton](./BUTTON.md) - Toggle button groups
- [AppBadge](./BADGE_CHIP.md) - Badges on tab items
