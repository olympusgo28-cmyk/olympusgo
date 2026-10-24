import '../../auth/data/auth_repository.dart';
import '../../onboarding/domain/sport.dart';
import '../../play/domain/activity.dart' show platformFee;
import '../domain/academy_models.dart';
import '../domain/academy_more.dart';

/// Academies, their classes, students, fees and coaching records.
abstract interface class AcademyRepository {
  Future<List<Academy>> academies();
  Future<Academy> academy(String id);

  // Parents.
  Future<List<Student>> myStudents();
  Future<Student> student(String id);
  Future<List<LessonWeek>> lessons(String studentId);
  Future<List<Invoice>> invoices(String studentId);
  Future<void> payInvoice(String invoiceId, String methodId);
  Future<List<MakeupSlot>> makeupSlots(String studentId);
  Future<void> bookMakeup(String studentId, MakeupSlot slot);
  Future<void> answerNotice(String studentId, {required bool coming});
  Future<void> requestEnrol({
    required String academyId,
    required String classId,
    required String student,
    String note,
  });

  /// Trial classes in the next two weeks with space.
  Future<List<MakeupSlot>> trialSlots(String academyId);
  Future<void> bookTrial(String academyId, MakeupSlot slot, String student);

  // Coaches.
  Future<List<CoachAlert>> alerts(String academyId);
  Future<List<EnrolRequest>> requests(String academyId);
  Future<void> decide(String requestId, RequestState state);
  Future<List<Student>> roster(String classId);
  Future<void> saveSession(SessionRecord record);
  Future<String> createAcademy(AcademyDraft draft);

  // Running the academy.
  Future<List<MessageThread>> messages(String academyId);
  Future<void> closeAcademy(String id);
  Future<List<CoverCoach>> coverCoaches(String classId);

  /// Moves, covers or cancels one class and tells the parents. Returns how
  /// many parents were told.
  Future<int> changeClass(
    String classId, {
    required String mode,
    required String notice,
    String? coach,
    DateTime? at,
  });
  Future<CoachPay> coachPay();
  Future<List<ClassProgress>> curriculumClasses(String academyId, int level);
  Future<List<CurriculumWeek>> curriculum(String academyId, int level);
  Future<void> saveLessonPlan(
    String academyId,
    int level,
    int week, {
    required List<Drill> drills,
    String note,
  });
  Future<List<Drill>> drillVideos();

  /// Parents invited to a class who haven't answered: name and when.
  Future<List<(String, String)>> pendingInvites(String classId);
  Future<void> inviteParent(String classId, String mobile);
  Future<void> sendParentNote(
    String studentId, {
    required Map<String, SkillStatus> skills,
    required String note,
  });
  Future<void> setFilmingConsent(
    String studentId, {
    required bool own,
    required bool train,
  });
  Future<List<AttendanceLine>> attendance(String studentId);
}

const _soon = AuthFailure(
  'Academies open with the next release. Classes you join will show here.',
);

