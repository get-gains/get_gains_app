import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/errors/api_error_codes.dart';
import '../../../../core/errors/error_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_error.dart';
import '../../../../widgets/widgets.dart';
import '../../../../core/access/access_guard.dart';
import '../../../../core/access/access_guard_provider.dart';
import '../../../subscription/subscription.dart';
import '../../data/models/coach_model.dart';
import '../providers/coach_profile_provider.dart';
import '../providers/subscribed_coaches_provider.dart';

/// Coach Profile Screen (ML-1)
///
/// Displays a single coach's full public profile using the
/// `GET /user/coaches/:coachId` endpoint. Shows extended fields
/// like socialLinks not available in the discovery list.
///
/// Users can subscribe/unsubscribe from this screen. Server
/// enforces ML-2 (subscription guard) and ML-5 (capacity guard).
class CoachProfileScreen extends ConsumerStatefulWidget {
  const CoachProfileScreen({super.key, required this.coachId});

  final String coachId;

  @override
  ConsumerState<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends ConsumerState<CoachProfileScreen> {
  bool _isSubscribing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(coachProfileProvider(widget.coachId).notifier).load();
      // Load subscribed coaches if not already loaded so isSubscribedToCoach
      // returns the correct value on first render (fixes double-tap subscribe bug).
      if (ref.read(subscribedCoachesProvider) is SubscribedCoachesInitial) {
        ref.read(subscribedCoachesProvider.notifier).loadCoaches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachProfileProvider(widget.coachId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(state),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(state, isDark),
    );
  }

  Widget _buildTitle(CoachProfileState state) {
    if (state is CoachProfileLoaded) {
      return Text(state.coach.name);
    }
    return const Text('Coach Profile');
  }

  Widget _buildBody(CoachProfileState state, bool isDark) {
    return switch (state) {
      CoachProfileInitial() ||
      CoachProfileLoading() => const Center(child: CircularProgressIndicator()),
      CoachProfileError(:final error) => _buildError(error, isDark),
      CoachProfileLoaded(:final coach) => _buildProfile(coach, isDark),
    };
  }

  Widget _buildError(AppError error, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? AppColors.error : AppColors.errorLight,
          ),
          const SizedBox(height: 12),
          Text(
            errorMessageFor(error),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Retry',
            onPressed: () =>
                ref.read(coachProfileProvider(widget.coachId).notifier).load(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(CoachDetailModel coach, bool isDark) {
    final theme = Theme.of(context);
    final isSubscribed = ref.watch(isSubscribedToCoachProvider(widget.coachId));

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(coachProfileProvider(widget.coachId).notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Header ────────────────────────────────────
          Center(
            child: Column(
              children: [
                AppAvatar(
                  imageUrl: coach.avatarUrl,
                  name: coach.name,
                  size: AppAvatarSize.xxl,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        coach.name,
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (coach.isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified,
                        size: 22,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  coach.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.mutedForegroundDark
                        : AppColors.mutedForegroundLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Subscribe / Unsubscribe Button ─────────────
          _isSubscribing
              ? const Center(child: CircularProgressIndicator())
              : AppButton(
                  label: isSubscribed ? 'Unsubscribe' : 'Subscribe',
                  variant: isSubscribed
                      ? AppButtonVariant.outline
                      : AppButtonVariant.primary,
                  icon: isSubscribed
                      ? Icons.person_remove_outlined
                      : Icons.person_add_outlined,
                  isFullWidth: true,
                  onPressed: () => _handleSubscription(isSubscribed),
                ),
          const SizedBox(height: 24),

          // ── Bio ───────────────────────────────────────
          if (coach.bio != null && coach.bio!.isNotEmpty) ...[
            _SectionHeader(title: 'About', isDark: isDark),
            const SizedBox(height: 8),
            Text(coach.bio!, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
          ],

          // ── Stats Row ────────────────────────────────
          Row(
            children: [
              Expanded(
                child: AppStatsCard(
                  label: 'Experience',
                  value: '${coach.yearsExperience}y',
                  icon: Icons.workspace_premium_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppStatsCard(
                  label: 'Certifications',
                  value: '${coach.certifications.length}',
                  icon: Icons.school_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Specialties ──────────────────────────────
          if (coach.specialties.isNotEmpty) ...[
            _SectionHeader(title: 'Specialties', isDark: isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: coach.specialties
                  .map(
                    (s) => AppBadge(label: s, variant: AppBadgeVariant.primary),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // ── Certifications ───────────────────────────
          if (coach.certifications.isNotEmpty) ...[
            _SectionHeader(title: 'Certifications', isDark: isDark),
            const SizedBox(height: 8),
            ...coach.certifications.map(
              (cert) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(cert, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Awards ───────────────────────────────────
          if (coach.awards.isNotEmpty) ...[
            _SectionHeader(title: 'Awards', isDark: isDark),
            const SizedBox(height: 8),
            ...coach.awards.map(
              (award) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(award, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Social Links ─────────────────────────────
          if (coach.socialLinks.isNotEmpty) ...[
            _SectionHeader(title: 'Social', isDark: isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: coach.socialLinks.map((link) {
                return ActionChip(
                  avatar: Icon(
                    _getSocialIcon(link),
                    size: 16,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                  label: Text(
                    _getSocialLabel(link),
                    style: theme.textTheme.labelMedium,
                  ),
                  onPressed: () => _launchUrl(link),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // ── Member Since ─────────────────────────────
          if (coach.createdAt != null)
            Center(
              child: Text(
                'Member since ${_formatDate(coach.createdAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.mutedForegroundDark
                      : AppColors.mutedForegroundLight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────────────────

  Future<void> _handleSubscription(bool isCurrentlySubscribed) async {
    setState(() => _isSubscribing = true);

    try {
      if (isCurrentlySubscribed) {
        // Unsubscribe
        final confirmed = await showAppConfirmSheet(
          context: context,
          title: 'Unsubscribe',
          message:
              'Are you sure you want to unsubscribe from this coach? '
              'You will lose access to their programs.',
          confirmLabel: 'Unsubscribe',
          isDestructive: true,
          icon: Icons.person_remove_outlined,
        );
        if (confirmed != true || !mounted) return;

        final (:success, :error) = await ref
            .read(subscribedCoachesProvider.notifier)
            .unsubscribeFromCoach(widget.coachId);
        if (mounted) {
          if (success) {
            AppToast.success(context, 'Unsubscribed from coach');
          } else if (error != null) {
            _showSubscriptionError(error);
          }
        }
      } else {
        // Proactive subscription check — show upgrade prompt instead of
        // relying on server 403 with a vague error toast (US2 / T026).
        final guard = ref.read(accessGuardProvider);
        final decision = await guard.evaluateAsync(
          const AccessRequirement(requireTier: SubscriptionTier.premium),
        );
        if (decision is! AccessGranted) {
          if (mounted) {
            showUpgradeSheet(
              context: context,
              feature: SubscriptionFeature.coachAccess,
            );
          }
          return;
        }

        // Subscribe — server still enforces ML-2 + ML-5 as fallback
        final (:success, :error) = await ref
            .read(subscribedCoachesProvider.notifier)
            .subscribeToCoach(widget.coachId);
        if (mounted) {
          if (success) {
            AppToast.success(context, 'Subscribed to coach!');
          } else if (error != null) {
            _showSubscriptionError(error);
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  /// Shows a code-aware error toast for subscribe/unsubscribe failures.
  void _showSubscriptionError(AppError error) {
    switch (error.code) {
      // Already subscribed — stale UI. Refresh so button flips to "Unsubscribe".
      case ApiErrorCode.userCoachAlreadySubscribed:
        AppToast.info(context, errorMessageFor(error));
        ref.read(subscribedCoachesProvider.notifier).loadCoaches();

      // Already unsubscribed — stale UI. Refresh so button flips to "Subscribe".
      case ApiErrorCode.userCoachAlreadyUnsubscribed:
        AppToast.info(context, 'Already unsubscribed from this coach.');
        ref.read(subscribedCoachesProvider.notifier).loadCoaches();

      // Coach at capacity or not accepting — warn, not error (not the user's fault)
      case ApiErrorCode.userCoachAtCapacity:
      case ApiErrorCode.userCoachNotAccepting:
        AppToast.warning(context, errorMessageFor(error));

      // Subscription required — show upgrade sheet
      case ApiErrorCode.subscriptionRequired:
      case ApiErrorCode.subscriptionTierInsufficient:
        showUpgradeSheet(
          context: context,
          feature: SubscriptionFeature.coachAccess,
        );

      default:
        AppToast.error(context, errorMessageFor(error));
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────

  IconData _getSocialIcon(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('instagram')) return Icons.camera_alt_outlined;
    if (lower.contains('twitter') || lower.contains('x.com')) {
      return Icons.alternate_email;
    }
    if (lower.contains('youtube')) return Icons.play_circle_outline;
    if (lower.contains('facebook')) return Icons.facebook_outlined;
    if (lower.contains('linkedin')) return Icons.work_outline;
    if (lower.contains('tiktok')) return Icons.music_note_outlined;
    return Icons.link;
  }

  String _getSocialLabel(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('instagram')) return 'Instagram';
    if (lower.contains('twitter') || lower.contains('x.com')) return 'X';
    if (lower.contains('youtube')) return 'YouTube';
    if (lower.contains('facebook')) return 'Facebook';
    if (lower.contains('linkedin')) return 'LinkedIn';
    if (lower.contains('tiktok')) return 'TikTok';
    return 'Website';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// ──────────────────────────────────────────────────────────
// Section Header
// ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
