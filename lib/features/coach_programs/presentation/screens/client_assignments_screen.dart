import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/widgets.dart';
import '../../../profile/data/models/user_profile_model.dart';
import '../../data/models/program_model.dart';
import '../providers/client_profile_provider.dart';
import '../providers/coach_assignment_provider.dart';
import 'assign_program_sheet.dart';

/// Client Assignments Screen
///
/// Displays all program assignments for a specific client.
/// Allows assigning new programs, deactivating, and deleting assignments.
class ClientAssignmentsScreen extends ConsumerStatefulWidget {
  const ClientAssignmentsScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  final String userId;
  final String? userName;

  @override
  ConsumerState<ClientAssignmentsScreen> createState() =>
      _ClientAssignmentsScreenState();
}

class _ClientAssignmentsScreenState
    extends ConsumerState<ClientAssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(clientAssignmentsProvider(widget.userId).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientAssignmentsProvider(widget.userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userName != null
              ? '${widget.userName}\'s Programs'
              : 'Client Programs',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(state, isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignSheet(),
        backgroundColor: isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Assign Program'),
      ),
    );
  }

  Widget _buildBody(ClientAssignmentsState state, bool isDark) {
    final content = switch (state) {
      ClientAssignmentsInitial() || ClientAssignmentsLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      ClientAssignmentsError(:final error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: isDark ? AppColors.error : AppColors.errorLight,
            ),
            const SizedBox(height: 12),
            Text(error.message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(
              label: 'Retry',
              onPressed: () => ref
                  .read(clientAssignmentsProvider(widget.userId).notifier)
                  .load(),
            ),
          ],
        ),
      ),
      ClientAssignmentsLoaded(:final assignments) =>
        assignments.isEmpty ? _buildEmpty() : _buildList(assignments, isDark),
    };

    return Column(
      children: [
        _ClientAvailabilityBar(userId: widget.userId),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildEmpty() {
    return AppEmptyState(
      icon: Icons.assignment_outlined,
      title: 'No Programs Assigned',
      description: 'Assign a program to this client to get them started.',
      actionLabel: 'Assign Program',
      onAction: () => _showAssignSheet(),
    );
  }

  Widget _buildList(List<AssignedProgramModel> assignments, bool isDark) {
    // Sort: active first, then by start date descending
    final sorted = [...assignments]
      ..sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        return b.startDate.compareTo(a.startDate);
      });

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(clientAssignmentsProvider(widget.userId).notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final assignment = sorted[index];
          return _AssignmentCard(
            assignment: assignment,
            isDark: isDark,
            onDelete: () => _confirmDelete(assignment),
          );
        },
      ),
    );
  }

  Future<void> _showAssignSheet() async {
    final result = await showAssignProgramSheet(
      context: context,
      userId: widget.userId,
      userName: widget.userName,
    );
    if (result == true && mounted) {
      ref.read(clientAssignmentsProvider(widget.userId).notifier).load();
    }
  }

  Future<void> _confirmDelete(AssignedProgramModel assignment) async {
    final programName = assignment.program?.name ?? 'this program';
    final confirmed = await showAppConfirmSheet(
      context: context,
      title: 'Remove Assignment',
      message: 'Remove "$programName" assignment from this client?',
      confirmLabel: 'Remove',
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(clientAssignmentsProvider(widget.userId).notifier)
          .deleteAssignment(assignment.id);
      if (mounted) {
        if (success) {
          AppToast.success(context, 'Assignment removed');
        } else {
          AppToast.error(context, 'Failed to remove assignment');
        }
      }
    }
  }
}

// ──────────────────────────────────────────────────────────
// Assignment Card
// ──────────────────────────────────────────────────────────

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.isDark,
    required this.onDelete,
  });

  final AssignedProgramModel assignment;
  final bool isDark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final programName = assignment.program?.name ?? 'Unknown Program';

    return AppCard.elevated(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  programName,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppBadge(
                label: assignment.isActive ? 'Active' : 'Inactive',
                variant: assignment.isActive
                    ? AppBadgeVariant.success
                    : AppBadgeVariant.secondary,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dates
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: isDark
                    ? AppColors.mutedForegroundDark
                    : AppColors.mutedForegroundLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Start: ${_formatDate(assignment.startDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
              if (assignment.endDate != null) ...[
                const SizedBox(width: 12),
                Text(
                  'End: ${_formatDate(assignment.endDate!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ],
            ],
          ),

          if (assignment.notes != null && assignment.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notes,
                  size: 14,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    assignment.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          if (assignment.program?.routineCount != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 14,
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
                const SizedBox(width: 4),
                Text(
                  '${assignment.program!.routineCount} routines',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: isDark ? AppColors.error : AppColors.errorLight,
              tooltip: 'Remove assignment',
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ──────────────────────────────────────────────────────────
// Client Availability Bar
// ──────────────────────────────────────────────────────────

/// Compact bar showing the client's active weekdays.
///
/// Fetches the client profile via [clientProfileNotifierProvider] and
/// displays day chips so the coach knows the client's availability.
class _ClientAvailabilityBar extends ConsumerWidget {
  const _ClientAvailabilityBar({required this.userId});

  final String userId;

  static const _dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _dayValues = DayOfWeek.values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(clientProfileProvider(userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        final activeDays = profile.activeWeekdays;
        if (activeDays.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Days',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.foregroundDark
                      : AppColors.foregroundLight,
                  fontFamily: AppTextStyles.fontFamilySans,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_dayValues.length, (i) {
                  final isActive = activeDays.contains(_dayValues[i]);
                  return _DayChip(
                    label: _dayLabels[i],
                    isActive: isActive,
                    isDark: isDark,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Divider(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.isActive,
    required this.isDark,
  });

  final String label;
  final bool isActive;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 32,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryDark
            : (isDark ? AppColors.surface2Dark : AppColors.surface2Light),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive
              ? Colors.white
              : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
          fontFamily: AppTextStyles.fontFamilySans,
        ),
      ),
    );
  }
}