/// No academy tables yet: real players see empty lists, never sample
/// academies, and actions explain why.
class SupabaseAcademyRepository implements AcademyRepository {
  @override
  Future<List<Academy>> academies() async => const [];
  @override
  Future<Academy> academy(String id) => throw _soon;
  @override
  Future<List<Student>> myStudents() async => const [];
  @override
  Future<Student> student(String id) => throw _soon;
  @override
  Future<List<LessonWeek>> lessons(String studentId) async => const [];
  @override
  Future<List<Invoice>> invoices(String studentId) async => const [];
  @override
  Future<void> payInvoice(String invoiceId, String methodId) => throw _soon;
  @override
  Future<List<MakeupSlot>> makeupSlots(String studentId) async => const [];
  @override
  Future<void> bookMakeup(String studentId, MakeupSlot slot) => throw _soon;
  @override
  Future<void> answerNotice(String studentId, {required bool coming}) =>
      throw _soon;
  @override
  Future<void> requestEnrol({
    required String academyId,
    required String classId,
    required String student,
    String note = '',
  }) => throw _soon;
  @override
  Future<List<MakeupSlot>> trialSlots(String academyId) async => const [];
  @override
  Future<void> bookTrial(String academyId, MakeupSlot slot, String student) =>
      throw _soon;
  @override
  Future<List<CoachAlert>> alerts(String academyId) async => const [];
  @override
  Future<List<EnrolRequest>> requests(String academyId) async => const [];
  @override
  Future<void> decide(String requestId, RequestState state) => throw _soon;
  @override
  Future<List<Student>> roster(String classId) async => const [];
  @override
  Future<void> saveSession(SessionRecord record) => throw _soon;
  @override
  Future<String> createAcademy(AcademyDraft draft) => throw _soon;
  @override
  Future<List<MessageThread>> messages(String academyId) async => const [];
  @override
  Future<void> closeAcademy(String id) => throw _soon;
  @override
  Future<List<CoverCoach>> coverCoaches(String classId) async => const [];
  @override
  Future<int> changeClass(
    String classId, {
    required String mode,
    required String notice,
    String? coach,
    DateTime? at,
  }) => throw _soon;
  @override
  Future<CoachPay> coachPay() => throw _soon;
  @override
  Future<List<ClassProgress>> curriculumClasses(
    String academyId,
    int level,
  ) async => const [];
  @override
  Future<List<CurriculumWeek>> curriculum(String academyId, int level) async =>
      const [];
  @override
  Future<void> saveLessonPlan(
    String academyId,
    int level,
    int week, {
    required List<Drill> drills,
    String note = '',
  }) => throw _soon;
  @override
  Future<List<Drill>> drillVideos() async => const [];
  @override
  Future<List<(String, String)>> pendingInvites(String classId) async =>
      const [];
  @override
  Future<void> inviteParent(String classId, String mobile) => throw _soon;
  @override
  Future<void> sendParentNote(
    String studentId, {
    required Map<String, SkillStatus> skills,
    required String note,
  }) => throw _soon;
  @override
  Future<void> setFilmingConsent(
    String studentId, {
    required bool own,
    required bool train,
  }) => throw _soon;
  @override
  Future<List<AttendanceLine>> attendance(String studentId) async => const [];
}

/// The trial fee: one paid trial per child.
const trialCents = 1500;

class DemoAcademyRepository implements AcademyRepository {
  DemoAcademyRepository() {
    _seed();
  }

