// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_services.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Saved on the device, like other display choices.

@ProviderFor(HomeServicesController)
final homeServicesControllerProvider = HomeServicesControllerProvider._();

/// Saved on the device, like other display choices.
final class HomeServicesControllerProvider
    extends $NotifierProvider<HomeServicesController, HomeServices> {
  /// Saved on the device, like other display choices.
  HomeServicesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeServicesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeServicesControllerHash();

  @$internal
  @override
  HomeServicesController create() => HomeServicesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeServices value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeServices>(value),
    );
  }
}

String _$homeServicesControllerHash() =>
    r'0863108d2f5c39578474fc11e5bb9bd27114f666';

/// Saved on the device, like other display choices.

abstract class _$HomeServicesController extends $Notifier<HomeServices> {
  HomeServices build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HomeServices, HomeServices>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HomeServices, HomeServices>,
              HomeServices,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
