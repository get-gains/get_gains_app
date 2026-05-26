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
import '../../../gains_coins/presentation/widgets/coin_balance_widget.dart';
import '../../../guidance/guidance.dart';
import '../../../home/presentation/screens/home_screen.dart'
    show isCoachProvider;
import '../../data/models/user_profile_model.dart';
import '../../data/models/profile_stats_model.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_stats_provider.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/share_template_picker.dart';

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
            ref.invalidate(profileProvider);
            ref.invalidate(userProfileProvider);
            ref.invalidate(profileStatsProvider);
            await ref.read(profileProvider.future);
            await ref.read(userProfileProvider.future);
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

class _ProfileContent extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Profile',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
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
              _ProfileHeader(user: user, fitnessProfile: fitnessProfile, isDark: isDark),
              const SizedBox(height: 24),

              _StatsGrid(
                statsAsync: statsAsync,
                isDark: isDark,
                user: user,
                fitnessProfile: fitnessProfile,
              ),
              const SizedBox(height: 24),

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
                      onTap: () => context.push(AppRoutes.workoutHistory),
                    ),
                    _divider(isDark),
                    _NavLinkTile(
                      icon: Icons.bar_chart,
                      title: 'Progress & Stats',
                      isDark: isDark,
                      onTap: () => context.push(AppRoutes.progress),
                    ),
                    if (!isCoach) ...[
                      _divider(isDark),
                      _NavLinkTile(
                        icon: Icons.person_search,
                        title: 'Find Coaches',
                        isDark: isDark,
                        onTap: () => context.push(AppRoutes.discoverCoaches),
                      ),
                      _divider(isDark),
                      _NavLinkTile(
                        icon: Icons.people,
                        title: 'My Coaches',
                        isDark: isDark,
                        onTap: () => context.push(AppRoutes.subscribedCoaches),
                      ),
                    ],
                    if (isCoach) ...[
                      _divider(isDark),
                      _NavLinkTile(
                        icon: Icons.sports,
                        title: 'Coach Tools',
                        isDark: isDark,
                        onTap: () => context.push(AppRoutes.coachHub),
                      ),
                      _divider(isDark),
                      _NavLinkTile(
                        icon: Icons.group,
                        title: 'Client Roster',
                        isDark: isDark,
                        onTap: () => context.push(AppRoutes.coachRoster),
                      ),
                    ],
                    _divider(isDark),
                    _NavLinkTile(
                      icon: Icons.help_outline,
                      title: 'Help & Tours',
                      isDark: isDark,
                      onTap: () {
                        final container = ProviderScope.containerOf(context);
                        container
                            .read(guidanceRepositoryProvider)
                            .resetAllTours();
                        AppToast.success(
                          context,
                          'All tours reset. They will replay on each screen.',
                        );
                        context.go(AppRoutes.home);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (fitnessProfile != null) ...[
                _SectionHeader(title: 'Fitness Profile', isDark: isDark),
                const SizedBox(height: 12),
                _FitnessProfileCard(profile: fitnessProfile!, isDark: isDark),
                const SizedBox(height: 24),

                if (fitnessProfile!.equipment.isNotEmpty) ...[
                  _SectionHeader(title: 'Equipment', isDark: isDark),
                  const SizedBox(height: 12),
                  _EquipmentCard(
                    equipment: fitnessProfile!.equipment,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                ],

                if (fitnessProfile!.injuryHistory != null &&
                    fitnessProfile!.injuryHistory!.isNotEmpty) ...[
                  _SectionHeader(title: 'Injury History', isDark: isDark),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.healing_outlined, size: 22, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            fitnessProfile!.injuryHistory!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: AppTextStyles.fontFamilySans),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],

              _SectionHeader(title: 'Gains Coins', isDark: isDark),
              const SizedBox(height: 12),
              CoinBalanceWidget(
                onTap: () => context.push(AppRoutes.coinHistory),
              ),
              const SizedBox(height: 24),

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
                    .map((a) => _AchievementTile(achievement: a, isDark: isDark))
                    .toList(),
              ),
              const SizedBox(height: 24),

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
                      foregroundColor: isDark ? AppColors.error : AppColors.destructiveLight,
                      side: BorderSide(color: isDark ? AppColors.error : AppColors.destructiveLight),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.fitnessProfile,
    required this.isDark,
  });

  final UserModel user;
  final UserProfileModel? fitnessProfile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTextStyles.fontFamilySans,
                ),
            textAlign: TextAlign.center,
          ),
          if (user.nickname.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              user.nickname,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontFamily: AppTextStyles.fontFamilySans,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          if (fitnessProfile?.bio != null && fitnessProfile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              fitnessProfile!.bio!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontFamily: AppTextStyles.fontFamilySans,
                  ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, size: 16, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              const SizedBox(width: 6),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontFamily: AppTextStyles.fontFamilySans,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends ConsumerWidget {
  const _StatsGrid({
    required this.statsAsync,
    required this.isDark,
    required this.user,
    required this.fitnessProfile,
  });

  final AsyncValue<ProfileStatsModel> statsAsync;
  final bool isDark;
  final UserModel user;
  final UserProfileModel? fitnessProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(title: 'Your Stats', isDark: isDark),
            _ShareButton(
              isDark: isDark,
              onTap: () {
                final stats = statsAsync.value;
                if (stats == null) return;
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ShareTemplatePicker(stats: stats, user: user, avatarUrl: fitnessProfile?.avatarUrl),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) => _buildStatsContent(context, stats, isDark),
          loading: () => const _StatsLoading(),
          error: (_, __) => _emptyStats(isDark),
        ),
      ],
    );
  }

  Widget _buildStatsContent(BuildContext context, ProfileStatsModel stats, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBlock(
                icon: Icons.fitness_center_outlined,
                label: 'Workouts\nthis week',
                value: '${stats.workoutsThisWeek}',
                isDark: isDark,
                accentColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBlock(
                icon: Icons.repeat,
                label: 'Sets\ntoday',
                value: '${stats.setsToday}',
                isDark: isDark,
                accentColor: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatBlock(
                icon: Icons.local_fire_department_outlined,
                label: 'Day\nstreak',
                value: '${stats.streakDays}',
                isDark: isDark,
                accentColor: const Color(0xFFFBBF24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatBlock(
                icon: Icons.timer_outlined,
                label: 'Minutes\nthis week',
                value: '${stats.totalMinutesWeek}',
                isDark: isDark,
                accentColor: const Color(0xFF60A5FA),
              ),
            ),
          ],
        ),
        if (stats.allTimeWorkouts > 0 || stats.allTimeSets > 0) ...[
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: _ProfileRow(
                    icon: Icons.emoji_events_outlined,
                    label: 'All-time workouts',
                    value: '${stats.allTimeWorkouts}',
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _ProfileRow(
                      icon: Icons.fitness_center_outlined,
                      label: 'All-time sets',
                      value: '${stats.allTimeSets}',
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyStats(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          'Complete a workout to see your stats',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamilyMono,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: accentColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamilySans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.share, size: 16, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Text(
              'Share',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamilySans,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 12),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Loading stats...'),
          ],
        ),
      ),
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
        Icon(icon, size: 22, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight,
            fontFamily: AppTextStyles.fontFamilySans,
          ),
    );
  }
}

