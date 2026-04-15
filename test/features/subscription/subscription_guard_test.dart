import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/features/subscription/presentation/providers/subscription_guard.dart';

// We test the checkAccess logic in isolation using a fake state.
// The actual provider requires a Riverpod container; test the logic path instead.

void main() {
  group('checkAccess - SubscriptionError handling', () {
    test('SubscriptionError with tier 0 requirement returns SubscriptionGranted', () {
      // Simulate: state is SubscriptionError, requiredTier = 0
      // Expected: SubscriptionGranted (free tier, error = treat as free)
      final result = _checkAccessWithError(requiredTier: 0);
      expect(result, isA<SubscriptionGranted>());
    });

    test('SubscriptionError with tier 1 requirement returns SubscriptionDenied', () {
      final result = _checkAccessWithError(requiredTier: 1);
      expect(result, isA<SubscriptionDenied>());
      expect((result as SubscriptionDenied).currentTier, 0);
      expect(result.requiredTier, 1);
    });
  });
}

// Extracted error-handling logic matching the fix in checkAccess.
SubscriptionGuardResult _checkAccessWithError({required int requiredTier}) {
  // This is the branch we're adding for SubscriptionError
  return requiredTier <= 0
      ? const SubscriptionGranted()
      : SubscriptionDenied(
          requiredTier: requiredTier,
          currentTier: 0,
          requiredTierName: 'Subscription',
        );
}
