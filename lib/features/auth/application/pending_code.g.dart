// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_code.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PendingCodeController)
final pendingCodeControllerProvider = PendingCodeControllerProvider._();

final class PendingCodeControllerProvider
    extends $NotifierProvider<PendingCodeController, PendingCode?> {
  PendingCodeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingCodeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingCodeControllerHash();

  @$internal
  @override
  PendingCodeController create() => PendingCodeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingCode? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingCode?>(value),
    );
  }
}

String _$pendingCodeControllerHash() =>
    r'4e2d811fa3b4494d5e8f7c07b24609e98b2af33e';

abstract class _$PendingCodeController extends $Notifier<PendingCode?> {
  PendingCode? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PendingCode?, PendingCode?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PendingCode?, PendingCode?>,
              PendingCode?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
