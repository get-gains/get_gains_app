import 'api_error_codes.dart';
import '../utils/app_error.dart';

/// Returns a user-facing string for the given [AppError].
///
/// Prefers the typed server [ApiErrorCode] when present (so UX is stable
/// even if the server's English copy changes). Falls back to [AppError.message].
///
/// When l10n lands, swap the [_messageForCode] switch body with `intl` lookups
/// keyed by [ApiErrorCode.value]. No other file needs to change.
String errorMessageFor(AppError error) {
  final code = error.code;
  if (code == null) return error.message;
  return _messageForCode(code) ?? error.message;
}

/// Convenience for screens that use [AppToast.error] with a title + body.
///
/// Returns a record with a short [title] and a longer [body]. The title is
/// generic per error category; the body is the code-aware message.
({String title, String body}) errorToastFor(AppError error) {
  final body = errorMessageFor(error);
  final title = _titleForError(error);
  return (title: title, body: body);
}

String _titleForError(AppError error) => switch (error) {
  AuthError() => 'Authentication Error',
  ValidationError() => 'Validation Error',
  SubscriptionRequiredError() => 'Subscription Required',
  NetworkError(statusCode: final s) when s != null && s >= 500 =>
    'Server Error',
  NetworkError() => 'Network Error',
  DatabaseError() => 'Database Error',
  CacheError() => 'Cache Error',
  UnknownError() => 'Error',
};

/// Curated code → user-facing message map.
///
/// Only codes where we want a _better_ UX than the raw server copy are listed.
/// The default `_` returns `null`, deferring to [AppError.message].
String? _messageForCode(ApiErrorCode code) => switch (code) {
  // ── Auth ──────────────────────────────────────────────────────────
  ApiErrorCode.authInvalidCredentials => 'Invalid email or password.',
  ApiErrorCode.authEmailNotVerified =>
    'Please verify your email before signing in.',
  ApiErrorCode.authEmailAlreadyExists =>
    'An account with this email already exists.',
  ApiErrorCode.authUserBanned =>
    'This account has been suspended. Contact support.',
  ApiErrorCode.authWeakPassword => 'Password is too weak.',
  ApiErrorCode.authSamePassword => 'Please choose a different password.',
  ApiErrorCode.authRateLimited => 'Too many attempts. Please wait a moment.',

  // ── User / Coach ──────────────────────────────────────────────────
  ApiErrorCode.userUsernameTaken => 'That username is already taken.',
  ApiErrorCode.userEmailTaken => 'That email is already in use.',
  ApiErrorCode.userCoachAtCapacity =>
    'This coach is no longer accepting clients.',
  ApiErrorCode.userCoachNotAccepting =>
    'This coach is paused and not accepting clients.',
  ApiErrorCode.userCoachAlreadySubscribed =>
    "You're already subscribed to this coach.",

  // ── Coins / Shop ─────────────────────────────────────────────────
  ApiErrorCode.coinInsufficientBalance => "You don't have enough coins.",
  ApiErrorCode.shopItemAlreadyOwned => 'You already own this item.',
  ApiErrorCode.shopItemOutOfStock => 'This item is out of stock.',

  // ── Workout ───────────────────────────────────────────────────────
  ApiErrorCode.workoutSessionAlreadyActive =>
    'A workout is already in progress.',

  // ── Subscription ──────────────────────────────────────────────────
  ApiErrorCode.subscriptionRequired =>
    'This feature requires an active subscription.',
  ApiErrorCode.subscriptionTierInsufficient =>
    'This feature requires a higher-tier plan.',

  // ── Generic ───────────────────────────────────────────────────────
  ApiErrorCode.rateLimited => "You're going too fast. Try again shortly.",
  ApiErrorCode.validationError => 'Please check the form and try again.',
  ApiErrorCode.routeNotFound => 'That resource is no longer available.',
  ApiErrorCode.unexpectedException => 'Something went wrong. Please try again.',

  // Codes not listed here defer to the server's own message.
  _ => null,
};
