// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_categories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Saved on the device, like other display choices.

@ProviderFor(HomeCategoriesController)
final homeCategoriesControllerProvider = HomeCategoriesControllerProvider._();

/// Saved on the device, like other display choices.
final class HomeCategoriesControllerProvider
    extends $NotifierProvider<HomeCategoriesController, HomeCategories> {
  /// Saved on the device, like other display choices.
  HomeCategoriesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeCategoriesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeCategoriesControllerHash();

  @$internal
  @override
  HomeCategoriesController create() => HomeCategoriesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeCategories value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeCategories>(value),
    );
  }
}

String _$homeCategoriesControllerHash() =>
    r'af6d8b5a0b35f87ec82718a0048a0c49d2e05acc';

/// Saved on the device, like other display choices.

abstract class _$HomeCategoriesController extends $Notifier<HomeCategories> {
  HomeCategories build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HomeCategories, HomeCategories>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HomeCategories, HomeCategories>,
              HomeCategories,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
