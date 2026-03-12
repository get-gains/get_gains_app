# AppEmptyState

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Display helpful feedback when there's no content to show. Used for empty lists, search results with no matches, initial states, errors, and offline scenarios.

---

## Variants

| Variant | Purpose |
|---------|---------|
| `AppEmptyState` | Generic empty state with icon, title, description, and actions |
| `AppSearchEmptyState` | Specialized for no search results |
| `AppErrorState` | Specialized for error scenarios |
| `AppOfflineState` | Specialized for connection issues |

---

## Specifications

### Size Variants

| Size | Icon Size | Container | Title Style | Usage |
|------|-----------|-----------|-------------|-------|
| `sm` | 48px | 80px | `titleMedium` | Cards, inline |
| `md` | 64px | 120px | `titleLarge` | Section empty states |
| `lg` | 96px | 160px | `headlineSmall` | Full page states |

### Styling

- **Icon container**: Circular, `secondary` color at 50% opacity
- **Icon color**: `mutedForeground` (customizable)
- **Title**: `foreground` color
- **Description**: `mutedForeground` color, max-width 280-320px
- **Spacing**: `spacing3` (sm), `spacing4` (md), `spacing6` (lg)

### Layout

```
┌─────────────────────────────┐
│                             │
│         ┌───────┐           │
│         │ ICON  │           │  Icon Container (circle)
│         └───────┘           │
│                             │
│          Title              │  Title text
│    Description text         │  Description (optional)
│    that may wrap lines      │
│                             │
│     [ Primary Action ]      │  Action button (optional)
│       Secondary Link        │  Secondary action (optional)
│                             │
└─────────────────────────────┘
```

---

## Implementation

```dart
// lib/widgets/app_empty_state.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import 'app_button.dart';

enum AppEmptyStateSize { sm, md, lg }

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.size = AppEmptyStateSize.md,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
    this.customIcon,
  });

  /// Compact size factory
  const AppEmptyState.compact({...}) : size = AppEmptyStateSize.sm;

  /// Full page size factory
  const AppEmptyState.fullPage({...}) : size = AppEmptyStateSize.lg;

  final IconData icon;
  final String title;
  final String? description;
  final AppEmptyStateSize size;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color? iconColor;
  final Widget? customIcon;

  // ... implementation
}
```

---

## Usage Examples

### Basic Empty State

```dart
AppEmptyState(
  icon: Icons.inbox_outlined,
  title: 'No messages yet',
  description: 'Your inbox is empty. Start a conversation!',
)
```

### With Action Button

```dart
AppEmptyState(
  icon: Icons.fitness_center,
  title: 'No workouts found',
  description: 'Create your first workout to get started on your fitness journey.',
  actionLabel: 'Create Workout',
  onAction: () => context.push('/workouts/create'),
)
```

### With Primary and Secondary Actions

```dart
AppEmptyState(
  icon: Icons.person_add_outlined,
  title: 'No friends yet',
  description: 'Connect with others to share your progress.',
  actionLabel: 'Find Friends',
  onAction: () => context.push('/friends/search'),
  secondaryActionLabel: 'Learn More',
  onSecondaryAction: () => showHelpDialog(context),
)
```

### Compact for Cards

```dart
AppCard(
  child: SizedBox(
    height: 200,
    child: Center(
      child: AppEmptyState.compact(
        icon: Icons.event_note_outlined,
        title: 'No upcoming events',
        description: 'Schedule workouts to see them here.',
      ),
    ),
  ),
)
```

### Full Page Empty State

```dart
Scaffold(
  appBar: AppBar(title: Text('Notifications')),
  body: Center(
    child: AppEmptyState.fullPage(
      icon: Icons.notifications_none_outlined,
      title: 'All caught up!',
      description: 'You have no new notifications.',
      actionLabel: 'Refresh',
      onAction: () => ref.refresh(notificationsProvider),
    ),
  ),
)
```

### Search Empty State

```dart
// When search returns no results
if (results.isEmpty)
  AppSearchEmptyState(
    query: searchController.text,
    onClear: () {
      searchController.clear();
      ref.invalidate(searchProvider);
    },
  )
```

### Error State

```dart
// When data loading fails
result.when(
  data: (data) => buildList(data),
  loading: () => AppCircularProgress(),
  error: (error, _) => AppErrorState(
    title: 'Failed to load workouts',
    description: error.toString(),
    onRetry: () => ref.refresh(workoutsProvider),
  ),
)
```

### Offline State

```dart
// When no network connection
if (!isConnected)
  AppOfflineState(
    onRetry: () async {
      final connected = await checkConnectivity();
      if (connected) ref.refresh(dataProvider);
    },
  )
```

### Custom Icon Widget

```dart
AppEmptyState(
  icon: Icons.add, // Fallback, not used when customIcon provided
  customIcon: Image.asset(
    'assets/images/empty_workout.png',
    width: 64,
    height: 64,
  ),
  title: 'Start your journey',
  description: 'Your workout history will appear here.',
  actionLabel: 'Get Started',
  onAction: () => context.push('/onboarding'),
)
```

### Custom Icon Color

```dart
AppEmptyState(
  icon: Icons.celebration_outlined,
  iconColor: AppColors.success,
  title: 'Goals completed!',
  description: 'You\'ve achieved all your goals for this week.',
)
```

---

## Specialized Components

### AppSearchEmptyState

Pre-configured for search scenarios:

```dart
class AppSearchEmptyState extends StatelessWidget {
  const AppSearchEmptyState({
    required this.query,
    this.onClear,
    this.suggestions,
  });

  final String query;
  final VoidCallback? onClear;
  final List<String>? suggestions;
}
```

### AppErrorState

Pre-configured for error scenarios with error-colored icon:

```dart
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    this.title = 'Something went wrong',
    this.description,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon = Icons.error_outline_rounded,
    this.size = AppEmptyStateSize.md,
  });
}
```

### AppOfflineState

Pre-configured for connectivity issues:

```dart
class AppOfflineState extends StatelessWidget {
  const AppOfflineState({
    this.onRetry,
    this.size = AppEmptyStateSize.md,
  });
}
```

---

## Accessibility

- Icon has no semantic meaning (decorative) — title provides context
- Title and description are announced by screen readers
- Action buttons have clear, descriptive labels
- Sufficient color contrast for text
- Touch targets meet minimum 44x44px requirement

---

## Best Practices

1. **Always provide a title** — Never show just an icon
2. **Keep descriptions concise** — 1-2 sentences maximum
3. **Offer clear actions** — Help users know what to do next
4. **Use appropriate size** — `sm` for cards, `md` for sections, `lg` for pages
5. **Choose meaningful icons** — Icons should relate to the missing content
6. **Consider the context** — Use specialized variants for search/error/offline

---

## Related Components

- [AppButton](./BUTTON.md) — Used for action buttons
- [AppCard](./CARD.md) — Often contains empty states
- [AppProgress](./PROGRESS.md) — Loading state before empty state
