enum SubscriptionTier {
  free,
  premium;

  static SubscriptionTier fromString(String? value) =>
      value?.toUpperCase() == 'PREMIUM' ? premium : free;

  bool get isPaid => this == SubscriptionTier.premium;
}
