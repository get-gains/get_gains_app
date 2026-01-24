// lib/widgets/app_table.dart

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';

/// Sort direction for table columns
enum AppTableSortDirection { ascending, descending, none }

/// Table size variants
enum AppTableSize {
  /// Compact rows (40px)
  sm,

  /// Standard rows (52px)
  md,

  /// Comfortable rows (64px)
  lg,
}

/// Column definition for AppTable
class AppTableColumn<T> {
  const AppTableColumn({
    required this.id,
    required this.header,
    required this.cellBuilder,
    this.width,
    this.flex,
    this.sortable = false,
    this.sortValue,
    this.alignment = Alignment.centerLeft,
    this.headerAlignment,
  });

  /// Unique identifier for the column
  final String id;

  /// Header text or widget
  final Widget header;

  /// Builder for cell content
  final Widget Function(T item, int index) cellBuilder;

  /// Fixed width (mutually exclusive with flex)
  final double? width;

  /// Flex value for responsive width
  final int? flex;

  /// Whether column is sortable
  final bool sortable;

  /// Value extractor for sorting
  final Comparable Function(T item)? sortValue;

  /// Cell content alignment
  final Alignment alignment;

  /// Header alignment (defaults to cell alignment)
  final Alignment? headerAlignment;

  Alignment get effectiveHeaderAlignment => headerAlignment ?? alignment;
}

/// State for table sorting
class AppTableSortState {
  const AppTableSortState({
    this.columnId,
    this.direction = AppTableSortDirection.none,
  });

  final String? columnId;
  final AppTableSortDirection direction;

  AppTableSortState copyWith({
    String? columnId,
    AppTableSortDirection? direction,
  }) {
    return AppTableSortState(
      columnId: columnId ?? this.columnId,
      direction: direction ?? this.direction,
    );
  }
}

/// A data table component with sorting and filtering capabilities.
///
/// Features:
/// - Sortable columns
/// - Selectable rows
/// - Loading and empty states
/// - Responsive column widths
/// - Custom cell rendering
///
/// ## Usage
///
/// ```dart
/// AppTable<Workout>(
///   items: workouts,
///   columns: [
///     AppTableColumn(
///       id: 'name',
///       header: const Text('Name'),
///       cellBuilder: (workout, _) => Text(workout.name),
///       sortable: true,
///       sortValue: (workout) => workout.name,
///     ),
///     AppTableColumn(
///       id: 'date',
///       header: const Text('Date'),
///       cellBuilder: (workout, _) => Text(workout.date),
///       width: 120,
///     ),
///   ],
///   onRowTap: (workout) => navigateToDetail(workout),
/// )
/// ```
class AppTable<T> extends StatefulWidget {
  const AppTable({
    super.key,
    required this.items,
    required this.columns,
    this.size = AppTableSize.md,
    this.onRowTap,
    this.onRowLongPress,
    this.selectable = false,
    this.selectedItems = const {},
    this.onSelectionChanged,
    this.showHeader = true,
    this.showDividers = true,
    this.striped = false,
    this.sortState,
    this.onSortChanged,
    this.emptyBuilder,
    this.loadingBuilder,
    this.isLoading = false,
    this.headerDecoration,
    this.rowDecoration,
    this.selectedRowDecoration,
    this.hoverRowDecoration,
    this.borderRadius,
    this.border,
    this.elevation = 0,
  });

  /// Data items to display
  final List<T> items;

  /// Column definitions
  final List<AppTableColumn<T>> columns;

  /// Table size
  final AppTableSize size;

  /// Callback when row is tapped
  final void Function(T item)? onRowTap;

  /// Callback when row is long-pressed
  final void Function(T item)? onRowLongPress;

  /// Enable row selection
  final bool selectable;

  /// Currently selected items (for controlled selection)
  final Set<T> selectedItems;

  /// Callback when selection changes
  final void Function(Set<T> selectedItems)? onSelectionChanged;

  /// Show header row
  final bool showHeader;

  /// Show dividers between rows
  final bool showDividers;

  /// Alternate row background colors
  final bool striped;

  /// Current sort state
  final AppTableSortState? sortState;

  /// Callback when sort changes
  final void Function(AppTableSortState sortState)? onSortChanged;

  /// Builder for empty state
  final Widget Function()? emptyBuilder;

  /// Builder for loading state
  final Widget Function()? loadingBuilder;

  /// Show loading state
  final bool isLoading;

  /// Header row decoration
  final BoxDecoration? headerDecoration;

  /// Default row decoration
  final BoxDecoration? rowDecoration;

  /// Selected row decoration
  final BoxDecoration? selectedRowDecoration;

