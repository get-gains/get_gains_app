/// Subscription Feature Definitions
///
/// Centralizes per-feature upgrade prompt metadata used by
/// [UpgradePrompt] and [SubscriptionGatedWidget] for contextual messaging.
///
/// Each feature has a human-readable benefit description for display
/// in upgrade prompts and an analytics key for tracking.
library;

/// Enum defining subscription-gated features with contextual metadata.
///
/// Used by upgrade prompts to display feature-specific benefit text
/// and by analytics to track which features drive subscription interest.
enum SubscriptionFeature {
  /// Coach-designed workout routines
  coachRoutines(
    'Get coach-designed routines tailored to your goals',
    'coach_routines',
  ),

  /// Today's coach workout with guided progression
  coachWorkout(
    "Follow today's coach workout with guided progression",
    'coach_workout',
  ),

  /// Access to a coach for personalized programming
  coachAccess(
    'Subscribe to a coach for personalized programming',
    'coach_access',
  ),

  /// Coach program performance breakdown in stats
  coachStats('View your coach program performance breakdown', 'coach_stats');

  /// Human-readable benefit description shown in upgrade prompts.
  final String benefitDescription;

  /// Analytics key for tracking feature-specific upgrade interactions.
  final String analyticsKey;

  const SubscriptionFeature(this.benefitDescription, this.analyticsKey);
}
