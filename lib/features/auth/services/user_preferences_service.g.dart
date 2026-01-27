// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for UserPreferencesService

@ProviderFor(userPreferencesService)
const userPreferencesServiceProvider = UserPreferencesServiceProvider._();

/// Provider for UserPreferencesService

final class UserPreferencesServiceProvider
    extends
        $FunctionalProvider<
          UserPreferencesService,
          UserPreferencesService,
          UserPreferencesService
        >
    with $Provider<UserPreferencesService> {
  /// Provider for UserPreferencesService
  const UserPreferencesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userPreferencesServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userPreferencesServiceHash();

  @$internal
  @override
  $ProviderElement<UserPreferencesService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserPreferencesService create(Ref ref) {
    return userPreferencesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserPreferencesService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserPreferencesService>(value),
    );
  }
}

String _$userPreferencesServiceHash() =>
    r'0e8fbf560f47a42225d849092c9054ebcc6e27f5';
