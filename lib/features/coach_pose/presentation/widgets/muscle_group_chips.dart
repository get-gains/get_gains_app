import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../workout/data/models/exercise_model.dart';

/// Horizontal scrollable chip selector for muscle group filtering.
class MuscleGroupChips extends StatelessWidget {
  const MuscleGroupChips({
    super.key,
    required this.selectedMuscleGroup,
    required this.onSelected,
  });

  final MuscleGroup? selectedMuscleGroup;
  final ValueChanged<MuscleGroup?> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedMuscleGroup == null,
              onSelected: (_) => onSelected(null),
              backgroundColor: isDark
                  ? AppColors.surface2Dark
                  : AppColors.secondaryLight,
              selectedColor: isDark
                  ? AppColors.primaryDark
                  : AppColors.primaryLight,
              labelStyle: TextStyle(
                color: selectedMuscleGroup == null
                    ? Colors.white
                    : (isDark
                          ? AppColors.foregroundDark
                          : AppColors.foregroundLight),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          // Muscle group chips
          ...MuscleGroup.values.map((group) {
            final isSelected = selectedMuscleGroup == group;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(group.displayName),
                selected: isSelected,
                onSelected: (_) => onSelected(isSelected ? null : group),
                backgroundColor: isDark
                    ? AppColors.surface2Dark
                    : AppColors.secondaryLight,
                selectedColor: isDark
                    ? AppColors.primaryDark
                    : AppColors.primaryLight,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? AppColors.foregroundDark
                            : AppColors.foregroundLight),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        ],
      ),
    );
  }
}
