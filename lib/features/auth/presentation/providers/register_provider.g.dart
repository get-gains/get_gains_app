// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Register Provider
///
/// Manages registration state and coordinates between:
/// - AuthRepository for API calls
/// - AuthStateNotifier for app-wide auth state
/// - UserPreferencesService for offline data
///
/// Supports two registration flows:
///
/// **Email/Password Flow:**
/// ```dart
/// await ref.read(registerProvider.notifier).registerWithEmailPassword(
///   email: 'user@example.com',
///   password: 'Password123!',
///   name: 'John Doe',
///   nickname: 'johnd',
/// );
/// ```
///
/// **Google Sign-In Flow (2 steps):**
/// ```dart
/// // Step 1: Google sign-in
/// await ref.read(registerProvider.notifier).signInWithGoogle();
/// // If state is RegisterGooglePendingProfile, show profile form
///
/// // Step 2: Complete profile
/// await ref.read(registerProvider.notifier).completeGoogleSignUp(
///   name: 'John Doe',
///   nickname: 'johnd',
/// );
/// ```

@ProviderFor(RegisterNotifier)
const registerProvider = RegisterNotifierProvider._();

/// Register Provider
///
/// Manages registration state and coordinates between:
/// - AuthRepository for API calls
/// - AuthStateNotifier for app-wide auth state
/// - UserPreferencesService for offline data
///
/// Supports two registration flows:
///
/// **Email/Password Flow:**
/// ```dart
/// await ref.read(registerProvider.notifier).registerWithEmailPassword(
///   email: 'user@example.com',
///   password: 'Password123!',
///   name: 'John Doe',
///   nickname: 'johnd',
/// );
/// ```
///
/// **Google Sign-In Flow (2 steps):**
/// ```dart
/// // Step 1: Google sign-in
/// await ref.read(registerProvider.notifier).signInWithGoogle();
/// // If state is RegisterGooglePendingProfile, show profile form
///
/// // Step 2: Complete profile
/// await ref.read(registerProvider.notifier).completeGoogleSignUp(
///   name: 'John Doe',
///   nickname: 'johnd',
/// );
/// ```
final class RegisterNotifierProvider
    extends $NotifierProvider<RegisterNotifier, RegisterState> {
  /// Register Provider
  ///
  /// Manages registration state and coordinates between:
  /// - AuthRepository for API calls
  /// - AuthStateNotifier for app-wide auth state
  /// - UserPreferencesService for offline data
  ///
  /// Supports two registration flows:
  ///
  /// **Email/Password Flow:**
  /// ```dart
  /// await ref.read(registerProvider.notifier).registerWithEmailPassword(
  ///   email: 'user@example.com',
  ///   password: 'Password123!',
  ///   name: 'John Doe',
  ///   nickname: 'johnd',
  /// );
  /// ```
  ///
  /// **Google Sign-In Flow (2 steps):**
  /// ```dart
  /// // Step 1: Google sign-in
  /// await ref.read(registerProvider.notifier).signInWithGoogle();
  /// // If state is RegisterGooglePendingProfile, show profile form
  ///
  /// // Step 2: Complete profile
  /// await ref.read(registerProvider.notifier).completeGoogleSignUp(
  ///   name: 'John Doe',
  ///   nickname: 'johnd',
  /// );
  /// ```
  const RegisterNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registerNotifierHash();

  @$internal
  @override
  RegisterNotifier create() => RegisterNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegisterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegisterState>(value),
    );
  }
}

String _$registerNotifierHash() => r'08d928a68ec094170f7e5b4b17d0251a55e79e6e';

/// Register Provider
///
/// Manages registration state and coordinates between:
/// - AuthRepository for API calls
/// - AuthStateNotifier for app-wide auth state
/// - UserPreferencesService for offline data
///
/// Supports two registration flows:
///
/// **Email/Password Flow:**
/// ```dart
/// await ref.read(registerProvider.notifier).registerWithEmailPassword(
///   email: 'user@example.com',
///   password: 'Password123!',
///   name: 'John Doe',
///   nickname: 'johnd',
/// );
/// ```
///
/// **Google Sign-In Flow (2 steps):**
/// ```dart
/// // Step 1: Google sign-in
/// await ref.read(registerProvider.notifier).signInWithGoogle();
/// // If state is RegisterGooglePendingProfile, show profile form
///
/// // Step 2: Complete profile
/// await ref.read(registerProvider.notifier).completeGoogleSignUp(
///   name: 'John Doe',
///   nickname: 'johnd',
/// );
/// ```

abstract class _$RegisterNotifier extends $Notifier<RegisterState> {
  RegisterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<RegisterState, RegisterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RegisterState, RegisterState>,
              RegisterState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Password Recovery Provider
///
/// Handles password recovery email sending.
///
/// Usage:
/// ```dart
/// final result = await ref.read(passwordRecoveryProvider.notifier).sendRecoveryEmail(
///   email: 'user@example.com',
/// );
/// ```

@ProviderFor(PasswordRecoveryNotifier)
const passwordRecoveryProvider = PasswordRecoveryNotifierProvider._();

/// Password Recovery Provider
///
/// Handles password recovery email sending.
///
/// Usage:
/// ```dart
/// final result = await ref.read(passwordRecoveryProvider.notifier).sendRecoveryEmail(
///   email: 'user@example.com',
/// );
/// ```
final class PasswordRecoveryNotifierProvider
    extends $NotifierProvider<PasswordRecoveryNotifier, AsyncValue<void>> {
  /// Password Recovery Provider
  ///
  /// Handles password recovery email sending.
  ///
  /// Usage:
  /// ```dart
  /// final result = await ref.read(passwordRecoveryProvider.notifier).sendRecoveryEmail(
  ///   email: 'user@example.com',
  /// );
  /// ```
  const PasswordRecoveryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordRecoveryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordRecoveryNotifierHash();

  @$internal
  @override
  PasswordRecoveryNotifier create() => PasswordRecoveryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$passwordRecoveryNotifierHash() =>
    r'd7b139aee44ef53935806da8fe604e635f08eaf7';

/// Password Recovery Provider
///
/// Handles password recovery email sending.
///
/// Usage:
/// ```dart
/// final result = await ref.read(passwordRecoveryProvider.notifier).sendRecoveryEmail(
///   email: 'user@example.com',
/// );
/// ```

abstract class _$PasswordRecoveryNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Pending Google Profile Provider
///
/// Provides access to pending Google profile data.
/// Useful for pre-filling registration form with Google data.

@ProviderFor(pendingGoogleProfile)
const pendingGoogleProfileProvider = PendingGoogleProfileProvider._();

/// Pending Google Profile Provider
///
/// Provides access to pending Google profile data.
/// Useful for pre-filling registration form with Google data.

final class PendingGoogleProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<PendingGoogleProfile?>,
          PendingGoogleProfile?,
          FutureOr<PendingGoogleProfile?>
        >
    with
        $FutureModifier<PendingGoogleProfile?>,
        $FutureProvider<PendingGoogleProfile?> {
  /// Pending Google Profile Provider
  ///
  /// Provides access to pending Google profile data.
  /// Useful for pre-filling registration form with Google data.
  const PendingGoogleProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingGoogleProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingGoogleProfileHash();

  @$internal
  @override
  $FutureProviderElement<PendingGoogleProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PendingGoogleProfile?> create(Ref ref) {
    return pendingGoogleProfile(ref);
  }
}

String _$pendingGoogleProfileHash() =>
    r'b76b3e31d82af579e362134a77e0b1ff4465a7af';
