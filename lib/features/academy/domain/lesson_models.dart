/// Someone this account may enrol or book for.
class EnrolPlayer {
  const EnrolPlayer({
    required this.id,
    required this.name,
    this.age,
    this.self = false,
  });

  final String id;
  final String name;
  final int? age;

  /// The account holder, rather than a linked child.
  final bool self;
}

enum LessonKind {
  trial('trial', 'Trial class'),
  dropIn('class', 'Single class'),
  oneToOne('one_to_one', 'One-to-one');

  const LessonKind(this.id, this.label);
  final String id;
  final String label;

  static LessonKind of(String id) =>
      values.firstWhere((k) => k.id == id, orElse: () => trial);
}

enum LessonStep {
  pending,
  paid,
  marked,
  lateCancelled,
  reported,
  released,
  cancelled,
  expired,
  refunded;

  static LessonStep of(String s) => switch (s) {
    'late_cancelled' => lateCancelled,
    _ => values.firstWhere((v) => v.name == s, orElse: () => cancelled),
  };

  String get label => switch (this) {
    pending => 'Waiting for payment',
    paid => 'Booked',
    marked => 'Attendance saved',
    lateCancelled => 'Cancelled late',
    reported => 'With our team',
    released => 'Done',
    cancelled => 'Cancelled',
    expired => 'Time ran out',
    refunded => 'Refunded',
  };
}

/// What a lesson costs, from the server.
class LessonQuote {
  const LessonQuote({
    required this.title,
    required this.priceCents,
    required this.feeCents,
    required this.totalCents,
    required this.startsAt,
    required this.refundRule,
    required this.enabled,
  });

  factory LessonQuote.fromJson(Map<String, dynamic> r) => LessonQuote(
    title: r['title'] as String? ?? '',
    priceCents: (r['price_minor'] as num).toInt(),
    feeCents: (r['fee_minor'] as num).toInt(),
    totalCents: (r['total_minor'] as num).toInt(),
    startsAt: DateTime.parse(r['starts_at'] as String).toLocal(),
    refundRule: r['refund_rule'] as String? ?? '',
    enabled: r['enabled'] as bool? ?? false,
  );

  final String title;
  final int priceCents;
  final int feeCents;
  final int totalCents;
  final DateTime startsAt;
  final String refundRule;

  /// Paying in the app is switched on.
  final bool enabled;
}

class LessonBooking {
  const LessonBooking({
    required this.id,
    required this.kind,
    required this.title,
    required this.academyId,
    required this.academy,
    required this.coach,
    required this.student,
    required this.startsAt,
    required this.endsAt,
    required this.step,
    required this.totalCents,
    this.priceCents = 0,
    this.feeCents = 0,
    this.refundedCents = 0,
    this.attendance,
    this.paymentId = '',
    this.paymentMethod,
    this.holdUntil,
    this.serverNow,
    this.freeCancelUntil,
    this.canPay = false,
    this.canTeach = false,
  });

  factory LessonBooking.fromJson(Map<String, dynamic> r) => LessonBooking(
    id: r['id'] as String,
    kind: LessonKind.of(r['kind'] as String? ?? ''),
    title: r['title'] as String? ?? '',
    academyId: r['academy_id'] as String? ?? '',
    academy: r['academy'] as String? ?? '',
    coach: r['coach'] as String? ?? '',
    student: r['student'] as String? ?? '',
    startsAt: DateTime.parse(r['starts_at'] as String).toLocal(),
    endsAt: DateTime.parse(r['ends_at'] as String).toLocal(),
    step: LessonStep.of(r['step'] as String? ?? ''),
    totalCents: (r['amount_minor'] as num?)?.toInt() ?? 0,
    priceCents: (r['price_minor'] as num?)?.toInt() ?? 0,
    feeCents: (r['fee_minor'] as num?)?.toInt() ?? 0,
    refundedCents: (r['refunded_minor'] as num?)?.toInt() ?? 0,
    attendance: r['attendance'] as String?,
    paymentId: r['payment_id'] as String? ?? '',
    paymentMethod: r['method'] as String?,
    holdUntil: DateTime.tryParse(r['hold_until'] as String? ?? ''),
    serverNow: DateTime.tryParse(r['server_now'] as String? ?? ''),
    freeCancelUntil: r['free_cancel_until'] == null
        ? null
        : DateTime.parse(r['free_cancel_until'] as String).toLocal(),
    canPay: r['can_pay'] as bool? ?? false,
    canTeach: r['can_teach'] as bool? ?? false,
  );

  final String id;
  final LessonKind kind;
  final String title;
  final String academyId;
  final String academy;
  final String coach;
  final String student;
  final DateTime startsAt;
  final DateTime endsAt;
  final LessonStep step;
  final int totalCents;
  final int priceCents;
  final int feeCents;
  final int refundedCents;
  final String? attendance;
  final String paymentId;

