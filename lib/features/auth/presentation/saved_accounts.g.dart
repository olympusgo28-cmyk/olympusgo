// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_accounts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Accounts this phone can open with Face ID. Empty unless Face ID is on
/// (Q249).

@ProviderFor(savedAccounts)
final savedAccountsProvider = SavedAccountsProvider._();

/// Accounts this phone can open with Face ID. Empty unless Face ID is on
/// (Q249).

final class SavedAccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavedAccount>>,
          List<SavedAccount>,
          FutureOr<List<SavedAccount>>
        >
    with
        $FutureModifier<List<SavedAccount>>,
        $FutureProvider<List<SavedAccount>> {
  /// Accounts this phone can open with Face ID. Empty unless Face ID is on
  /// (Q249).
  SavedAccountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedAccountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedAccountsHash();

  @$internal
  @override
  $FutureProviderElement<List<SavedAccount>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SavedAccount>> create(Ref ref) {
    return savedAccounts(ref);
  }
}

String _$savedAccountsHash() => r'ec98f9bd8eff97646d4a5eb0bf5347766af52df6';
