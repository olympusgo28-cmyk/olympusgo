// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discover_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(foundSessions)
final foundSessionsProvider = FoundSessionsFamily._();

final class FoundSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FoundSession>>,
          List<FoundSession>,
          FutureOr<List<FoundSession>>
        >
    with
        $FutureModifier<List<FoundSession>>,
        $FutureProvider<List<FoundSession>> {
  FoundSessionsProvider._({
    required FoundSessionsFamily super.from,
    required DiscoverFilter super.argument,
  }) : super(
         retry: null,
         name: r'foundSessionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foundSessionsHash();

  @override
  String toString() {
    return r'foundSessionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FoundSession>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FoundSession>> create(Ref ref) {
    final argument = this.argument as DiscoverFilter;
    return foundSessions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FoundSessionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foundSessionsHash() => r'0d316af0da8a92b9102ec26fba72bdbb1119f3fa';

final class FoundSessionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<FoundSession>>,
          DiscoverFilter
        > {
  FoundSessionsFamily._()
    : super(
        retry: null,
        name: r'foundSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FoundSessionsProvider call(DiscoverFilter filter) =>
      FoundSessionsProvider._(argument: filter, from: this);

  @override
  String toString() => r'foundSessionsProvider';
}
