// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(analysisStatus)
final analysisStatusProvider = AnalysisStatusProvider._();

final class AnalysisStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<AnalysisStatus>,
          AnalysisStatus,
          FutureOr<AnalysisStatus>
        >
    with $FutureModifier<AnalysisStatus>, $FutureProvider<AnalysisStatus> {
  AnalysisStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analysisStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analysisStatusHash();

  @$internal
  @override
  $FutureProviderElement<AnalysisStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AnalysisStatus> create(Ref ref) {
    return analysisStatus(ref);
  }
}

String _$analysisStatusHash() => r'45c9e72ad13bc2a5736094738385d9c3075960eb';

@ProviderFor(myClips)
final myClipsProvider = MyClipsProvider._();

final class MyClipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AnalysisClip>>,
          List<AnalysisClip>,
          FutureOr<List<AnalysisClip>>
        >
    with
        $FutureModifier<List<AnalysisClip>>,
        $FutureProvider<List<AnalysisClip>> {
  MyClipsProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'myClipsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myClipsHash();

  @$internal
  @override
  $FutureProviderElement<List<AnalysisClip>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AnalysisClip>> create(Ref ref) {
    return myClips(ref);
  }
}

String _$myClipsHash() => r'2939e0e7512daa046ce2b9bfa02a68aa14cf0d5f';

@ProviderFor(childClips)
final childClipsProvider = ChildClipsFamily._();

final class ChildClipsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AnalysisClip>>,
          List<AnalysisClip>,
          FutureOr<List<AnalysisClip>>
        >
    with
        $FutureModifier<List<AnalysisClip>>,
        $FutureProvider<List<AnalysisClip>> {
  ChildClipsProvider._({
    required ChildClipsFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'childClipsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$childClipsHash();

  @override
  String toString() {
    return r'childClipsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AnalysisClip>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AnalysisClip>> create(Ref ref) {
    final argument = this.argument as String;
    return childClips(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChildClipsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$childClipsHash() => r'6a329818162e4943ded3cf178fcf9e6aa01ac225';

final class ChildClipsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AnalysisClip>>, String> {
  ChildClipsFamily._()
    : super(
        retry: _noRetry,
        name: r'childClipsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChildClipsProvider call(String childId) =>
      ChildClipsProvider._(argument: childId, from: this);

  @override
  String toString() => r'childClipsProvider';
}

/// Asks again while the server works, and stops when the screen closes.

@ProviderFor(analysisClip)
final analysisClipProvider = AnalysisClipFamily._();

/// Asks again while the server works, and stops when the screen closes.

final class AnalysisClipProvider
    extends
        $FunctionalProvider<
          AsyncValue<AnalysisClip>,
          AnalysisClip,
          FutureOr<AnalysisClip>
        >
    with $FutureModifier<AnalysisClip>, $FutureProvider<AnalysisClip> {
  /// Asks again while the server works, and stops when the screen closes.
  AnalysisClipProvider._({
    required AnalysisClipFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'analysisClipProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$analysisClipHash();

  @override
  String toString() {
    return r'analysisClipProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AnalysisClip> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AnalysisClip> create(Ref ref) {
    final argument = this.argument as String;
    return analysisClip(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AnalysisClipProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$analysisClipHash() => r'0af4c66aee444f6f3c3722c38f3f8d68eb012fa8';

/// Asks again while the server works, and stops when the screen closes.

final class AnalysisClipFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AnalysisClip>, String> {
  AnalysisClipFamily._()
    : super(
        retry: _noRetry,
        name: r'analysisClipProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Asks again while the server works, and stops when the screen closes.

  AnalysisClipProvider call(String id) =>
      AnalysisClipProvider._(argument: id, from: this);

  @override
  String toString() => r'analysisClipProvider';
}

/// Clips on their way up from this phone. Outlives the screen, so leaving
/// during an upload doesn't read as an upload that failed.

@ProviderFor(ClipUploads)
final clipUploadsProvider = ClipUploadsProvider._();

/// Clips on their way up from this phone. Outlives the screen, so leaving
/// during an upload doesn't read as an upload that failed.
final class ClipUploadsProvider
    extends $NotifierProvider<ClipUploads, Set<String>> {
  /// Clips on their way up from this phone. Outlives the screen, so leaving
  /// during an upload doesn't read as an upload that failed.
  ClipUploadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipUploadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipUploadsHash();

  @$internal
  @override
  ClipUploads create() => ClipUploads();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$clipUploadsHash() => r'f12f6b88573012059f1caddf942a94534530ab55';

/// Clips on their way up from this phone. Outlives the screen, so leaving
/// during an upload doesn't read as an upload that failed.

abstract class _$ClipUploads extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(clipFrame)
final clipFrameProvider = ClipFrameFamily._();

final class ClipFrameProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClipFrame>,
          ClipFrame,
          FutureOr<ClipFrame>
        >
    with $FutureModifier<ClipFrame>, $FutureProvider<ClipFrame> {
  ClipFrameProvider._({
    required ClipFrameFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'clipFrameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clipFrameHash();

  @override
  String toString() {
    return r'clipFrameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ClipFrame> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ClipFrame> create(Ref ref) {
    final argument = this.argument as String;
    return clipFrame(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClipFrameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clipFrameHash() => r'd9c48bbfad3ea8c825f24e97245c6b55b2a0ed49';

final class ClipFrameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ClipFrame>, String> {
  ClipFrameFamily._()
    : super(
        retry: _noRetry,
        name: r'clipFrameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClipFrameProvider call(String path) =>
      ClipFrameProvider._(argument: path, from: this);

  @override
  String toString() => r'clipFrameProvider';
}

@ProviderFor(clipPicker)
final clipPickerProvider = ClipPickerProvider._();

final class ClipPickerProvider
    extends $FunctionalProvider<ClipPicker, ClipPicker, ClipPicker>
    with $Provider<ClipPicker> {
  ClipPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipPickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipPickerHash();

  @$internal
  @override
  $ProviderElement<ClipPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClipPicker create(Ref ref) {
    return clipPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClipPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClipPicker>(value),
    );
  }
}

String _$clipPickerHash() => r'18059c9ca5f46202a88925d642ece258d0415b90';
