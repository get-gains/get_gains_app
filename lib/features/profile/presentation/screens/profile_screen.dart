// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../providers/auth_state_provider.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../home/presentation/screens/home_screen.dart'
    show isCoachProvider;
import '../../data/models/user_profile_model.dart';
import '../providers/profile_provider.dart';
import '../providers/user_profile_provider.dart';

/// Placeholder achievement entry for the profile achievements grid.
/// Replace with API-backed model when backend is ready.
class _PlaceholderAchievement {
  const _PlaceholderAchievement({
    required this.id,
    required this.icon,
    required this.title,
    required this.unlocked,
  });

  final String id;
  final IconData icon;
  final String title;
  final bool unlocked;
}

const List<_PlaceholderAchievement> _placeholderAchievements = [
  _PlaceholderAchievement(
    id: '1',
    icon: Icons.fitness_center,
    title: 'First rep',
    unlocked: false,
  ),
  _PlaceholderAchievement(
    id: '2',
    icon: Icons.repeat,
    title: '10 workouts',
    unlocked: false,
  ),
  _PlaceholderAchievement(
    id: '3',
    icon: Icons.calendar_today,
    title: 'Week warrior',
    unlocked: false,
  ),
  _PlaceholderAchievement(
    id: '4',
    icon: Icons.wb_sunny_outlined,
    title: 'Early bird',
    unlocked: false,
  ),
  _PlaceholderAchievement(
    id: '5',
    icon: Icons.trending_up,
    title: 'Strong start',
    unlocked: false,
  ),
  _PlaceholderAchievement(
    id: '6',
    icon: Icons.local_fire_department_outlined,
    title: 'Consistency',
    unlocked: false,
  ),
];