class _FitnessProfileCard extends StatelessWidget {
  const _FitnessProfileCard({required this.profile, required this.isDark});

  final UserProfileModel profile;
  final bool isDark;

  String _formatHeight(double cm) => '${cm.toStringAsFixed(1)} cm';
  String _formatWeight(double kg) => '${kg.toStringAsFixed(1)} kg';

  String _formatSex(Sex sex) {
    return switch (sex) { Sex.male => 'Male', Sex.female => 'Female' };
  }

  String _formatExperience(ExperienceLevel level) {
    return switch (level) {
      ExperienceLevel.beginner => 'Beginner',
      ExperienceLevel.intermediate => 'Intermediate',
      ExperienceLevel.advanced => 'Advanced',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.heightCm != null) ...[
            _ProfileRow(icon: Icons.straighten_outlined, label: 'Height', value: _formatHeight(profile.heightCm!), isDark: isDark),
            const SizedBox(height: 16),
          ],
          if (profile.weightKg != null) ...[
            _ProfileRow(icon: Icons.monitor_weight_outlined, label: 'Weight', value: _formatWeight(profile.weightKg!), isDark: isDark),
            const SizedBox(height: 16),
          ],
          if (profile.sex != null) ...[
            _ProfileRow(icon: Icons.person_outline, label: 'Sex', value: _formatSex(profile.sex!), isDark: isDark),
            const SizedBox(height: 16),
          ],
          if (profile.dateOfBirth != null) ...[
            _ProfileRow(icon: Icons.cake_outlined, label: 'Date of Birth', value: DateFormat.yMMMd().format(profile.dateOfBirth!), isDark: isDark),
            const SizedBox(height: 16),
          ],
          if (profile.experienceLevel != null)
            _ProfileRow(icon: Icons.trending_up_outlined, label: 'Experience', value: _formatExperience(profile.experienceLevel!), isDark: isDark),
          if (profile.heightCm == null && profile.weightKg == null && profile.sex == null && profile.dateOfBirth == null && profile.experienceLevel == null)
            _ProfileRow(icon: Icons.info_outline, label: 'Tip', value: 'Tap the edit button to complete your fitness profile', isDark: isDark),
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
          final label = item.isNotEmpty ? '${item[0].toUpperCase()}${item.substring(1)}' : item;
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
    final iconColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: iconColor, fontFamily: AppTextStyles.fontFamilySans),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (isLocked)
              Positioned(top: 4, right: 4, child: Icon(Icons.lock_outline, size: 14, color: iconColor)),
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
      title: "Couldn't load profile",
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
            Icon(icon, size: 22, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}
