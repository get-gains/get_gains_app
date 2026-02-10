# Subscription Feature

## Overview

The Subscription feature provides in-app purchases, subscription management, and access control based on subscription tier levels. It integrates with the Google Play Store via the `in_app_purchase` package and syncs with the backend server.

## Architecture

```
lib/features/subscription/
├── subscription.dart                    # Feature barrel export
├── data/
│   ├── data.dart                        # Data layer barrel
│   ├── models/
│   │   ├── models.dart                  # Models barrel
│   │   ├── plan_model.dart              # Plan model with freezed
│   │   ├── subscription_model.dart      # Subscription model with status enums
│   │   └── subscription_status_model.dart # Status and verify request/response
│   └── subscription_repository.dart     # API repository
├── services/
│   ├── services.dart                    # Services barrel
│   └── in_app_purchase_service.dart     # Flutter IAP wrapper
└── presentation/
    ├── presentation.dart                # Presentation barrel
    ├── providers/
    │   ├── providers.dart               # Providers barrel
    │   ├── subscription_provider.dart   # Main state notifier
    │   └── subscription_guard.dart      # Access control guards
    └── widgets/
        ├── widgets.dart                 # Widgets barrel
        ├── profile_sheet.dart           # Profile bottom sheet
        ├── subscription_status_card.dart # Current subscription display
        ├── plan_card.dart               # Purchasable plan card
        └── upgrade_prompt.dart          # Upgrade CTA widget
```

## Tier Levels

Tier levels control feature access. The tier level is an integer where higher values grant more access.

| Level | Description                                        |
|-------|----------------------------------------------------|
| 0     | Default, no subscription (Free)                   |
| 1+    | Paid tiers - names come from plan configuration   |

> **Note**: Tier names (e.g., "Basic", "Premium", "Pro") are **not hardcoded**. They are derived from the plan names configured in the backend. Use `planNameForTierProvider` to get display names.

## Usage

### Import the Feature

```dart
import 'package:get_gains_app/features/subscription/subscription.dart';
```

### Watch Subscription State

```dart
// In a ConsumerWidget
final state = ref.watch(subscriptionProvider);

switch (state) {
  case SubscriptionInitial():
    return const Text('Not loaded');
  case SubscriptionLoading():
    return const AppCircularProgress();
  case SubscriptionLoaded():
    return Text('Tier: ${state.status.tierLevel}');
  case SubscriptionError():
    return Text('Error: ${state.error.message}');
}
```

### Convenience Providers

```dart
// Check if subscribed (any tier > 0)
final isSubscribed = ref.watch(isSubscribedProvider);

// Get current tier level
final tier = ref.watch(subscriptionTierProvider);

// Get current subscription (null if none)
final subscription = ref.watch(currentSubscriptionProvider);

// Get available plans
final plans = ref.watch(availablePlansProvider);

// Get plan name for a tier level (dynamic from backend)
final premiumName = ref.watch(planNameForTierProvider(2));
```

### Route Protection

Protect routes that require subscription:

```dart
// In your router configuration
GoRoute(
  path: '/premium-feature',
  redirect: (context, state) => subscriptionRouteGuard(
    ref,
    requiredTier: SubscriptionTiers.premium,
    redirectPath: '/upgrade',
  ),
  builder: (context, state) => const PremiumFeatureScreen(),
),
```

### Function Execution Guards

Guard async functions that require subscription:

```dart
Future<void> getCoaches(BuildContext context) async {
  final guard = ref.read(subscriptionGuardProvider);
  
  final canAccess = await guard.requireTier(
    SubscriptionTiers.premium,
    onDenied: (result) => showUpgradeSheet(
      context,
      requiredTier: result.requiredTier,
      tierName: result.requiredTierName,  // Uses plan name from backend
    ),
  );
  
  if (!canAccess) return;
  
  // Proceed with API call
  final coaches = await repository.getCoaches();
}
```

### Guarded Calls with Result

For operations that return `Result<T, AppError>`:

```dart
Future<Result<List<Coach>, AppError>> getCoaches() async {
  final guard = ref.read(subscriptionGuardProvider);
  
  return guard.guardedCall(
    requiredTier: SubscriptionTiers.premium,
    call: () => repository.getCoaches(),
  );
}
```

### Show Profile Sheet

Open the profile sheet from any screen:

```dart
// Add avatar button to app bar
AppAvatar(
  name: userName,
  size: AppAvatarSize.sm,
  onTap: () => showProfileSheet(context),
),
```

### Show Upgrade Prompt

Display upgrade prompt for gated features:

```dart
showUpgradeSheet(
  context,
  requiredTier: SubscriptionTiers.premium,
  featureName: 'Advanced Analytics',
  onUpgrade: () => navigateToPlans(),
);
```

### Conditional UI

Show/hide UI based on subscription:

```dart
final guard = ref.watch(subscriptionGuardProvider);

// Check tier access
if (guard.hasTier(SubscriptionTiers.premium)) {
  return const PremiumWidget();
} else {
  return UpgradePrompt(
    featureName: 'Premium Feature',
    requiredTier: SubscriptionTiers.premium,
  );
}
```

## API Endpoints

The feature uses these backend endpoints:

| Endpoint                    | Method | Description                    |
|-----------------------------|--------|--------------------------------|
| `/api/subscriptions/plans`  | GET    | Get available subscription plans |
| `/api/subscriptions/status` | GET    | Get current subscription status |
| `/api/subscriptions/verify` | POST   | Verify and activate purchase   |
| `/api/subscriptions/history`| GET    | Get subscription history       |

