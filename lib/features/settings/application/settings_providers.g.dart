// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(privateInfo)
final privateInfoProvider = PrivateInfoProvider._();

final class PrivateInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<PrivateInfo>,
          PrivateInfo,
          FutureOr<PrivateInfo>
        >
    with $FutureModifier<PrivateInfo>, $FutureProvider<PrivateInfo> {
  PrivateInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privateInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privateInfoHash();

  @$internal
  @override
  $FutureProviderElement<PrivateInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PrivateInfo> create(Ref ref) {
    return privateInfo(ref);
  }
}

String _$privateInfoHash() => r'f52f7d093b79a57edd675a53b1a179923fa3bffa';

/// The Account information screen. A failed load is not retried behind the
/// player's back (Riverpod would retry forever and the screen would never
/// leave its skeleton); the screen shows the error and Try again.

@ProviderFor(AccountInfoNotifier)
final accountInfoProvider = AccountInfoNotifierProvider._();

/// The Account information screen. A failed load is not retried behind the
/// player's back (Riverpod would retry forever and the screen would never
/// leave its skeleton); the screen shows the error and Try again.
final class AccountInfoNotifierProvider
    extends $AsyncNotifierProvider<AccountInfoNotifier, AccountInfo> {
  /// The Account information screen. A failed load is not retried behind the
  /// player's back (Riverpod would retry forever and the screen would never
  /// leave its skeleton); the screen shows the error and Try again.
  AccountInfoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'accountInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountInfoNotifierHash();

  @$internal
  @override
  AccountInfoNotifier create() => AccountInfoNotifier();
}

String _$accountInfoNotifierHash() =>
    r'58bac9dc4df7068a3d7d10d9b282a12a0671b211';

/// The Account information screen. A failed load is not retried behind the
/// player's back (Riverpod would retry forever and the screen would never
/// leave its skeleton); the screen shows the error and Try again.

abstract class _$AccountInfoNotifier extends $AsyncNotifier<AccountInfo> {
  FutureOr<AccountInfo> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AccountInfo>, AccountInfo>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AccountInfo>, AccountInfo>,
              AsyncValue<AccountInfo>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Edit profile. Each edit saves on its own screen and shows here straight
/// away; Profile and the rest of the app reload with it. Sports load here
/// too, so a failed load shows Try again at once instead of retrying.

@ProviderFor(MyProfileNotifier)
final myProfileProvider = MyProfileNotifierProvider._();

/// Edit profile. Each edit saves on its own screen and shows here straight
/// away; Profile and the rest of the app reload with it. Sports load here
/// too, so a failed load shows Try again at once instead of retrying.
final class MyProfileNotifierProvider
    extends $AsyncNotifierProvider<MyProfileNotifier, MyProfile> {
  /// Edit profile. Each edit saves on its own screen and shows here straight
  /// away; Profile and the rest of the app reload with it. Sports load here
  /// too, so a failed load shows Try again at once instead of retrying.
  MyProfileNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'myProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myProfileNotifierHash();

  @$internal
  @override
  MyProfileNotifier create() => MyProfileNotifier();
}

String _$myProfileNotifierHash() => r'a0c59fb02ce281c4333d7a30d5d1d621f8c97070';

/// Edit profile. Each edit saves on its own screen and shows here straight
/// away; Profile and the rest of the app reload with it. Sports load here
/// too, so a failed load shows Try again at once instead of retrying.

abstract class _$MyProfileNotifier extends $AsyncNotifier<MyProfile> {
  FutureOr<MyProfile> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MyProfile>, MyProfile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MyProfile>, MyProfile>,
              AsyncValue<MyProfile>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Notification switches. Each change saves straight away.

@ProviderFor(NotificationSettings)
final notificationSettingsProvider = NotificationSettingsProvider._();

/// Notification switches. Each change saves straight away.
final class NotificationSettingsProvider
    extends $AsyncNotifierProvider<NotificationSettings, NotificationPrefs> {
  /// Notification switches. Each change saves straight away.
  NotificationSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationSettingsHash();

  @$internal
  @override
  NotificationSettings create() => NotificationSettings();
}

String _$notificationSettingsHash() =>
    r'86eec1679c1f90f946592790131643f1d7016469';

/// Notification switches. Each change saves straight away.

abstract class _$NotificationSettings
    extends $AsyncNotifier<NotificationPrefs> {
  FutureOr<NotificationPrefs> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<NotificationPrefs>, NotificationPrefs>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NotificationPrefs>, NotificationPrefs>,
              AsyncValue<NotificationPrefs>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Privacy switches. Each change saves straight away.

@ProviderFor(PrivacySettings)
final privacySettingsProvider = PrivacySettingsProvider._();

/// Privacy switches. Each change saves straight away.
final class PrivacySettingsProvider
    extends $AsyncNotifierProvider<PrivacySettings, PrivacyPrefs> {
  /// Privacy switches. Each change saves straight away.
  PrivacySettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacySettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacySettingsHash();

  @$internal
  @override
  PrivacySettings create() => PrivacySettings();
}

String _$privacySettingsHash() => r'b2fe6670abfd0395377aeaf85debe3c3d1faea56';

/// Privacy switches. Each change saves straight away.

abstract class _$PrivacySettings extends $AsyncNotifier<PrivacyPrefs> {
  FutureOr<PrivacyPrefs> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PrivacyPrefs>, PrivacyPrefs>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PrivacyPrefs>, PrivacyPrefs>,
              AsyncValue<PrivacyPrefs>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Face ID unlock for the signed-in account on this phone. Off until this
/// player switches it on; another account on the same phone is not affected
/// (Q249).

@ProviderFor(FaceIdEnabled)
final faceIdEnabledProvider = FaceIdEnabledProvider._();

/// Face ID unlock for the signed-in account on this phone. Off until this
/// player switches it on; another account on the same phone is not affected
/// (Q249).
final class FaceIdEnabledProvider
    extends $AsyncNotifierProvider<FaceIdEnabled, bool> {
  /// Face ID unlock for the signed-in account on this phone. Off until this
  /// player switches it on; another account on the same phone is not affected
  /// (Q249).
  FaceIdEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'faceIdEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$faceIdEnabledHash();

  @$internal
  @override
  FaceIdEnabled create() => FaceIdEnabled();
}

String _$faceIdEnabledHash() => r'fb6683eb7526a52db1e8343699c518df9b2415a3';

/// Face ID unlock for the signed-in account on this phone. Off until this
/// player switches it on; another account on the same phone is not affected
/// (Q249).

abstract class _$FaceIdEnabled extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
