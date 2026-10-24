// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(academyRepository)
final academyRepositoryProvider = AcademyRepositoryProvider._();

final class AcademyRepositoryProvider
    extends
        $FunctionalProvider<
          AcademyRepository,
          AcademyRepository,
          AcademyRepository
        >
    with $Provider<AcademyRepository> {
  AcademyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'academyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$academyRepositoryHash();

  @$internal
  @override
  $ProviderElement<AcademyRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AcademyRepository create(Ref ref) {
    return academyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AcademyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AcademyRepository>(value),
    );
  }
}

String _$academyRepositoryHash() => r'587a9b9c6fd79a115e9762d453abf3c8884da76a';

@ProviderFor(academyList)
final academyListProvider = AcademyListProvider._();

final class AcademyListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Academy>>,
          List<Academy>,
          FutureOr<List<Academy>>
        >
    with $FutureModifier<List<Academy>>, $FutureProvider<List<Academy>> {
  AcademyListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'academyListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$academyListHash();

  @$internal
  @override
  $FutureProviderElement<List<Academy>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Academy>> create(Ref ref) {
    return academyList(ref);
  }
}

String _$academyListHash() => r'5b510e0a720f91561561eec3828cf15ac7d3263a';

@ProviderFor(academy)
final academyProvider = AcademyFamily._();

