/// A parent or student conversation in the academy inbox.
class MessageThread {
  const MessageThread({
    required this.id,
    required this.name,
    required this.last,
    required this.at,
    this.unread = 0,
    this.parent = true,
  });

  final String id;

  /// "Aaron Ng (Ethan)".
  final String name;
  final String last;
  final DateTime at;
  final int unread;

  /// A parent, or an adult student.
  final bool parent;

  String get initials => name
      .split(RegExp(r'[\s(]+'))
      .where((w) => w.isNotEmpty && w[0] != ')')
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}

/// A coach who can cover a class.
class CoverCoach {
  const CoverCoach(this.name, this.initials, this.free, {this.blocked = false});
  final String name;
  final String initials;

  /// "Free 2:00 – 3:30 PM · teaches L1 on Wednesdays".
  final String free;

  /// Can't cover, for example an unverified licence.
  final bool blocked;
}

/// The coach's pay for a month.
class CoachPay {
  const CoachPay({
    required this.month,
    required this.totalCents,
    required this.paidOn,
    required this.classes,
    required this.rateCents,
    required this.covers,
    required this.lines,
    this.past = const [],
  });

  final String month;
  final int totalCents;
  final DateTime paidOn;
  final int classes;
  final int rateCents;
  final int covers;

  /// Class, line, cents.
  final List<(String, String, int)> lines;

  /// Month and cents.
  final List<(String, int)> past;
}

/// A drill in a lesson plan.
class Drill {
  const Drill(this.name, this.minutes, {this.tag = '', this.video = ''});
  final String name;
  final int minutes;
  final String tag;

  /// Video length, "2:10".
  final String video;
}

/// One week of a level's curriculum.
class CurriculumWeek {
  const CurriculumWeek({
    required this.week,
    required this.topic,
    required this.skills,
    this.drills = const [],
    this.version = '',
  });

  final int week;
  final String topic;
  final String skills;
  final List<Drill> drills;

  /// "Edited by Coach Ravi, 2 days ago".
  final String version;
}

/// Where a class is in the curriculum.
class ClassProgress {
  const ClassProgress(
    this.name,
    this.initials,
    this.sub, {
    this.behind = false,
  });
  final String name;
  final String initials;
  final String sub;
  final bool behind;
}

/// One class on a student's attendance record.
class AttendanceLine {
  const AttendanceLine(this.at, this.lesson, this.state);
  final DateTime at;
  final String lesson;

  /// Present, Absent or Make-up.
  final String state;
}
