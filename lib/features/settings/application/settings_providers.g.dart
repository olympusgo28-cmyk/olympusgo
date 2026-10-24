// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountDetails)
final accountDetailsProvider = AccountDetailsProvider._();

final class AccountDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AccountDetails>,
          AccountDetails,
          FutureOr<AccountDetails>
        >
    with $FutureModifier<AccountDetails>, $FutureProvider<AccountDetails> {
  AccountDetailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountDetailsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountDetailsHash();

  @$internal
  @override
  $FutureProviderElement<AccountDetails> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AccountDetails> create(Ref ref) {
    return accountDetails(ref);
  }
}

String _$accountDetailsHash() => r'0c7cede8385df2a653cab46081b4ef870a067c9c';

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

/// Face ID unlock on this phone.

@ProviderFor(FaceIdEnabled)
final faceIdEnabledProvider = FaceIdEnabledProvider._();

/// Face ID unlock on this phone.
final class FaceIdEnabledProvider
    extends $AsyncNotifierProvider<FaceIdEnabled, bool> {
  /// Face ID unlock on this phone.
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

String _$faceIdEnabledHash() => r'49dc48cbdc884cc939d98cb486d504ba7e267111';

/// Face ID unlock on this phone.

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
