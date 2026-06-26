// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(unreadNotificationCount)
const unreadNotificationCountProvider = UnreadNotificationCountProvider._();

final class UnreadNotificationCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  const UnreadNotificationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return unreadNotificationCount(ref);
  }
}

String _$unreadNotificationCountHash() =>
    r'3861b8b56d2072ea8ffe5a4919ec592aa9a69195';

@ProviderFor(NotificationPoll)
const notificationPollProvider = NotificationPollProvider._();

final class NotificationPollProvider
    extends $NotifierProvider<NotificationPoll, int> {
  const NotificationPollProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPollProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPollHash();

  @$internal
  @override
  NotificationPoll create() => NotificationPoll();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$notificationPollHash() => r'0ebb693999ddb923eedc6deefa6ff9ec7a7291aa';

abstract class _$NotificationPoll extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(notificationList)
const notificationListProvider = NotificationListFamily._();

final class NotificationListProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotificationListState>,
          NotificationListState,
          FutureOr<NotificationListState>
        >
    with
        $FutureModifier<NotificationListState>,
        $FutureProvider<NotificationListState> {
  const NotificationListProvider._({
    required NotificationListFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'notificationListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$notificationListHash();

  @override
  String toString() {
    return r'notificationListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<NotificationListState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NotificationListState> create(Ref ref) {
    final argument = this.argument as int;
    return notificationList(ref, page: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$notificationListHash() => r'193863143b215e501420e12f20b764f0f888d648';

final class NotificationListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<NotificationListState>, int> {
  const NotificationListFamily._()
    : super(
        retry: null,
        name: r'notificationListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NotificationListProvider call({int page = 0}) =>
      NotificationListProvider._(argument: page, from: this);

  @override
  String toString() => r'notificationListProvider';
}