  /// Hovered row decoration
  final BoxDecoration? hoverRowDecoration;

  /// Border radius for the table
  final BorderRadius? borderRadius;

  /// Border for the table
  final BoxBorder? border;

  /// Table elevation
  final double elevation;

  @override
  State<AppTable<T>> createState() => _AppTableState<T>();
}

class _AppTableState<T> extends State<AppTable<T>> {
  int? _hoveredIndex;
  late AppTableSortState _sortState;

  @override
  void initState() {
    super.initState();
    _sortState = widget.sortState ?? const AppTableSortState();
  }

  @override
  void didUpdateWidget(AppTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sortState != null && widget.sortState != _sortState) {
      _sortState = widget.sortState!;
    }
  }

  double get _rowHeight {
    switch (widget.size) {
      case AppTableSize.sm:
        return 40;
      case AppTableSize.md:
        return 52;
      case AppTableSize.lg:
        return 64;
    }
  }

  double get _headerHeight {
    switch (widget.size) {
      case AppTableSize.sm:
        return 36;
      case AppTableSize.md:
        return 44;
      case AppTableSize.lg:
        return 52;
    }
  }

  List<T> get _sortedItems {
    if (_sortState.columnId == null ||
        _sortState.direction == AppTableSortDirection.none) {
      return widget.items;
    }

    final column = widget.columns.firstWhere(
      (c) => c.id == _sortState.columnId,
      orElse: () => widget.columns.first,
    );

    if (column.sortValue == null) return widget.items;

    final sorted = List<T>.from(widget.items)
      ..sort((a, b) {
        final aValue = column.sortValue!(a);
        final bValue = column.sortValue!(b);
        return aValue.compareTo(bValue);
      });

    if (_sortState.direction == AppTableSortDirection.descending) {
      return sorted.reversed.toList();
    }

    return sorted;
  }

  void _handleSort(AppTableColumn<T> column) {
    if (!column.sortable) return;

    AppTableSortDirection newDirection;
    String? newColumnId = column.id;

    if (_sortState.columnId == column.id) {
      // Cycle through: none -> ascending -> descending -> none
      switch (_sortState.direction) {
        case AppTableSortDirection.none:
          newDirection = AppTableSortDirection.ascending;
          break;
        case AppTableSortDirection.ascending:
          newDirection = AppTableSortDirection.descending;
          break;
        case AppTableSortDirection.descending:
          newDirection = AppTableSortDirection.none;
          newColumnId = null;
          break;
      }
    } else {
      newDirection = AppTableSortDirection.ascending;
    }

    final newState = AppTableSortState(
      columnId: newColumnId,
      direction: newDirection,
    );

    if (widget.onSortChanged != null) {
      widget.onSortChanged!(newState);
    } else {
      setState(() {
        _sortState = newState;
      });
    }
  }

  void _handleRowTap(T item) {
    if (widget.selectable && widget.onSelectionChanged != null) {
      final newSelection = Set<T>.from(widget.selectedItems);
      if (newSelection.contains(item)) {
        newSelection.remove(item);
      } else {
        newSelection.add(item);
      }
      widget.onSelectionChanged!(newSelection);
    }
    widget.onRowTap?.call(item);
  }

  void _handleSelectAll(bool? selected) {
    if (widget.onSelectionChanged == null) return;

    if (selected == true) {
      widget.onSelectionChanged!(Set<T>.from(widget.items));
    } else {
      widget.onSelectionChanged!({});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Material(
      color: bgColor,
      elevation: widget.elevation,
      borderRadius: widget.borderRadius ?? AppTheme.borderRadiusLg,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? AppTheme.borderRadiusLg,
          border: widget.border ?? Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showHeader) _buildHeader(context, isDark),
            Flexible(child: _buildBody(context, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final headerBg = isDark ? AppColors.surface2Dark : AppColors.gray50;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      height: _headerHeight,
      decoration:
          widget.headerDecoration ??
          BoxDecoration(
            color: headerBg,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
      child: Row(
        children: [
          if (widget.selectable) _buildSelectAllCheckbox(isDark),
          ...widget.columns.map((column) => _buildHeaderCell(column, isDark)),
        ],
      ),
    );
  }

  Widget _buildSelectAllCheckbox(bool isDark) {
    final allSelected =
        widget.items.isNotEmpty &&
        widget.selectedItems.length == widget.items.length;
    final someSelected = widget.selectedItems.isNotEmpty && !allSelected;

    return SizedBox(
      width: 56,
      child: Checkbox(
        value: allSelected,
        tristate: true,
        onChanged: _handleSelectAll,
        activeColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      ),
    );
  }

  Widget _buildHeaderCell(AppTableColumn<T> column, bool isDark) {
    final isSorted = _sortState.columnId == column.id;
    final textColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    Widget content = DefaultTextStyle(
      style: AppTextStyles.labelMedium.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      child: column.header,
    );

    if (column.sortable) {
      content = InkWell(
        onTap: () => _handleSort(column),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            const SizedBox(width: 4),
            _buildSortIcon(column, isSorted, isDark),
          ],
        ),
      );
    }

    return _buildCell(
      child: content,
      column: column,
      alignment: column.effectiveHeaderAlignment,
    );
  }

  Widget _buildSortIcon(AppTableColumn<T> column, bool isSorted, bool isDark) {
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final inactiveColor = isDark
        ? AppColors.mutedForegroundDark.withOpacity(0.5)
        : AppColors.mutedForegroundLight.withOpacity(0.5);

    if (!isSorted) {
      return Icon(Icons.unfold_more_rounded, size: 16, color: inactiveColor);
    }

    return Icon(
      _sortState.direction == AppTableSortDirection.ascending
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded,
      size: 16,
      color: activeColor,
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (widget.isLoading) {
      return widget.loadingBuilder?.call() ?? _buildDefaultLoading(isDark);
    }

    final sortedItems = _sortedItems;

    if (sortedItems.isEmpty) {
      return widget.emptyBuilder?.call() ?? _buildDefaultEmpty(isDark);
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        return _buildRow(context, sortedItems[index], index, isDark);
      },
    );
  }

  Widget _buildRow(BuildContext context, T item, int index, bool isDark) {
    final isSelected = widget.selectedItems.contains(item);
    final isHovered = _hoveredIndex == index;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    // Determine row background
    Color? bgColor;
    if (isSelected) {
      bgColor = isDark
          ? AppColors.primaryDark.withOpacity(0.15)
          : AppColors.primaryLight.withOpacity(0.1);
    } else if (isHovered) {
      bgColor = isDark ? AppColors.surface2Dark : AppColors.gray50;
    } else if (widget.striped && index.isOdd) {
      bgColor = isDark
          ? AppColors.surface1Dark.withOpacity(0.5)
          : AppColors.gray50.withOpacity(0.5);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: widget.onRowTap != null || widget.selectable
            ? () => _handleRowTap(item)
            : null,
        onLongPress: widget.onRowLongPress != null
            ? () => widget.onRowLongPress!(item)
            : null,
        child: Container(
          height: _rowHeight,
          decoration: BoxDecoration(
            color: bgColor,
            border: widget.showDividers && index < widget.items.length - 1
                ? Border(bottom: BorderSide(color: borderColor))
                : null,
          ),
          child: Row(
            children: [
              if (widget.selectable)
                _buildRowCheckbox(item, isSelected, isDark),
              ...widget.columns.map((column) {
                return _buildCell(
                  child: column.cellBuilder(item, index),
                  column: column,
                  alignment: column.alignment,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowCheckbox(T item, bool isSelected, bool isDark) {
    return SizedBox(
      width: 56,
      child: Checkbox(
        value: isSelected,
        onChanged: (selected) {
          if (widget.onSelectionChanged != null) {
            final newSelection = Set<T>.from(widget.selectedItems);
            if (selected == true) {
              newSelection.add(item);
            } else {
              newSelection.remove(item);
            }
            widget.onSelectionChanged!(newSelection);
          }
        },
        activeColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      ),
    );
  }

  Widget _buildCell({
    required Widget child,
    required AppTableColumn<T> column,
    required Alignment alignment,
  }) {
    Widget cellContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(alignment: alignment, child: child),
    );

    if (column.width != null) {
      return SizedBox(width: column.width, child: cellContent);
    }

    return Expanded(flex: column.flex ?? 1, child: cellContent);
  }

  Widget _buildDefaultLoading(bool isDark) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      ),
    );
  }

  Widget _buildDefaultEmpty(bool isDark) {
    final textColor = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: textColor),
          const SizedBox(height: 16),
          Text(
            'No data',
            style: AppTextStyles.bodyMedium.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}

/// A simple table row widget for use outside AppTable
class AppTableRow extends StatelessWidget {
  const AppTableRow({
    super.key,
    required this.cells,
    this.onTap,
    this.height = 52,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.showDivider = true,
  });

  final List<Widget> cells;
  final VoidCallback? onTap;
  final double height;
  final EdgeInsets padding;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding,
        decoration: showDivider
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              )
            : null,
        child: Row(
          children: cells.map((cell) {
            return Expanded(child: cell);
          }).toList(),
        ),
      ),
    );
  }
}
