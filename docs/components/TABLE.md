# AppTable

> **Reference**: [DESIGN_STYLE.md](../DESIGN_STYLE.md) · [COMPONENTS_INDEX.md](../COMPONENTS_INDEX.md)

## Purpose

Data table component for displaying structured data with sorting, filtering, and selection capabilities. Ideal for workout logs, exercise lists, and progress tracking.

---

## Variants

| Size | Row Height | Header Height | Usage |
|------|------------|---------------|-------|
| `sm` | 40px | 36px | Compact data lists |
| `md` | 52px | 44px | Default tables |
| `lg` | 64px | 52px | Tables with rich content |

---

## Features

| Feature | Description |
|---------|-------------|
| Sortable columns | Click headers to sort ascending/descending |
| Selectable rows | Checkbox selection with select-all |
| Striped rows | Alternating row backgrounds |
| Loading state | Built-in loading indicator |
| Empty state | Customizable empty content |
| Responsive columns | Fixed width or flex-based sizing |
| Custom cell rendering | Full control over cell content |

---

## Specifications

### Styling

| Property | Value | Token |
|----------|-------|-------|
| Border radius | 16px | `radiusLg` |
| Cell padding | 16px horizontal | `spacing4` |
| Border | 1px | `border` color |
| Header background | `surface2` / `gray50` | - |

### Typography

| Element | Style |
|---------|-------|
| Header text | `labelMedium`, muted, semi-bold |
| Cell text | `bodyMedium` |

### Colors (Dark Mode)

| State | Background |
|-------|------------|
| Default | `card` |
| Hovered | `surface2` |
| Selected | `primary` 15% opacity |
| Striped odd | `surface1` 50% opacity |

---

## Implementation

### Column Definition

```dart
class AppTableColumn<T> {
  const AppTableColumn({
    required this.id,          // Unique identifier
    required this.header,      // Header widget
    required this.cellBuilder, // Cell content builder
    this.width,               // Fixed width
    this.flex,                // Flex value
    this.sortable = false,    // Enable sorting
    this.sortValue,           // Sort value extractor
    this.alignment = Alignment.centerLeft,
  });
}
```

### Sort State

```dart
class AppTableSortState {
  const AppTableSortState({
    this.columnId,
    this.direction = AppTableSortDirection.none,
  });
}

enum AppTableSortDirection {
  ascending,
  descending,
  none,
}
```

---

## Usage Examples

### Basic Table

```dart
AppTable<Exercise>(
  items: exercises,
  columns: [
    AppTableColumn(
      id: 'name',
      header: const Text('Exercise'),
      cellBuilder: (exercise, _) => Text(exercise.name),
      flex: 2,
    ),
    AppTableColumn(
      id: 'sets',
      header: const Text('Sets'),
      cellBuilder: (exercise, _) => Text('${exercise.sets}'),
      width: 80,
      alignment: Alignment.center,
    ),
    AppTableColumn(
      id: 'reps',
      header: const Text('Reps'),
      cellBuilder: (exercise, _) => Text('${exercise.reps}'),
      width: 80,
      alignment: Alignment.center,
    ),
  ],
)
```

### Sortable Table

```dart
AppTable<Workout>(
  items: workouts,
  sortState: _sortState,
  onSortChanged: (state) => setState(() => _sortState = state),
  columns: [
    AppTableColumn(
      id: 'name',
      header: const Text('Name'),
      cellBuilder: (workout, _) => Text(workout.name),
      sortable: true,
      sortValue: (workout) => workout.name,
    ),
    AppTableColumn(
      id: 'date',
      header: const Text('Date'),
      cellBuilder: (workout, _) => Text(
        DateFormat.yMMMd().format(workout.date),
      ),
      sortable: true,
      sortValue: (workout) => workout.date,
      width: 120,
    ),
    AppTableColumn(
      id: 'duration',
      header: const Text('Duration'),
      cellBuilder: (workout, _) => Text('${workout.durationMinutes} min'),
      sortable: true,
      sortValue: (workout) => workout.durationMinutes,
      width: 100,
      alignment: Alignment.centerRight,
    ),
  ],
)
```

### Selectable Table