  /// Set once a payment has started, which fixes how it's paid.
  final String? paymentMethod;
  final DateTime? holdUntil;
  final DateTime? serverNow;

  /// Until then, cancelling gives the price back.
  final DateTime? freeCancelUntil;

  /// This person paid, so they can cancel or report.
  final bool canPay;

  /// This person teaches it, so they can mark attendance or cancel.
  final bool canTeach;

  bool get started => !DateTime.now().isBefore(startsAt);

  /// Money really changed hands.
  bool get charged => switch (step) {
    LessonStep.pending || LessonStep.expired => false,
    LessonStep.cancelled => refundedCents > 0,
    _ => true,
  };
}

/// A one-to-one time a coach has opened.
class LessonSlot {
  const LessonSlot({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.priceCents,
    this.coachId = '',
    this.coach = '',
    this.totalCents = 0,
    this.venue = '',
    this.booked = false,
  });

  factory LessonSlot.fromJson(Map<String, dynamic> r) => LessonSlot(
    id: r['id'] as String,
    startsAt: DateTime.parse(r['starts_at'] as String).toLocal(),
    endsAt: DateTime.parse(r['ends_at'] as String).toLocal(),
    priceCents: (r['price_minor'] as num).toInt(),
    coachId: r['coach_id'] as String? ?? '',
    coach: r['coach'] as String? ?? '',
    totalCents: (r['total_minor'] as num?)?.toInt() ?? 0,
    venue: r['venue'] as String? ?? '',
    booked: r['booked'] as bool? ?? false,
  );

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final int priceCents;
  final String coachId;
  final String coach;
  final int totalCents;
  final String venue;
  final bool booked;
}

/// A coach's public page.
class CoachProfile {
  const CoachProfile({
    required this.id,
    required this.name,
    this.headline = '',
    this.bio = '',
    this.yearsCoaching,
    this.academies = const [],
  });

  final String id;
  final String name;
  final String headline;
  final String bio;
  final int? yearsCoaching;

  /// (id, name, role).
  final List<(String, String, String)> academies;
}

/// A coach's own licence and page details.
class CoachLicence {
  const CoachLicence({
    this.status = 'none',
    this.number,
    this.expiresOn,
    this.rejectedReason,
    this.current = false,
    this.headline = '',
    this.bio = '',
    this.yearsCoaching,
  });

  final String status;
  final String? number;
  final DateTime? expiresOn;
  final String? rejectedReason;
  final bool current;
  final String headline;
  final String bio;
  final int? yearsCoaching;
}

/// Where an academy stands with review.
class AcademyChecklist {
  const AcademyChecklist({
    required this.verification,
    this.uen,
    this.rejectedReason,
    this.payoutReady = false,
    this.isOwner = false,
    this.coaches = const [],
  });

  final String verification;
  final String? uen;
  final String? rejectedReason;
  final bool payoutReady;
  final bool isOwner;
  final List<ChecklistCoach> coaches;
}

class ChecklistCoach {
  const ChecklistCoach({
    required this.name,
    required this.head,
    required this.accepted,
    required this.licence,
  });

  final String name;
  final bool head;
  final bool accepted;

  /// none, submitted, verified or rejected.
  final String licence;
}

class AssessmentTemplate {
  const AssessmentTemplate({
    required this.id,
    required this.name,
    required this.scaleMax,
    required this.criteria,
    this.used = false,
  });

  final String id;
  final String name;
  final int scaleMax;

  /// (id, label).
  final List<(String, String)> criteria;
  final bool used;
}

class AssessmentScore {
  const AssessmentScore({
    required this.criterionId,
    required this.label,
    required this.score,
    required this.max,
  });

  final String criterionId;
  final String label;
  final int score;
  final int max;
}

class Assessment {
  const Assessment({
    required this.id,
    required this.academy,
    required this.templateId,
    required this.template,
    required this.coach,
    required this.on,
    required this.scores,
    this.level,
    this.note = '',
    this.edited = false,
    this.mine = false,
  });

  final String id;
  final String academy;
  final String templateId;
  final String template;
  final String coach;
  final DateTime on;
  final List<AssessmentScore> scores;
  final int? level;
  final String note;
  final bool edited;

  /// This coach wrote it, so they can correct it.
  final bool mine;
}

/// One line on an improvement chart: a thing assessed, oldest score first.
class ScoreLine {
  const ScoreLine(this.label, this.max, this.points);

  final String label;
  final int max;
  final List<(DateTime, int)> points;
}

/// Groups one template's assessments into a line per thing assessed.
List<ScoreLine> scoreLines(List<Assessment> oldestFirst) {
  final lines = <String, ScoreLine>{};
  for (final a in oldestFirst) {
    for (final s in a.scores) {
      final line = lines[s.criterionId] ??= ScoreLine(s.label, s.max, []);
      line.points.add((a.on, s.score));
    }
  }
  return lines.values.toList();
}
