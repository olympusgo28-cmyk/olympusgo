// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(myReports)
final myReportsProvider = MyReportsProvider._();

final class MyReportsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SafetyReport>>,
          List<SafetyReport>,
          FutureOr<List<SafetyReport>>
        >
    with
        $FutureModifier<List<SafetyReport>>,
        $FutureProvider<List<SafetyReport>> {
  MyReportsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myReportsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myReportsHash();

  @$internal
  @override
  $FutureProviderElement<List<SafetyReport>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SafetyReport>> create(Ref ref) {
    return myReports(ref);
  }
}

String _$myReportsHash() => r'1f8085783698197144a13148d586489448e84d0f';

@ProviderFor(safetyReport)
final safetyReportProvider = SafetyReportFamily._();

final class SafetyReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<SafetyReport>,
          SafetyReport,
          FutureOr<SafetyReport>
        >
    with $FutureModifier<SafetyReport>, $FutureProvider<SafetyReport> {
  SafetyReportProvider._({
    required SafetyReportFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'safetyReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$safetyReportHash();

  @override
  String toString() {
    return r'safetyReportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SafetyReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SafetyReport> create(Ref ref) {
    final argument = this.argument as String;
    return safetyReport(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SafetyReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$safetyReportHash() => r'7f72410e46b356a3c0b0425e8afd4a6bf4c2167d';

final class SafetyReportFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SafetyReport>, String> {
  SafetyReportFamily._()
    : super(
        retry: null,
        name: r'safetyReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SafetyReportProvider call(String id) =>
      SafetyReportProvider._(argument: id, from: this);

  @override
  String toString() => r'safetyReportProvider';
}

@ProviderFor(removalNotice)
final removalNoticeProvider = RemovalNoticeFamily._();

final class RemovalNoticeProvider
    extends
        $FunctionalProvider<
          AsyncValue<RemovalNotice>,
          RemovalNotice,
          FutureOr<RemovalNotice>
        >
    with $FutureModifier<RemovalNotice>, $FutureProvider<RemovalNotice> {
  RemovalNoticeProvider._({
    required RemovalNoticeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'removalNoticeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$removalNoticeHash();

  @override
  String toString() {
    return r'removalNoticeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RemovalNotice> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RemovalNotice> create(Ref ref) {
    final argument = this.argument as String;
    return removalNotice(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RemovalNoticeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$removalNoticeHash() => r'a1aff06b23e066d915e2747d12a14bcdcdda5699';

final class RemovalNoticeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RemovalNotice>, String> {
  RemovalNoticeFamily._()
    : super(
        retry: null,
        name: r'removalNoticeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RemovalNoticeProvider call(String id) =>
      RemovalNoticeProvider._(argument: id, from: this);

  @override
  String toString() => r'removalNoticeProvider';
}
