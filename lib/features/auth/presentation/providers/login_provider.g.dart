part of 'login_provider.dart';

/// Login Provider
///
/// Manages login state and coordinates between:
/// - AuthRepository for API calls
/// - AuthStateNotifier for app-wide auth state
///
/// Supports two login flows:
///
/// **Email/Password Login:**
/// ```dart
/// await ref.read(loginProvider.notifier).loginWithEmailPassword(
///   email: 'user@example.com',
///   password: 'Password123!',
/// );
/// ```
///
/// **Google Login:**
/// ```dart
/// await ref.read(loginProvider.notifier).loginWithGoogle();
/// ```

@ProviderFor(LoginNotifier)
const loginProvider = LoginNotifierProvider._();

/// Login Provider
///
/// Manages login state and coordinates between:
/// - AuthRepository for API calls
/// - AuthStateNotifier for app-wide auth state
///
/// Supports two login flows:
///
/// **Email/Password Login:**
/// ```dart
/// await ref.read(loginProvider.notifier).loginWithEmailPassword(
///   email: 'user@example.com',
///   password: 'Password123!',
/// );
/// ```
///
/// **Google Login:**
/// ```dart
/// await ref.read(loginProvider.notifier).loginWithGoogle();
/// ```
final class LoginNotifierProvider
    extends $NotifierProvider<LoginNotifier, LoginState> {
  /// Login Provider
  ///
  /// Manages login state and coordinates between:
  /// - AuthRepository for API calls
  /// - AuthStateNotifier for app-wide auth state
  ///
  /// Supports two login flows:
  ///
  /// **Email/Password Login:**
  /// ```dart
  /// await ref.read(loginProvider.notifier).loginWithEmailPassword(
  ///   email: 'user@example.com',
  ///   password: 'Password123!',
  /// );
  /// ```
  ///
  /// **Google Login:**
  /// ```dart
  /// await ref.read(loginProvider.notifier).loginWithGoogle();
  /// ```
  const LoginNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginNotifierHash();

  @$internal
  @override
  LoginNotifier create() => LoginNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoginState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoginState>(value),
    );
  }
}

String _$loginNotifierHash() => r'22672501ce56cc41b0cfe22a8e0f6f350ee304bf';

/// Login Provider
///
/// Manages login state and coordinates between:
/// - AuthRepository for API calls
/// - AuthStateNotifier for app-wide auth state
///
/// Supports two login flows:
///
/// **Email/Password Login:**
/// ```dart
/// await ref.read(loginProvider.notifier).loginWithEmailPassword(
///   email: 'user@example.com',
///   password: 'Password123!',
/// );
/// ```
///
/// **Google Login:**
/// ```dart
/// await ref.read(loginProvider.notifier).loginWithGoogle();
/// ```

abstract class _$LoginNotifier extends $Notifier<LoginState> {
  LoginState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LoginState, LoginState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LoginState, LoginState>,
              LoginState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