## Purchase Flow

1. User selects a plan from `PlanCard`
2. `SubscriptionNotifier.purchase(productId)` is called
3. `InAppPurchaseService` initiates store purchase
4. On successful store purchase, `verifyPurchase` is called
5. Backend verifies with Google Play and updates subscription
6. State is refreshed to reflect new subscription

```
┌─────────┐     ┌─────────────┐     ┌──────────────┐     ┌─────────┐
│   App   │────▶│ Play Store  │────▶│   Backend    │────▶│ Google  │
│         │◀────│             │◀────│              │◀────│   API   │
└─────────┘     └─────────────┘     └──────────────┘     └─────────┘
```

## In-App Purchase Service

The `InAppPurchaseService` wraps Flutter's `in_app_purchase` package with comprehensive error handling:

```dart
// Located at: lib/features/subscription/services/in_app_purchase_service.dart
final iapService = ref.read(inAppPurchaseServiceProvider);

// Initialize and load products
await iapService.initialize(['get_gains.premium']);

// Listen to purchase results
iapService.purchaseResults.listen((result) {
  switch (result.status) {
    case PurchaseState.completed:
      // Verify with server
      await verifyPurchase(result.purchaseDetails!);
    case PurchaseState.error:
      // Error message is already user-friendly
      showError(result.errorMessage);
    case PurchaseState.canceled:
      // User canceled - no error needed
    // ...
  }
});

// Purchase
await iapService.purchaseProduct('get_gains.premium');
```

## Billing Error Parser

The `BillingErrorParser` class converts technical billing errors into user-friendly messages:

```dart
// Located at: lib/features/subscription/services/billing_error_parser.dart

// Parse any error message
final userMessage = BillingErrorParser.parseErrorMessage(rawError);

// Check specific error types
if (BillingErrorParser.isUserCanceled(error)) {
  // Don't show error - user intentionally canceled
}

if (BillingErrorParser.isAlreadyOwned(error)) {
  // Prompt user to restore purchases instead
  showRestorePrompt();
}

if (BillingErrorParser.isNetworkError(error)) {
  // Show connectivity message
  showNetworkError();
}
```

**Error Code Mapping:**

| Code | User-Friendly Message |
|------|----------------------|
| `userCanceled (1)` | Purchase was canceled. |
| `serviceUnavailable (2)` | Google Play is temporarily unavailable. Please try again later. |
| `billingUnavailable (3)` | Google Play Billing is not available. Please update your device. |
| `itemUnavailable (4)` | This subscription is not available for purchase at this time. |
| `error (6)` | An error occurred during the purchase. Please try again. |
| `itemAlreadyOwned (7)` | You already own this subscription. Please restore your purchase instead. |
| `networkError (12)` | Network error. Please check your internet connection and try again. |

## Server Verification Flow

The complete flow for verifying a purchase with the backend:

```dart
// 1. Query available products
final products = await InAppPurchase.instance.queryProductDetails({'premium_monthly'});

// 2. Purchase
await InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

// 3. Verify with server
final response = await api.post('/subscriptions/verify', {
  'productId': purchase.productID,
  'purchaseToken': purchase.purchaseID,
  'provider': 'GOOGLE_PAY',
});

// 4. Complete purchase
await InAppPurchase.instance.completePurchase(purchase);
```

## Models

### PlanModel

```dart
PlanModel(
  id: 'plan-uuid',
  name: 'Premium Monthly',
  description: 'Full access to all features',
  price: 9.99,
  currency: 'USD',
  billingCycle: BillingCycle.monthly,
  productId: 'premium_monthly',
  tierLevel: 2,
  features: ['Feature 1', 'Feature 2'],
  trialDays: 7,
  isActive: true,
)
```

### SubscriptionModel

```dart
SubscriptionModel(
  id: 'sub-uuid',
  userId: 'user-uuid',
  plan: PlanSummary(...),
  status: SubscriptionStatus.active,
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 30)),
  autoRenew: true,
  paymentProvider: PaymentProvider.googlePay,
)
```

### SubscriptionStatusModel

```dart
SubscriptionStatusModel(
  isSubscribed: true,
  subscription: SubscriptionModel(...),
  canPurchase: false,
  tierLevel: 2,
)
```

## State Management

The subscription uses a sealed class hierarchy for state:

```dart
sealed class SubscriptionState {}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final SubscriptionStatusModel status;
  final List<PlanModel> plans;
  final bool purchaseInProgress;
  final String? purchaseError;
}

class SubscriptionError extends SubscriptionState {
  final AppError error;
}
```

## Dependencies

- `in_app_purchase: ^3.2.3` - Flutter IAP package
- Backend subscription endpoints
- Google Play Console configuration

## Testing

Mock the providers for testing:

```dart
// Mock subscription loaded state
testWidgets('shows premium content when subscribed', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionProvider.overrideWith(
          () => MockSubscriptionNotifier(
            SubscriptionLoaded(
              status: mockStatus(tierLevel: 2),
              plans: [],
            ),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
  
  expect(find.text('Premium Content'), findsOneWidget);
});
```

## Related Files

- [lib/core/constants/api_constants.dart](../../lib/core/constants/api_constants.dart) - API endpoints
- [lib/features/home/presentation/screens/home_screen.dart](../../lib/features/home/presentation/screens/home_screen.dart) - Profile avatar integration
