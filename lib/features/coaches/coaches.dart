/// Coaches Feature (Client-Facing)
///
/// Client-side coach discovery, profiles, and subscription management.
///
/// Features:
/// - Discover and search public coaches
/// - View individual coach profiles
/// - Subscribe/unsubscribe to coaches (requires platform subscription)
/// - View subscribed coaches list
///
/// Missing Links addressed:
/// - ML-1: Single coach profile endpoint
/// - ML-2: Subscription guard handled server-side (409 on free-tier)
/// - ML-5: Coach capacity enforcement handled server-side (409 when full)
library;

// Data layer
export 'data/data.dart';

// Presentation layer
export 'presentation/presentation.dart';