final class AcademyProvider
    extends $FunctionalProvider<AsyncValue<Academy>, Academy, FutureOr<Academy>>
    with $FutureModifier<Academy>, $FutureProvider<Academy> {
  AcademyProvider._({
    required AcademyFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'academyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$academyHash();

  @override
  String toString() {
    return r'academyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Academy> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Academy> create(Ref ref) {
    final argument = this.argument as String;
    return academy(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$academyHash() => r'c3613f1ff49b4dca3c6837a7831a25688128c659';

final class AcademyFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Academy>, String> {
  AcademyFamily._()
    : super(
        retry: null,
        name: r'academyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AcademyProvider call(String id) =>
      AcademyProvider._(argument: id, from: this);

  @override
  String toString() => r'academyProvider';
}

@ProviderFor(myStudents)
final myStudentsProvider = MyStudentsProvider._();

final class MyStudentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Student>>,
          List<Student>,
          FutureOr<List<Student>>
        >
    with $FutureModifier<List<Student>>, $FutureProvider<List<Student>> {
  MyStudentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myStudentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myStudentsHash();

  @$internal
  @override
  $FutureProviderElement<List<Student>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Student>> create(Ref ref) {
    return myStudents(ref);
  }
}

String _$myStudentsHash() => r'96c973747f4894c66bcc0bf3a6b6a97e771cc907';

@ProviderFor(student)
final studentProvider = StudentFamily._();

final class StudentProvider
    extends $FunctionalProvider<AsyncValue<Student>, Student, FutureOr<Student>>
    with $FutureModifier<Student>, $FutureProvider<Student> {
  StudentProvider._({
    required StudentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'studentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studentHash();

  @override
  String toString() {
    return r'studentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Student> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Student> create(Ref ref) {
    final argument = this.argument as String;
    return student(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentHash() => r'8b29bd7636bfb6a9d4d0756ffe67f073cfbdfb47';

final class StudentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Student>, String> {
  StudentFamily._()
    : super(
        retry: null,
        name: r'studentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StudentProvider call(String id) =>
      StudentProvider._(argument: id, from: this);

  @override
  String toString() => r'studentProvider';
}

@ProviderFor(studentLessons)
final studentLessonsProvider = StudentLessonsFamily._();

final class StudentLessonsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LessonWeek>>,
          List<LessonWeek>,
          FutureOr<List<LessonWeek>>
        >
    with $FutureModifier<List<LessonWeek>>, $FutureProvider<List<LessonWeek>> {
  StudentLessonsProvider._({
    required StudentLessonsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'studentLessonsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studentLessonsHash();

  @override
  String toString() {
    return r'studentLessonsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<LessonWeek>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LessonWeek>> create(Ref ref) {
    final argument = this.argument as String;
    return studentLessons(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentLessonsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentLessonsHash() => r'fe1afc6df841c9647c402e084b14777e422dfed0';

final class StudentLessonsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<LessonWeek>>, String> {
  StudentLessonsFamily._()
    : super(
        retry: null,
        name: r'studentLessonsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StudentLessonsProvider call(String id) =>
      StudentLessonsProvider._(argument: id, from: this);

  @override
  String toString() => r'studentLessonsProvider';
}

@ProviderFor(studentInvoices)
final studentInvoicesProvider = StudentInvoicesFamily._();

final class StudentInvoicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Invoice>>,
          List<Invoice>,
          FutureOr<List<Invoice>>
        >
    with $FutureModifier<List<Invoice>>, $FutureProvider<List<Invoice>> {
  StudentInvoicesProvider._({
    required StudentInvoicesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'studentInvoicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studentInvoicesHash();

  @override
  String toString() {
    return r'studentInvoicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Invoice>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Invoice>> create(Ref ref) {
    final argument = this.argument as String;
    return studentInvoices(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentInvoicesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentInvoicesHash() => r'217ef4ee88709d42527e927fc4cc1769c2da82f2';

final class StudentInvoicesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Invoice>>, String> {
  StudentInvoicesFamily._()
    : super(
        retry: null,
        name: r'studentInvoicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StudentInvoicesProvider call(String id) =>
      StudentInvoicesProvider._(argument: id, from: this);

  @override
  String toString() => r'studentInvoicesProvider';
}

@ProviderFor(makeupSlots)
final makeupSlotsProvider = MakeupSlotsFamily._();

final class MakeupSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MakeupSlot>>,
          List<MakeupSlot>,
          FutureOr<List<MakeupSlot>>
        >
    with $FutureModifier<List<MakeupSlot>>, $FutureProvider<List<MakeupSlot>> {
  MakeupSlotsProvider._({
    required MakeupSlotsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'makeupSlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$makeupSlotsHash();

  @override
  String toString() {
    return r'makeupSlotsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MakeupSlot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MakeupSlot>> create(Ref ref) {
    final argument = this.argument as String;
    return makeupSlots(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MakeupSlotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$makeupSlotsHash() => r'f1a46c651468e70e460f702abdc3a7fe190898e7';

final class MakeupSlotsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MakeupSlot>>, String> {
  MakeupSlotsFamily._()
    : super(
        retry: null,
        name: r'makeupSlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MakeupSlotsProvider call(String studentId) =>
      MakeupSlotsProvider._(argument: studentId, from: this);

  @override
  String toString() => r'makeupSlotsProvider';
}

@ProviderFor(trialSlots)
final trialSlotsProvider = TrialSlotsFamily._();

final class TrialSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MakeupSlot>>,
          List<MakeupSlot>,
          FutureOr<List<MakeupSlot>>
        >
    with $FutureModifier<List<MakeupSlot>>, $FutureProvider<List<MakeupSlot>> {
  TrialSlotsProvider._({
    required TrialSlotsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'trialSlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trialSlotsHash();

  @override
  String toString() {
    return r'trialSlotsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MakeupSlot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MakeupSlot>> create(Ref ref) {
    final argument = this.argument as String;
    return trialSlots(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrialSlotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trialSlotsHash() => r'edf83cd2a0933600c2cacc14a5cc81db4c00eacf';

final class TrialSlotsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MakeupSlot>>, String> {
  TrialSlotsFamily._()
    : super(
        retry: null,
        name: r'trialSlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TrialSlotsProvider call(String academyId) =>
      TrialSlotsProvider._(argument: academyId, from: this);

  @override
  String toString() => r'trialSlotsProvider';
}

@ProviderFor(coachAlerts)
final coachAlertsProvider = CoachAlertsFamily._();

final class CoachAlertsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CoachAlert>>,
          List<CoachAlert>,
          FutureOr<List<CoachAlert>>
        >
    with $FutureModifier<List<CoachAlert>>, $FutureProvider<List<CoachAlert>> {
  CoachAlertsProvider._({
    required CoachAlertsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'coachAlertsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coachAlertsHash();

  @override
  String toString() {
    return r'coachAlertsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CoachAlert>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CoachAlert>> create(Ref ref) {
    final argument = this.argument as String;
    return coachAlerts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CoachAlertsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coachAlertsHash() => r'e2e9125b745c5856fc43674f57284c993c18d1da';

final class CoachAlertsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CoachAlert>>, String> {
  CoachAlertsFamily._()
    : super(
        retry: null,
        name: r'coachAlertsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CoachAlertsProvider call(String academyId) =>
      CoachAlertsProvider._(argument: academyId, from: this);

  @override
  String toString() => r'coachAlertsProvider';
}

@ProviderFor(enrolRequests)
final enrolRequestsProvider = EnrolRequestsFamily._();

final class EnrolRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EnrolRequest>>,
          List<EnrolRequest>,
          FutureOr<List<EnrolRequest>>
        >
    with
        $FutureModifier<List<EnrolRequest>>,
        $FutureProvider<List<EnrolRequest>> {
  EnrolRequestsProvider._({
    required EnrolRequestsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'enrolRequestsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$enrolRequestsHash();

  @override
  String toString() {
    return r'enrolRequestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<EnrolRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EnrolRequest>> create(Ref ref) {
    final argument = this.argument as String;
    return enrolRequests(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EnrolRequestsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$enrolRequestsHash() => r'79e1b436d27da86f4f1f2e3d2021366c3dd3c861';

final class EnrolRequestsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<EnrolRequest>>, String> {
  EnrolRequestsFamily._()
    : super(
        retry: null,
        name: r'enrolRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EnrolRequestsProvider call(String academyId) =>
      EnrolRequestsProvider._(argument: academyId, from: this);

  @override
  String toString() => r'enrolRequestsProvider';
}

@ProviderFor(classRoster)
final classRosterProvider = ClassRosterFamily._();

final class ClassRosterProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Student>>,
          List<Student>,
          FutureOr<List<Student>>
        >
    with $FutureModifier<List<Student>>, $FutureProvider<List<Student>> {
  ClassRosterProvider._({
    required ClassRosterFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'classRosterProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$classRosterHash();

  @override
  String toString() {
    return r'classRosterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Student>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Student>> create(Ref ref) {
    final argument = this.argument as String;
    return classRoster(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassRosterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$classRosterHash() => r'7f12eeac234b4bd261a4e746d04fecffa77a5c33';

final class ClassRosterFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Student>>, String> {
  ClassRosterFamily._()
    : super(
        retry: null,
        name: r'classRosterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClassRosterProvider call(String classId) =>
      ClassRosterProvider._(argument: classId, from: this);

  @override
  String toString() => r'classRosterProvider';
}

/// The create-academy answers, kept across the five steps.

@ProviderFor(AcademyDraftController)
final academyDraftControllerProvider = AcademyDraftControllerProvider._();

/// The create-academy answers, kept across the five steps.
final class AcademyDraftControllerProvider
    extends $NotifierProvider<AcademyDraftController, AcademyDraft> {
  /// The create-academy answers, kept across the five steps.
  AcademyDraftControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'academyDraftControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$academyDraftControllerHash();

  @$internal
  @override
  AcademyDraftController create() => AcademyDraftController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AcademyDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AcademyDraft>(value),
    );
  }
}

String _$academyDraftControllerHash() =>
    r'932ef34a4f2d264cf8ab109bdf040da281e25af5';

/// The create-academy answers, kept across the five steps.

abstract class _$AcademyDraftController extends $Notifier<AcademyDraft> {
  AcademyDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AcademyDraft, AcademyDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AcademyDraft, AcademyDraft>,
              AcademyDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(academyMessages)
final academyMessagesProvider = AcademyMessagesFamily._();

final class AcademyMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MessageThread>>,
          List<MessageThread>,
          FutureOr<List<MessageThread>>
        >
    with
        $FutureModifier<List<MessageThread>>,
        $FutureProvider<List<MessageThread>> {
  AcademyMessagesProvider._({
    required AcademyMessagesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'academyMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$academyMessagesHash();

  @override
  String toString() {
    return r'academyMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MessageThread>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MessageThread>> create(Ref ref) {
    final argument = this.argument as String;
    return academyMessages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$academyMessagesHash() => r'9c9fd065fead09aab6113e56b2eab0a8578819ef';

final class AcademyMessagesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MessageThread>>, String> {
  AcademyMessagesFamily._()
    : super(
        retry: null,
        name: r'academyMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AcademyMessagesProvider call(String academyId) =>
      AcademyMessagesProvider._(argument: academyId, from: this);

  @override
  String toString() => r'academyMessagesProvider';
}

@ProviderFor(coachPay)
final coachPayProvider = CoachPayProvider._();

final class CoachPayProvider
    extends
        $FunctionalProvider<AsyncValue<CoachPay>, CoachPay, FutureOr<CoachPay>>
    with $FutureModifier<CoachPay>, $FutureProvider<CoachPay> {
  CoachPayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachPayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachPayHash();

  @$internal
  @override
  $FutureProviderElement<CoachPay> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CoachPay> create(Ref ref) {
    return coachPay(ref);
  }
}

String _$coachPayHash() => r'31079f1789ff2c19193781b8e8cb22e2ac8faedc';

@ProviderFor(curriculum)
final curriculumProvider = CurriculumFamily._();

final class CurriculumProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CurriculumWeek>>,
          List<CurriculumWeek>,
          FutureOr<List<CurriculumWeek>>
        >
    with
        $FutureModifier<List<CurriculumWeek>>,
        $FutureProvider<List<CurriculumWeek>> {
  CurriculumProvider._({
    required CurriculumFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'curriculumProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$curriculumHash();

  @override
  String toString() {
    return r'curriculumProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<CurriculumWeek>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CurriculumWeek>> create(Ref ref) {
    final argument = this.argument as (String, int);
    return curriculum(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CurriculumProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$curriculumHash() => r'8042a030df96cbde952c273ed65408f5b23b8386';

final class CurriculumFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<CurriculumWeek>>,
          (String, int)
        > {
  CurriculumFamily._()
    : super(
        retry: null,
        name: r'curriculumProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurriculumProvider call(String academyId, int level) =>
      CurriculumProvider._(argument: (academyId, level), from: this);

  @override
  String toString() => r'curriculumProvider';
}

@ProviderFor(curriculumClasses)
final curriculumClassesProvider = CurriculumClassesFamily._();

final class CurriculumClassesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClassProgress>>,
          List<ClassProgress>,
          FutureOr<List<ClassProgress>>
        >
    with
        $FutureModifier<List<ClassProgress>>,
        $FutureProvider<List<ClassProgress>> {
  CurriculumClassesProvider._({
    required CurriculumClassesFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'curriculumClassesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$curriculumClassesHash();

  @override
  String toString() {
    return r'curriculumClassesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ClassProgress>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClassProgress>> create(Ref ref) {
    final argument = this.argument as (String, int);
    return curriculumClasses(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CurriculumClassesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$curriculumClassesHash() => r'63feaa79475a9616dce80b14fbd77f938c4130d4';

final class CurriculumClassesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ClassProgress>>,
          (String, int)
        > {
  CurriculumClassesFamily._()
    : super(
        retry: null,
        name: r'curriculumClassesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurriculumClassesProvider call(String academyId, int level) =>
      CurriculumClassesProvider._(argument: (academyId, level), from: this);

  @override
  String toString() => r'curriculumClassesProvider';
}

@ProviderFor(drillVideos)
final drillVideosProvider = DrillVideosProvider._();

final class DrillVideosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Drill>>,
          List<Drill>,
          FutureOr<List<Drill>>
        >
    with $FutureModifier<List<Drill>>, $FutureProvider<List<Drill>> {
  DrillVideosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'drillVideosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$drillVideosHash();

  @$internal
  @override
  $FutureProviderElement<List<Drill>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Drill>> create(Ref ref) {
    return drillVideos(ref);
  }
}

String _$drillVideosHash() => r'e7d15b809368726e8f6a469ce705a711acd3d1a1';

@ProviderFor(pendingInvites)
final pendingInvitesProvider = PendingInvitesFamily._();

final class PendingInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<(String, String)>>,
          List<(String, String)>,
          FutureOr<List<(String, String)>>
        >
    with
        $FutureModifier<List<(String, String)>>,
        $FutureProvider<List<(String, String)>> {
  PendingInvitesProvider._({
    required PendingInvitesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pendingInvitesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingInvitesHash();

  @override
  String toString() {
    return r'pendingInvitesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<(String, String)>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<(String, String)>> create(Ref ref) {
    final argument = this.argument as String;
    return pendingInvites(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingInvitesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingInvitesHash() => r'b3068bb6de2814d15502cf89f5d6de425d10fb12';

final class PendingInvitesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<(String, String)>>, String> {
  PendingInvitesFamily._()
    : super(
        retry: null,
        name: r'pendingInvitesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PendingInvitesProvider call(String classId) =>
      PendingInvitesProvider._(argument: classId, from: this);

  @override
  String toString() => r'pendingInvitesProvider';
}

@ProviderFor(attendance)
final attendanceProvider = AttendanceFamily._();

final class AttendanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AttendanceLine>>,
          List<AttendanceLine>,
          FutureOr<List<AttendanceLine>>
        >
    with
        $FutureModifier<List<AttendanceLine>>,
        $FutureProvider<List<AttendanceLine>> {
  AttendanceProvider._({
    required AttendanceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'attendanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attendanceHash();

  @override
  String toString() {
    return r'attendanceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AttendanceLine>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AttendanceLine>> create(Ref ref) {
    final argument = this.argument as String;
    return attendance(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AttendanceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attendanceHash() => r'12d4d570fda51fdfd030d46f62d28e3ca92a867e';

final class AttendanceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AttendanceLine>>, String> {
  AttendanceFamily._()
    : super(
        retry: null,
        name: r'attendanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AttendanceProvider call(String studentId) =>
      AttendanceProvider._(argument: studentId, from: this);

  @override
  String toString() => r'attendanceProvider';
}

@ProviderFor(coverCoaches)
final coverCoachesProvider = CoverCoachesFamily._();

final class CoverCoachesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CoverCoach>>,
          List<CoverCoach>,
          FutureOr<List<CoverCoach>>
        >
    with $FutureModifier<List<CoverCoach>>, $FutureProvider<List<CoverCoach>> {
  CoverCoachesProvider._({
    required CoverCoachesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'coverCoachesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coverCoachesHash();

  @override
  String toString() {
    return r'coverCoachesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CoverCoach>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CoverCoach>> create(Ref ref) {
    final argument = this.argument as String;
    return coverCoaches(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CoverCoachesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coverCoachesHash() => r'be087358242a814436f1d72e2137100cab28287e';

final class CoverCoachesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CoverCoach>>, String> {
  CoverCoachesFamily._()
    : super(
        retry: null,
        name: r'coverCoachesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CoverCoachesProvider call(String classId) =>
      CoverCoachesProvider._(argument: classId, from: this);

  @override
  String toString() => r'coverCoachesProvider';
}
