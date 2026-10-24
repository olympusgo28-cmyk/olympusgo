import 'package:freezed_annotation/freezed_annotation.dart';

import '../../onboarding/domain/sport.dart';

part 'academy_models.freezed.dart';

enum AcademyRole { none, parent, coach, headCoach }

enum Billing {
  term('Per term', 'term'),
  month('Monthly', 'month'),
  perClass('Per class', 'class');

  const Billing(this.label, this.unit);
  final String label;
  final String unit;
}

@freezed
abstract class AcademyCoach with _$AcademyCoach {
  const factory AcademyCoach({
    required String name,
    required String initials,
    required String role,
    @Default(true) bool nroc,
    @Default('') String id,
    @Default(false) bool head,
  }) = _AcademyCoach;
}

/// A weekly class.
@freezed
abstract class AcademyClass with _$AcademyClass {
  const factory AcademyClass({
    required String id,
    required String academyId,
    required String name,

    /// 1, 2, 3; "Rally Builders".
    required int level,
    @Default('') String levelName,

    /// DateTime.monday … DateTime.sunday.
    required List<int> weekdays,
    required int hour,
    @Default(0) int minute,
    @Default(90) int minutes,
    @Default('') String ages,
    required int feeCents,
    required int capacity,
    @Default(0) int enrolled,
    required String coach,
    @Default('') String coachId,
    @Default('') String court,
    @Default(1) int week,
    @Default(10) int termWeeks,

    /// This week's lesson, and the skill it works on (a [Skill.id]).
    @Default('') String lesson,
    @Default('') String focusSkill,
  }) = _AcademyClass;

  const AcademyClass._();

  int get spotsLeft => (capacity - enrolled).clamp(0, capacity);
  bool get full => spotsLeft == 0;

  /// The next time this class starts, after [from].
  DateTime nextAt([DateTime? from]) {
    final now = from ?? DateTime.now();
    for (var i = 0; i < 8; i++) {
      final d = DateTime(now.year, now.month, now.day + i, hour, minute);
      if (weekdays.contains(d.weekday) && d.isAfter(now)) return d;
    }
    return DateTime(now.year, now.month, now.day + 7, hour, minute);
  }

  DateTime endOf(DateTime start) => start.add(Duration(minutes: minutes));
}

@freezed
abstract class Academy with _$Academy {
  const factory Academy({
    required String id,
    required String name,
    required Sport sport,
    required String area,
    @Default('') String blurb,
    @Default('') String audience,
    double? rating,
    @Default(0) int ratingCount,
    @Default(0) int students,
    @Default(false) bool verified,
    @Default(Billing.month) Billing billing,
    @Default(2) int makeupsPerMonth,
    @Default([]) List<AcademyCoach> coaches,
    @Default([]) List<AcademyClass> classes,
    @Default(0xFF16181B) int color,
    @Default(0xFFF2C14E) int ink,

    /// The banner on the academy page, like a club's cover colour.
    @Default(0xFFE8590C) int coverColor,
    @Default(AcademyRole.none) AcademyRole myRole,
    @Default(0) int pendingRequests,

    /// 'none', 'submitted' or 'verified'.
    @Default('none') String verification,

    /// Coaches invited by email who haven't signed up yet.
    @Default([]) List<String> invitedCoaches,
  }) = _Academy;

  const Academy._();

  String get initials => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  int? get fromCents => classes.isEmpty
      ? null
      : classes.map((c) => c.feeCents).reduce((a, b) => a < b ? a : b);

  bool get isCoach =>
      myRole == AcademyRole.coach || myRole == AcademyRole.headCoach;
}

enum SkillStatus {
  notYet('Not yet'),
  practising('Practising'),
  gotIt('Got it');

  const SkillStatus(this.label);
  final String label;

  SkillStatus get next => values[(index + 1) % values.length];
}

@freezed
abstract class Skill with _$Skill {
  const factory Skill({
    required String id,
    required String group,
    required String name,
    @Default(SkillStatus.notYet) SkillStatus status,

    /// "Week 4" when it was last updated.
    @Default('') String week,
  }) = _Skill;
}

@freezed
abstract class CoachNote with _$CoachNote {
  const factory CoachNote({
    required String coach,
    required DateTime at,
    required String text,
    @Default('') String lesson,
    @Default(true) bool present,
    String? got,
    String? practising,
  }) = _CoachNote;
}

/// A child (or the player themself) in an academy class.
@freezed
abstract class Student with _$Student {
  const factory Student({
    required String id,
    required String name,
    int? age,
    required String academyId,
    required String classId,
    @Default('') String parent,
    @Default([]) List<Skill> skills,
    @Default(100) int attendancePct,
    @Default(0) int attended,
    @Default(0) int held,
    @Default(0) int makeupCredits,
    DateTime? creditUseBy,
    @Default('') String flag,
    @Default([]) List<CoachNote> notes,
    @Default(false) bool filmingConsent,

    /// A change the coach sent ("Saturday's class is now 10:30 AM"), and
    /// the parent's answer once given.
    String? notice,
    bool? noticeComing,
  }) = _Student;

  const Student._();

  String get initials => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  String get firstName => name.split(' ').first;

  int get skillsGot =>
      skills.where((s) => s.status == SkillStatus.gotIt).length;
}

/// One week of a class's term plan.
@freezed
abstract class LessonWeek with _$LessonWeek {
  const factory LessonWeek({
    required int week,
    required String title,
    @Default(false) bool attended,
  }) = _LessonWeek;
}

@freezed
abstract class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    required String title,
    required int feeCents,
    required int platformCents,
    required DateTime due,
    DateTime? paidOn,
  }) = _Invoice;

  const Invoice._();

  int get totalCents => feeCents + platformCents;
}

/// A class with space a student can make a missed class up in.
@freezed
abstract class MakeupSlot with _$MakeupSlot {
  const factory MakeupSlot({
    required String classId,
    required String className,
    required DateTime at,
    required String coach,
    required String lesson,
    required int spots,
  }) = _MakeupSlot;
}

enum RequestState { pending, accepted, declined }

@freezed
abstract class EnrolRequest with _$EnrolRequest {
  const factory EnrolRequest({
    required String id,
    required String academyId,
    required String student,
    int? age,
    @Default('') String parent,
    required String classId,
    required String className,
    @Default('') String note,
    @Default(RequestState.pending) RequestState state,
  }) = _EnrolRequest;
}

/// Something on a coach's Today list.
@freezed
abstract class CoachAlert with _$CoachAlert {
  const factory CoachAlert({
    required String title,
    required String body,
    @Default('navy') String tone,
    String? action,
  }) = _CoachAlert;
}

/// What a coach records at a class: who came, skill updates and a note.
@freezed
abstract class SessionRecord with _$SessionRecord {
  const factory SessionRecord({
    required String classId,
    @Default({}) Set<String> absent,
    @Default({}) Map<String, SkillStatus> focusSkill,
    @Default('') String note,
  }) = _SessionRecord;
}

/// Answers from the five create-academy steps.
@freezed
abstract class AcademyDraft with _$AcademyDraft {
  const factory AcademyDraft({
    @Default('') String name,
    @Default('') String blurb,
    @Default({'Kids'}) Set<String> audience,
    @Default([]) List<String> venues,
    @Default(Sport.badminton) Sport sport,
    @Default(true) bool template,
    @Default(Billing.month) Billing billing,
    @Default(2) int makeups,
    @Default({}) Set<String> documents,
    @Default([]) List<String> coachEmails,
  }) = _AcademyDraft;
}