/// User profile screen.
///
/// Displays the current user's profile (avatar, name, nickname, email,
/// member since) with pull-to-refresh and error/retry.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final fitnessProfileAsync = ref.watch(userProfileProvider);
    final canEdit = ref.watch(canEditProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCoachAsync = ref.watch(isCoachProvider);
    final isCoach = isCoachAsync.asData?.value ?? false;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.refresh(profileProvider.future);
            ref.read(userProfileProvider.notifier).refresh();
          },
          child: profileAsync.when(
            data: (user) => _ProfileContent(
              user: user,
              fitnessProfile: fitnessProfileAsync.value,
              canEdit: canEdit,
              isDark: isDark,
              isCoach: isCoach,
            ),
            loading: () => const _ProfileLoading(),
            error: (error, _) => _ProfileError(
              message: error is Exception ? error.toString() : '$error',
              onRetry: () => ref.invalidate(profileProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.user,
    required this.fitnessProfile,
    required this.canEdit,
    required this.isDark,
    this.isCoach = false,
  });

  final UserModel user;
  final UserProfileModel? fitnessProfile;
  final bool canEdit;
  final bool isDark;
  final bool isCoach;

  @override
  Widget build(BuildContext context) {
    final memberSince = user.createdAt != null
        ? DateFormat.yMMM().format(user.createdAt!)
        : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Profile',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: canEdit ? 'Edit profile' : 'Editing requires internet',
                onPressed: canEdit
                    ? () => context.push(AppRoutes.editProfile)
                    : () => AppToast.warning(
                        context,
                        'Editing requires an internet connection',
                      ),
              ),
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              // ── Avatar and name block ─────────────────────────────
              Center(
                child: Column(
                  children: [
                    AppAvatar(
                      name: user.name,
                      imageUrl: fitnessProfile?.avatarUrl,
                      size: AppAvatarSize.xxl,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTextStyles.fontFamilySans,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (user.nickname.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.nickname,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontFamily: AppTextStyles.fontFamilySans,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (fitnessProfile?.bio != null &&
                        fitnessProfile!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        fitnessProfile!.bio!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontFamily: AppTextStyles.fontFamilySans,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Account info card ─────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                      isDark: isDark,
                    ),
                    if (memberSince != null) ...[
                      const SizedBox(height: 16),
                      _ProfileRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member since',
                        value: memberSince,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Quick Navigation Links (M-CF1-5) ──────────────
              _SectionHeader(title: 'Quick Links', isDark: isDark),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    _NavLinkTile(
                      icon: Icons.history,
                      title: 'Workout History',
                      isDark: isDark,
                      onTap: () =>
                          context.push(AppRoutes.workoutHistory),
                    ),
                    _divider(isDark),
                    _NavLinkTile(
                      icon: Icons.bar_chart,
                      title: 'Progress & Stats',
                      isDark: isDark,
                      onTap: () => context.push(AppRoutes.progress),
                    ),
                    _divider(isDark),
                    _NavLinkTile(
                      icon: Icons.person_search,
                      title: 'Find Coaches',
                      isDark: isDark,
                      onTap: () =>
                          context.push(AppRoutes.discoverCoaches),
                    ),
                    _divider(isDark),
                    _NavLinkTile(
                      icon: Icons.people,
                      title: 'My Coaches',
                      isDark: isDark,
                      onTap: () =>
                          context.push(AppRoutes.subscribedCoaches),
                    ),
                    if (isCoach) ...[
                      _divider(isDark),
                      _NavLinkTile(
                        icon: Icons.sports,
                        title: 'Coach Tools',
                        isDark: isDark,
                        onTap: () =>
                            context.push(AppRoutes.coachHub),
                      ),
                      _divider(isDark),
                      _NavLinkTile(
                        icon: Icons.group,
                        title: 'Client Roster',
                        isDark: isDark,
                        onTap: () =>
                            context.push(AppRoutes.coachRoster),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Fitness profile card ──────────────────────────────
              if (fitnessProfile != null) ...[
                _SectionHeader(title: 'Fitness Profile', isDark: isDark),
                const SizedBox(height: 12),
                _FitnessProfileCard(profile: fitnessProfile!, isDark: isDark),
                const SizedBox(height: 24),

                // ── Training preferences card ─────────────────────
                _SectionHeader(title: 'Training Preferences', isDark: isDark),
                const SizedBox(height: 12),
                _TrainingPreferencesCard(
                  profile: fitnessProfile!,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // ── Equipment card ────────────────────────────────
                if (fitnessProfile!.equipment.isNotEmpty) ...[
                  _SectionHeader(title: 'Equipment', isDark: isDark),
                  const SizedBox(height: 12),
                  _EquipmentCard(
                    equipment: fitnessProfile!.equipment,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Injury history ────────────────────────────────
                if (fitnessProfile!.injuryHistory != null &&
                    fitnessProfile!.injuryHistory!.isNotEmpty) ...[
                  _SectionHeader(title: 'Injury History', isDark: isDark),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.healing_outlined,
                          size: 22,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            fitnessProfile!.injuryHistory!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontFamily: AppTextStyles.fontFamilySans,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],

              // ── Stats placeholder section ─────────────────────────
              _SectionHeader(title: 'Stats', isDark: isDark),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileRow(
                      icon: Icons.fitness_center_outlined,
                      label: 'Workouts this week',
                      value: '—',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _ProfileRow(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Current streak',
                      value: '—',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Achievements section
              _SectionHeader(title: 'Achievements', isDark: isDark),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: _placeholderAchievements
                    .map(
                      (a) => _AchievementTile(achievement: a, isDark: isDark),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              // Logout
              Consumer(
                builder: (context, ref, _) {
                  return OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.error
                          : AppColors.destructiveLight,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.error
                            : AppColors.destructiveLight,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 22,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontFamily: AppTextStyles.fontFamilySans,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFamily: AppTextStyles.fontFamilySans,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark
                ? AppColors.foregroundDark
                : AppColors.foregroundLight,
            fontFamily: AppTextStyles.fontFamilySans,
          ),
        ),
      ],
    );
  }
}

// ─── Fitness profile display cards ──────────────────────────────────────

class _FitnessProfileCard extends StatelessWidget {
  const _FitnessProfileCard({required this.profile, required this.isDark});

  final UserProfileModel profile;
  final bool isDark;

  String _formatHeight(double cm) {
    return '${cm.toStringAsFixed(1)} cm';
  }

  String _formatWeight(double kg) {
    return '${kg.toStringAsFixed(1)} kg';
  }

  String _formatSex(Sex sex) {
    return switch (sex) {
      Sex.male => 'Male',
      Sex.female => 'Female',
    };
  }

  String _formatExperience(ExperienceLevel level) {
    return switch (level) {
      ExperienceLevel.beginner => 'Beginner',
      ExperienceLevel.intermediate => 'Intermediate',
      ExperienceLevel.advanced => 'Advanced',
    };
  }

  String _formatDateOfBirth(DateTime dob) {
    final age = DateTime.now().difference(dob).inDays ~/ 365;
    return '${DateFormat.yMMMd().format(dob)} ($age yrs)';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.heightCm != null) ...[
            _ProfileRow(
              icon: Icons.straighten_outlined,
              label: 'Height',
              value: _formatHeight(profile.heightCm!),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ],
          if (profile.weightKg != null) ...[
            _ProfileRow(
              icon: Icons.monitor_weight_outlined,
              label: 'Weight',
              value: _formatWeight(profile.weightKg!),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ],
          if (profile.sex != null) ...[
            _ProfileRow(
              icon: Icons.person_outline,
              label: 'Sex',
              value: _formatSex(profile.sex!),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ],
          if (profile.dateOfBirth != null) ...[
            _ProfileRow(
              icon: Icons.cake_outlined,
              label: 'Date of Birth',
              value: _formatDateOfBirth(profile.dateOfBirth!),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ],
          if (profile.experienceLevel != null)
            _ProfileRow(
              icon: Icons.trending_up_outlined,
              label: 'Experience',
              value: _formatExperience(profile.experienceLevel!),
              isDark: isDark,
            ),
          // If no fields are populated, show a hint
          if (profile.heightCm == null &&
              profile.weightKg == null &&
              profile.sex == null &&
              profile.dateOfBirth == null &&
              profile.experienceLevel == null)
            _ProfileRow(
              icon: Icons.info_outline,
              label: 'Tip',
              value: 'Tap the edit button to complete your fitness profile',
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

class _TrainingPreferencesCard extends StatelessWidget {
  const _TrainingPreferencesCard({required this.profile, required this.isDark});

  final UserProfileModel profile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileRow(
            icon: Icons.calendar_view_week_outlined,
            label: 'Days per week',
            value: '${profile.daysAvailable}',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _ProfileRow(
            icon: Icons.timer_outlined,
            label: 'Session duration',
            value: '${profile.sessionDurationMinutes} min',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.equipment, required this.isDark});

  final List<String> equipment;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: equipment.map((item) {
          // Capitalise first letter for display
          final label = item.isNotEmpty
              ? '${item[0].toUpperCase()}${item.substring(1)}'
              : item;
          return AppBadge(label: label, variant: AppBadgeVariant.secondary);
        }).toList(),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.isDark});

  final _PlaceholderAchievement achievement;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isLocked = !achievement.unlocked;
    final iconColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(achievement.icon, size: 36, color: iconColor),
                const SizedBox(height: 8),
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: iconColor,
                    fontFamily: AppTextStyles.fontFamilySans,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (isLocked)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.lock_outline, size: 14, color: iconColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading profile...'),
          ],
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState.fullPage(
      icon: Icons.person_off_outlined,
      title: 'Couldn’t load profile',
      description: message,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}
Widget _divider(bool isDark) {
  return Divider(
    height: 1,
    thickness: 0.5,
    indent: 56,
    color: isDark ? AppColors.borderDark : AppColors.borderLight,
  );
}

class _NavLinkTile extends StatelessWidget {
  const _NavLinkTile({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}