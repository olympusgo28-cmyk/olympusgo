// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(servicesRepository)
final servicesRepositoryProvider = ServicesRepositoryProvider._();

final class ServicesRepositoryProvider
    extends
        $FunctionalProvider<
          ServicesRepository,
          ServicesRepository,
          ServicesRepository
        >
    with $Provider<ServicesRepository> {
  ServicesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'servicesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$servicesRepositoryHash();

  @$internal
  @override
  $ProviderElement<ServicesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ServicesRepository create(Ref ref) {
    return servicesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServicesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServicesRepository>(value),
    );
  }
}

String _$servicesRepositoryHash() =>
    r'9abf2e3768d5c43832461692c9c1f32b588c9ec1';

@ProviderFor(servicePartners)
final servicePartnersProvider = ServicePartnersProvider._();

final class ServicePartnersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ServicePartner>>,
          List<ServicePartner>,
          FutureOr<List<ServicePartner>>
        >
    with
        $FutureModifier<List<ServicePartner>>,
        $FutureProvider<List<ServicePartner>> {
  ServicePartnersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'servicePartnersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$servicePartnersHash();

  @$internal
  @override
  $FutureProviderElement<List<ServicePartner>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ServicePartner>> create(Ref ref) {
    return servicePartners(ref);
  }
}

String _$servicePartnersHash() => r'4a632558788fce83f00b826c5c245bf194df7601';