  final _academies = <String, Academy>{};
  final _students = <String, Student>{};
  final _invoices = <String, List<Invoice>>{};
  final _requests = <EnrolRequest>[];
  int _n = 0;

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 200));

  static const _plan = [
    'Grip, ready position and split-step',
    'Clears from the back',
    'Backhand clear',
    'Smash basics and high serve',
    'Net play',
    'Net shots under pressure',
    'Doubles basics',
    'Doubles positions',
    'Scoring and calls',
    'Skills check',
  ];

  static const _skills = [
    ('fw1', 'Footwork', 'Split-step'),
    ('fw2', 'Footwork', 'Recover to base'),
    ('fw3', 'Footwork', 'Lunge to the net'),
    ('st1', 'Strokes', 'Forehand clear'),
    ('st2', 'Strokes', 'Backhand clear'),
    ('st3', 'Strokes', 'Smash'),
    ('st4', 'Strokes', 'Net kill'),
    ('sv1', 'Serve', 'Low serve'),
    ('sv2', 'Serve', 'High serve'),
    ('gs1', 'Game sense', 'Rally of 10'),
    ('gs2', 'Game sense', 'Doubles positions'),
    ('gs3', 'Game sense', 'Scoring and calls'),
  ];

  List<Skill> _skillSet(int got, int practising) => [
    for (var i = 0; i < _skills.length; i++)
      Skill(
        id: _skills[i].$1,
        group: _skills[i].$2,
        name: _skills[i].$3,
        status: i < got
            ? SkillStatus.gotIt
            : i < got + practising
            ? SkillStatus.practising
            : SkillStatus.notYet,
        week: i < got + practising ? 'Week ${1 + i % 4}' : '',
      ),
  ];

  void _seed() {
    final now = DateTime.now();
    const sa = 'a-smash';
    _academies[sa] = const Academy(
      id: sa,
      name: 'Smash Academy',
      sport: Sport.badminton,
      area: 'Tampines',
      blurb:
          'Structured badminton classes for kids, teens and adults, from '
          'first rallies to match play.',
      audience: 'ages 6 to 16',
      rating: 4.8,
      ratingCount: 126,
      students: 86,
      verified: true,
      myRole: AcademyRole.coach,
      coaches: [
        AcademyCoach(name: 'Coach Ravi', initials: 'RA', role: 'Head coach'),
        AcademyCoach(name: 'Coach Mei', initials: 'ME', role: 'Juniors'),
        AcademyCoach(name: 'Coach Daniel', initials: 'DA', role: 'Teens squad'),
      ],
      classes: [
        AcademyClass(
          id: 'c-l1',
          academyId: sa,
          name: 'Juniors Level 1',
          level: 1,
          levelName: 'First Rallies',
          weekdays: [DateTime.saturday],
          hour: 9,
          ages: 'ages 6 to 9',
          feeCents: 16000,
          capacity: 15,
          enrolled: 12,
          coach: 'Coach Mei',
          court: 'Court 3',
          week: 3,
          termWeeks: 8,
          lesson: 'Grip and ready position',
          focusSkill: 'fw1',
        ),
        AcademyClass(
          id: 'c-l2',
          academyId: sa,
          name: 'Juniors Level 2',
          level: 2,
          levelName: 'Rally Builders',
          weekdays: [DateTime.saturday],
          hour: 10,
          minute: 30,
          ages: 'ages 8 to 12',
          feeCents: 18000,
          capacity: 12,
          enrolled: 11,
          coach: 'Coach Ravi',
          court: 'Court 3',
          week: 5,
          lesson: 'Net play',
          focusSkill: 'st4',
        ),
        AcademyClass(
          id: 'c-teens',
          academyId: sa,
          name: 'Teens Squad',
          level: 3,
          levelName: 'Match Play',
          weekdays: [DateTime.tuesday, DateTime.thursday],
          hour: 17,
          ages: 'ages 13 to 16',
          feeCents: 24000,
          capacity: 14,
          enrolled: 14,
          coach: 'Coach Daniel',
          court: 'Court 1',
          week: 5,
          lesson: 'Doubles rotation',
        ),
        AcademyClass(
          id: 'c-adult',
          academyId: sa,
          name: 'Adult Beginners',
          level: 1,
          levelName: 'First Rallies',
          weekdays: [DateTime.wednesday],
          hour: 20,
          ages: 'adults',
          feeCents: 14000,
          capacity: 15,
          enrolled: 9,
          coach: 'Coach Ravi',
          court: 'Court 2',
          week: 5,
          lesson: 'Clears from the back',
        ),
      ],
      pendingRequests: 5,
    );
    _academies['a-feather'] = const Academy(
      id: 'a-feather',
      name: 'Feather First',
      sport: Sport.badminton,
      area: 'Bedok',
      blurb: 'Small-group coaching for adults who want to play doubles well.',
      audience: 'adults',
      rating: 4.6,
      ratingCount: 31,
      students: 40,
      verified: true,
      billing: Billing.perClass,
      color: 0xFF2F3A5F,
      ink: 0xFFFFFFFF,
      coverColor: 0xFF3E6B8A,
      coaches: [
        AcademyCoach(name: 'Coach Lin', initials: 'LI', role: 'Head coach'),
        AcademyCoach(name: 'Coach Arif', initials: 'AR', role: 'Coach'),
      ],
      classes: [
        AcademyClass(
          id: 'c-ff1',
          academyId: 'a-feather',
          name: 'Doubles Clinic',
          level: 2,
          weekdays: [DateTime.monday, DateTime.thursday],
          hour: 19,
          ages: 'adults',
          feeCents: 4500,
          capacity: 8,
          enrolled: 6,
          coach: 'Coach Lin',
        ),
      ],
    );
    _academies['a-net'] = const Academy(
      id: 'a-net',
      name: 'Net Skills',
      sport: Sport.badminton,
      area: 'Pasir Ris',
      blurb: 'Weekend classes for juniors, focused on footwork and net play.',
      audience: 'ages 8 to 14',
      rating: 4.7,
      ratingCount: 18,
      students: 52,
      verified: true,
      billing: Billing.term,
      color: 0xFF0E6B4E,
      ink: 0xFFFFFFFF,
      coverColor: 0xFFB9832A,
      coaches: [
        AcademyCoach(name: 'Coach Wen', initials: 'WE', role: 'Head coach'),
        AcademyCoach(name: 'Coach Sam', initials: 'SA', role: 'Coach'),
        AcademyCoach(name: 'Coach Ida', initials: 'ID', role: 'Coach'),
      ],
      classes: [
        AcademyClass(
          id: 'c-ns1',
          academyId: 'a-net',
          name: 'Juniors Footwork',
          level: 1,
          weekdays: [DateTime.sunday],
          hour: 10,
          ages: 'ages 8 to 11',
          feeCents: 14000,
          capacity: 14,
          enrolled: 10,
          coach: 'Coach Wen',
        ),
      ],
    );

    final l2 = _academies[sa]!.classes[1];
    final lastSat = l2.nextAt().subtract(const Duration(days: 7));
    _students['s-ethan'] = Student(
      id: 's-ethan',
      name: 'Ethan Ng',
      age: 10,
      academyId: sa,
      classId: 'c-l2',
      parent: 'Aaron Ng',
      skills: _skillSet(5, 2),
      attendancePct: 92,
      attended: 11,
      held: 12,
      makeupCredits: 1,
      creditUseBy: now.add(const Duration(days: 4)),
      notice:
          "Saturday's class is now 10:30 AM – 12:00 PM, Court 3. Was 9:00 AM.",
      notes: [
        CoachNote(
          coach: 'Coach Ravi',
          at: lastSat,
          lesson: 'Week 4 · Smash basics',
          got: 'High serve',
          practising: 'Smash',
          text:
              "Ethan's high serve is consistent now. His smash needs a fuller "
              'swing; 10 shadow swings a day at home will help.',
        ),
      ],
    );
    // The rest of Juniors Level 2, for the coach's roster.
    const others = [
      ('Aisha Rahman', 11, 7, 100, 'Make-up from Wednesday'),
      ('Jayden Lim', 11, 6, 92, ''),
      ('Maya Koh', 10, 4, 83, 'Away today, has a make-up credit'),
      ('Zoe Wong', 9, 8, 100, ''),
      ('Lucas Chua', 10, 3, 75, 'No filming consent'),
      ('Ben Ong', 9, 5, 67, 'Missed 2 in a row'),
      ('Sophie Chan', 11, 9, 92, 'Ready for Level 3'),
    ];
    for (final (name, age, got, pct, flag) in others) {
      final id = 's-${name.split(' ').first.toLowerCase()}';
      _students[id] = Student(
        id: id,
        name: name,
        age: age,
        academyId: sa,
        classId: 'c-l2',
        skills: _skillSet(got, 2),
        attendancePct: pct,
        flag: flag,
        filmingConsent: flag != 'No filming consent',
      );
    }

    final m = now.month;
    DateTime first(int month) => DateTime(now.year, month, 1);
    _invoices['s-ethan'] = [
      Invoice(
        id: 'inv-next',
        title: '${_monthName(m + 1)} fee',
        feeCents: 18000,
        platformCents: 1800,
        due: first(m + 1),
      ),
      Invoice(
        id: 'inv-now',
        title: '${_monthName(m)} fee',
        feeCents: 18000,
        platformCents: 1800,
        due: first(m),
        paidOn: first(m),
      ),
      Invoice(
        id: 'inv-prev',
        title: '${_monthName(m - 1)} fee',
        feeCents: 18000,
        platformCents: 1800,
        due: first(m - 1),
        paidOn: first(m - 1),
      ),
    ];

    const reqs = [
      ('Lucas Tay', 8, 'Mrs Tay', 'c-l1', 'He has played a little at school.'),
      ('Aisha Khan', 11, 'Mr Khan', 'c-l2', 'Moving from Feather First.'),
      ('Zhi Hao Lim', 14, 'Mrs Lim', 'c-teens', 'Happy to wait for a spot.'),
      ('Nadia Wong', null, '', 'c-adult', 'Complete beginner, keen to learn.'),
      ('Ben Ong', 7, 'Mr Ong', 'c-l1', ''),
    ];
    for (final (name, age, parent, cls, note) in reqs) {
      _requests.add(
        EnrolRequest(
          id: 'r-${_requests.length}',
          academyId: sa,
          student: name,
          age: age,
          parent: parent,
          classId: cls,
          className: _class(cls).name,
          note: note,
        ),
      );
    }
  }

  static String _monthName(int m) => const [
    'December',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
    'January',
  ][m.clamp(0, 13)];

  AcademyClass _class(String id) => _academies.values
      .expand((a) => a.classes)
      .firstWhere(
        (c) => c.id == id,
        orElse: () => throw const AuthFailure('This class no longer runs.'),
      );

  Academy _find(String id) =>
      _academies[id] ??
      (throw const AuthFailure('This academy is no longer listed.'));

  Student _student(String id) =>
      _students[id] ?? (throw const AuthFailure('This student has left.'));

  @override
  Future<List<Academy>> academies() async {
    await _tick();
    return [
      for (final a in _academies.values)
        a.copyWith(
          pendingRequests: _requests
              .where(
                (r) => r.academyId == a.id && r.state == RequestState.pending,
              )
              .length,
        ),
    ];
  }

  @override
  Future<Academy> academy(String id) async {
    await _tick();
    final a = _find(id);
    final kids = _students.values.where(
      (s) => s.academyId == id && s.parent == 'Aaron Ng',
    );
    return a.copyWith(
      pendingRequests: _requests
          .where((r) => r.academyId == id && r.state == RequestState.pending)
          .length,
      myRole: a.myRole == AcademyRole.none && kids.isNotEmpty
          ? AcademyRole.parent
          : a.myRole,
    );
  }

  @override
  Future<List<Student>> myStudents() async {
    await _tick();
    return _students.values.where((s) => s.parent == 'Aaron Ng').toList();
  }

  @override
  Future<Student> student(String id) async {
    await _tick();
    return _student(id);
  }

  @override
  Future<List<LessonWeek>> lessons(String studentId) async {
    await _tick();
    final c = _class(_student(studentId).classId);
    return [
      for (var i = 0; i < c.termWeeks; i++)
        LessonWeek(
          week: i + 1,
          title: i < _plan.length ? _plan[i] : 'Week ${i + 1}',
          attended: i + 1 < c.week,
        ),
    ];
  }

  @override
  Future<List<Invoice>> invoices(String studentId) async {
    await _tick();
    return [...?_invoices[studentId]];
  }

  @override
  Future<void> payInvoice(String invoiceId, String methodId) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    for (final list in _invoices.values) {
      final i = list.indexWhere((x) => x.id == invoiceId);
      if (i >= 0) list[i] = list[i].copyWith(paidOn: DateTime.now());
    }
  }

  @override
  Future<List<MakeupSlot>> makeupSlots(String studentId) async {
    await _tick();
    final s = _student(studentId);
    final mine = _class(s.classId);
    final now = DateTime.now();
    // Same-level classes in the next two weeks, at least 24 hours away.
    final slots = <MakeupSlot>[];
    for (final c in _find(
      s.academyId,
    ).classes.where((c) => c.level == mine.level && !c.full)) {
      var at = c.nextAt(now.add(const Duration(hours: 24)));
      while (at.isBefore(now.add(const Duration(days: 14)))) {
        slots.add(
          MakeupSlot(
            classId: c.id,
            className: c.name,
            at: at,
            coach: c.coach,
            lesson: c.lesson,
            spots: c.spotsLeft,
          ),
        );
        at = c.nextAt(at);
      }
    }
    // A Sunday Level 2 class, as on the canvas, so there is a choice.
    if (mine.level == 2) {
      final sun = mine.nextAt(now.add(const Duration(hours: 24)));
      slots.add(
        MakeupSlot(
          classId: 'c-l2-sun',
          className: 'Juniors Level 2',
          at: DateTime(sun.year, sun.month, sun.day + 1, 10),
          coach: 'Coach Mei',
          lesson: mine.lesson,
          spots: 2,
        ),
      );
    }
    return slots..sort((a, b) => a.at.compareTo(b.at));
  }

  @override
  Future<void> bookMakeup(String studentId, MakeupSlot slot) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final s = _student(studentId);
    if (s.makeupCredits < 1) {
      throw const AuthFailure('No make-up credits left.');
    }
    _students[studentId] = s.copyWith(makeupCredits: s.makeupCredits - 1);
  }

  @override
  Future<void> answerNotice(String studentId, {required bool coming}) async {
    await _tick();
    final s = _student(studentId);
    _students[studentId] = s.copyWith(
      noticeComing: coming,
      // Missing a moved class earns a make-up credit.
      makeupCredits: s.makeupCredits + (coming ? 0 : 1),
      creditUseBy:
          s.creditUseBy ?? DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Future<void> requestEnrol({
    required String academyId,
    required String classId,
    required String student,
    String note = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _requests.add(
      EnrolRequest(
        id: 'r-${++_n}-mine',
        academyId: academyId,
        student: student,
        parent: 'Aaron Ng',
        classId: classId,
        className: _class(classId).name,
        note: note,
      ),
    );
  }

  @override
  Future<List<MakeupSlot>> trialSlots(String academyId) async {
    await _tick();
    final now = DateTime.now();
    return [
      for (final c in _find(academyId).classes.where((c) => !c.full))
        MakeupSlot(
          classId: c.id,
          className: c.name,
          at: c.nextAt(now.add(const Duration(hours: 24))),
          coach: c.coach,
          lesson: c.lesson,
          spots: c.spotsLeft,
        ),
    ]..sort((a, b) => a.at.compareTo(b.at));
  }

  @override
  Future<void> bookTrial(String academyId, MakeupSlot slot, String student) =>
      Future.delayed(const Duration(milliseconds: 500));

  @override
  Future<List<CoachAlert>> alerts(String academyId) async {
    await _tick();
    final pending = _requests
        .where(
          (r) => r.academyId == academyId && r.state == RequestState.pending,
        )
        .length;
    if (academyId != 'a-smash') {
      return [
        if (pending > 0)
          CoachAlert(
            title:
                '$pending enrolment ${pending == 1 ? 'request' : 'requests'}',
            body: 'Reply within 2 working days.',
            action: 'Open',
          ),
      ];
    }
    return [
      const CoachAlert(
        title: 'Coach Mei is off sick',
        body: 'Juniors L1 at 9:00 AM needs a cover coach or a new time.',
        tone: 'red',
        action: 'Fix',
      ),
      const CoachAlert(
        title: "3 parents haven't seen Saturday's change",
        body: 'Juniors L2 moved to 10:30 AM. Sent yesterday at 6:12 PM.',
        tone: 'yellow',
        action: 'Remind',
      ),
      const CoachAlert(
        title: '2 make-up bookings this week',
        body: 'Maya Koh and Ben Ong join Juniors L1 on Saturday.',
      ),
    ];
  }

  @override
  Future<List<EnrolRequest>> requests(String academyId) async {
    await _tick();
    return _requests.where((r) => r.academyId == academyId).toList();
  }

  @override
  Future<void> decide(String requestId, RequestState state) async {
    await _tick();
    final i = _requests.indexWhere((r) => r.id == requestId);
    _requests[i] = _requests[i].copyWith(state: state);
  }

  @override
  Future<List<Student>> roster(String classId) async {
    await _tick();
    return _students.values.where((s) => s.classId == classId).toList();
  }

  @override
  Future<void> saveSession(SessionRecord r) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final c = _class(r.classId);
    final now = DateTime.now();
    for (final s
        in _students.values.where((s) => s.classId == r.classId).toList()) {
      final present = !r.absent.contains(s.id);
      final focus = r.focusSkill[s.id];
      final skills = [
        for (final k in s.skills)
          focus != null && k.id == c.focusSkill
              ? k.copyWith(status: focus, week: 'Week ${c.week}')
              : k,
      ];
      _students[s.id] = s.copyWith(
        attended: s.attended + (present ? 1 : 0),
        held: s.held + 1,
        attendancePct: ((s.attended + (present ? 1 : 0)) * 100 / (s.held + 1))
            .round(),
        skills: skills,
        notes: [
          if (r.note.trim().isNotEmpty)
            CoachNote(
              coach: c.coach,
              at: now,
              lesson: 'Week ${c.week} · ${c.lesson}',
              present: present,
              text: r.note.trim(),
            ),
          ...s.notes,
        ],
      );
    }
  }

  @override
  Future<String> createAcademy(AcademyDraft d) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final id = 'a-new-${++_n}';
    _academies[id] = Academy(
      id: id,
      name: d.name.trim(),
      sport: d.sport,
      area: d.venues.isEmpty ? '' : d.venues.first.split(',').last.trim(),
      blurb: d.blurb.trim(),
      audience: d.audience.join(', ').toLowerCase(),
      billing: d.billing,
      makeupsPerMonth: d.makeups,
      myRole: AcademyRole.headCoach,
      coaches: const [
        AcademyCoach(name: 'You', initials: 'AN', role: 'Head coach'),
      ],
      color: 0xFF2F3A5F,
      ink: 0xFFFFFFFF,
    );
    return id;
  }

  // Running the academy.

  final _plans = <String, List<Drill>>{};
  final _invites = <String, List<(String, String)>>{};

  @override
  Future<List<MessageThread>> messages(String academyId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return [
      MessageThread(
        id: 'm1',
        name: 'Aaron Ng (Ethan)',
        last: 'Can Ethan do the make-up on Sunday instead?',
        at: now.subtract(const Duration(hours: 2)),
        unread: 2,
      ),
      MessageThread(
        id: 'm2',
        name: 'Mr Khan (Aisha)',
        last: 'Thank you coach, she loved it.',
        at: now.subtract(const Duration(days: 1)),
        unread: 1,
      ),
      MessageThread(
        id: 'm3',
        name: 'Mrs Lim (Zhi Hao)',
        last: 'Is there a trial for the squad?',
        at: now.subtract(const Duration(days: 1, hours: 3)),
        unread: 1,
      ),
      MessageThread(
        id: 'm4',
        name: 'Nadia Wong',
        last: 'Which racket should I buy?',
        at: now.subtract(const Duration(days: 3)),
        parent: false,
      ),
      MessageThread(
        id: 'm5',
        name: 'Mr Ong (Ben)',
        last: 'Noted on the new time, thanks.',
        at: now.subtract(const Duration(days: 4)),
      ),
    ];
  }

  @override
  Future<void> closeAcademy(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _academies.remove(id);
  }

  @override
  Future<List<CoverCoach>> coverCoaches(String classId) async => const [
    CoverCoach(
      'Coach Daniel',
      'DA',
      'Free at that time · teaches L1 on Wednesdays',
    ),
    CoverCoach('Coach Ravi', 'RA', 'Free after 12:00 PM · head coach'),
    CoverCoach('Coach Priya', 'PR', 'NROC licence not verified', blocked: true),
  ];

  @override
  Future<int> changeClass(
    String classId, {
    required String mode,
    required String notice,
    String? coach,
    DateTime? at,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final a in _academies.values) {
      for (final c in a.classes) {
        if (c.id == classId) return c.enrolled;
      }
    }
    return 0;
  }

  @override
  Future<CoachPay> coachPay() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    final last = DateTime(now.year, now.month - 1);
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return CoachPay(
      month: months[last.month - 1],
      totalCents: 144000,
      paidOn: DateTime(now.year, now.month, 5),
      classes: 24,
      rateCents: 6000,
      covers: 2,
      lines: const [
        ('Juniors Level 2', '8 classes · Sat 10:30 AM', 48000),
        ('Adult Beginners', '8 classes · Wed 8:00 PM', 48000),
        ('Trial and make-up classes', '6 classes', 36000),
        ('Cover for Coach Mei', '2 classes', 12000),
      ],
      past: [
        (months[(last.month - 2) % 12], 132000),
        (months[(last.month - 3) % 12], 138000),
      ],
    );
  }

  static const _weeks = [
    ('Grip, ready position and split-step', 'Split-step · Low serve'),
    ('Clears from the back', 'Forehand clear · Recover to base'),
    ('Backhand clear', 'Backhand clear'),
    ('Smash basics and high serve', 'Smash · High serve'),
    ('Net play', 'Net kill · Lunge to the net'),
    ('Net shots under pressure', 'Rally of 10'),
    ('Doubles basics', 'Practice week'),
    ('Doubles positions', 'Doubles positions'),
    ('Scoring and calls', 'Scoring and calls'),
    ('Skills check', 'Coaches confirm level-up'),
  ];

  static const _netPlan = [
    Drill('Warm-up: shadow footwork to the net', 10),
    Drill('Feed drill: net kill from a loose lift', 20),
    Drill('Pairs: net kill and recover to base', 25),
    Drill('Half-court games, net kills score double', 30),
  ];

  @override
  Future<List<ClassProgress>> curriculumClasses(
    String academyId,
    int level,
  ) async => const [
    ClassProgress(
      'Sat L2 · Coach Ravi',
      'RA',
      'Week 5 today · 2 of 4 parts done',
    ),
    ClassProgress('Wed L2 · Coach Mei', 'ME', 'Week 5 taught on Wednesday'),
    ClassProgress(
      'Thu L2 · Coach Mei',
      'ME',
      'Week 4 · last Thursday was a public holiday',
      behind: true,
    ),
  ];

  @override
  Future<List<CurriculumWeek>> curriculum(String academyId, int level) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return [
      for (final (i, (topic, skills)) in _weeks.indexed)
        CurriculumWeek(
          week: i + 1,
          topic: topic,
          skills: skills,
          drills: _plans['$level-${i + 1}'] ?? (i == 4 ? _netPlan : const []),
          version: _plans.containsKey('$level-${i + 1}')
              ? 'Edited by you, just now'
              : (i == 4 ? 'Edited by Coach Ravi, 2 days ago' : ''),
        ),
    ];
  }

  @override
  Future<void> saveLessonPlan(
    String academyId,
    int level,
    int week, {
    required List<Drill> drills,
    String note = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _plans['$level-$week'] = drills;
  }

  @override
  Future<List<Drill>> drillVideos() async => const [
    Drill('Shadow footwork to the net', 10, tag: 'Footwork', video: '2:10'),
    Drill('Split step timing', 10, tag: 'Footwork', video: '1:45'),
    Drill('High serve, step by step', 15, tag: 'Serve', video: '3:05'),
    Drill('Low serve for doubles', 15, tag: 'Serve', video: '2:30'),
    Drill('Smash: full swing', 20, tag: 'Smash', video: '2:50'),
    Drill('Jump smash basics', 20, tag: 'Smash', video: '3:40'),
    Drill('Net kill feed', 15, tag: 'Net', video: '1:55'),
    Drill('Tight net shot in pairs', 15, tag: 'Net', video: '2:20'),
  ];

  @override
  Future<List<(String, String)>> pendingInvites(String classId) async =>
      _invites[classId] ??= [
        ('Mrs Tay, for Lucas', 'Sent 2 days ago'),
        ('Mr Ong, for Ben', 'Sent 5 days ago'),
      ];

  @override
  Future<void> inviteParent(String classId, String mobile) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!RegExp(r'^\+?[0-9 ]{8,}$').hasMatch(mobile.trim())) {
      throw const AuthFailure('Enter a mobile number, like 9123 4567.');
    }
    (_invites[classId] ??= []).insert(0, (
      'Parent at ${mobile.trim()}',
      'Sent just now',
    ));
  }

  @override
  Future<void> sendParentNote(
    String studentId, {
    required Map<String, SkillStatus> skills,
    required String note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> setFilmingConsent(
    String studentId, {
    required bool own,
    required bool train,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final s = _students[studentId];
    if (s != null) _students[studentId] = s.copyWith(filmingConsent: own);
  }

  @override
  Future<List<AttendanceLine>> attendance(String studentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    DateTime sat(int weeksAgo) {
      final d = now.subtract(
        Duration(days: (now.weekday - DateTime.saturday) % 7 + 7 * weeksAgo),
      );
      return DateTime(d.year, d.month, d.day, 10, 30);
    }

    return [
      AttendanceLine(sat(0), 'Net kill and tumbling net', 'Present'),
      AttendanceLine(sat(1), 'Backhand clear', 'Present'),
      AttendanceLine(
        sat(1).subtract(const Duration(days: 3)),
        'Make-up class, Level 2',
        'Make-up',
      ),
      AttendanceLine(sat(2), 'Footwork: split step', 'Absent'),
      AttendanceLine(sat(3), 'Serve and return', 'Present'),
      AttendanceLine(sat(4), 'Clears from the back', 'Present'),
      AttendanceLine(sat(5), 'Grip and ready position', 'Present'),
    ];
  }
}

/// The academy platform fee: 10%, minimum S$2 per payment.
int academyFee(int cents) => platformFee(cents);