```dart
AppTable<Exercise>(
  items: exercises,
  selectable: true,
  selectedItems: _selectedExercises,
  onSelectionChanged: (selected) {
    setState(() => _selectedExercises = selected);
  },
  onRowTap: (exercise) {
    // Navigate to detail
    context.push('/exercise/${exercise.id}');
  },
  columns: [
    // ... columns
  ],
)

// Use selected items
ElevatedButton(
  onPressed: _selectedExercises.isEmpty
      ? null
      : () => deleteExercises(_selectedExercises),
  child: Text('Delete (${_selectedExercises.length})'),
)
```

### Custom Cell Content

```dart
AppTableColumn<Workout>(
  id: 'exercises',
  header: const Text('Exercises'),
  cellBuilder: (workout, _) => Wrap(
    spacing: 4,
    children: workout.exercises.take(3).map((e) {
      return AppChip(
        label: e.name,
        size: AppChipSize.sm,
      );
    }).toList(),
  ),
),

AppTableColumn<User>(
  id: 'avatar',
  header: const Text('User'),
  cellBuilder: (user, _) => Row(
    children: [
      AppAvatar(
        imageUrl: user.avatarUrl,
        initials: user.initials,
        size: AppAvatarSize.sm,
      ),
      const SizedBox(width: 12),
      Text(user.name),
    ],
  ),
),

AppTableColumn<Workout>(
  id: 'status',
  header: const Text('Status'),
  cellBuilder: (workout, _) => AppBadge(
    label: workout.isCompleted ? 'Done' : 'Pending',
    variant: workout.isCompleted
        ? AppBadgeVariant.success
        : AppBadgeVariant.warning,
  ),
  width: 100,
),
```

### Table with States

```dart
AppTable<Workout>(
  items: workouts,
  isLoading: isLoading,
  loadingBuilder: () => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading workouts...'),
      ],
    ),
  ),
  emptyBuilder: () => AppEmptyState(
    icon: Icons.fitness_center,
    title: 'No workouts yet',
    description: 'Start your fitness journey by creating your first workout.',
    action: AppButton(
      label: 'Create Workout',
      onPressed: () => showCreateWorkoutSheet(context),
    ),
  ),
  columns: [
    // ... columns
  ],
)
```

### Striped Table

```dart
AppTable<Exercise>(
  items: exercises,
  striped: true,
  showDividers: false,
  columns: [
    // ... columns
  ],
)
```

### Compact Table

```dart
AppTable<Set>(
  items: workoutSets,
  size: AppTableSize.sm,
  showHeader: false,
  columns: [
    AppTableColumn(
      id: 'set',
      header: const Text('Set'),
      cellBuilder: (set, index) => Text('${index + 1}'),
      width: 50,
    ),
    AppTableColumn(
      id: 'weight',
      header: const Text('Weight'),
      cellBuilder: (set, _) => Text('${set.weight} kg'),
    ),
    AppTableColumn(
      id: 'reps',
      header: const Text('Reps'),
      cellBuilder: (set, _) => Text('${set.reps}'),
    ),
  ],
)
```

---

## Accessibility

| Feature | Implementation |
|---------|----------------|
| Screen reader | Column headers and cell content are announced |
| Keyboard | Tab navigation through interactive elements |
| Selection | Checkbox announces selected state |
| Sort | Sort direction announced on header interaction |

### Accessibility Guidelines

```dart
// Add semantic labels for complex cells
AppTableColumn<Workout>(
  id: 'status',
  header: const Text('Status'),
  cellBuilder: (workout, _) => Semantics(
    label: workout.isCompleted
        ? 'Completed workout'
        : 'Incomplete workout',
    child: AppBadge(
      label: workout.isCompleted ? 'Done' : 'Pending',
      variant: workout.isCompleted
          ? AppBadgeVariant.success
          : AppBadgeVariant.warning,
    ),
  ),
),
```

---

## Do's and Don'ts

### ✅ Do

- Use sortable columns for data users need to compare
- Provide loading and empty states
- Use appropriate column widths for content
- Include actions for selected rows
- Use semantic cell content

### ❌ Don't

- Don't display too many columns (consider horizontal scroll)
- Don't use tables for simple lists (use AppListTile)
- Don't forget mobile responsiveness
- Don't disable all row interactions

---

## Related Components

- [AppListTile](./LIST_TILE.md) - Simple list items
- [AppCard](./CARD.md) - Card-based layouts
- [AppProgress](./PROGRESS.md) - Loading states
- [AppEmptyState](./EMPTY_STATE.md) - Empty states
