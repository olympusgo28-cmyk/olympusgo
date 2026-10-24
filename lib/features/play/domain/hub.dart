import '../../clubs/domain/club_sport.dart';
import 'activity.dart';

/// The Play hub's tabs.
enum HubTab {
  all('All', null),
  meet('Meet', ActivityKind.meet),
  tournament('Tournament', ActivityKind.tournament),
  event('Event', ActivityKind.event);

  const HubTab(this.label, this.kind);
  final String label;
  final ActivityKind? kind;

  static HubTab of(ActivityKind? kind) =>
      values.firstWhere((t) => t.kind == kind);

  static HubTab fromId(String? id) =>
      values.where((t) => t.name == id).firstOrNull ?? all;

  /// Meets and tournaments narrow each sport by skill level.
  bool get hasLevels => this == meet || this == tournament;

  /// Only Meets narrow each sport by game type.
  bool get hasGameType => this == meet;

  /// Filters for this tab. The first three show in the search bar. Distance,
  /// gender, age group and audience arrive once activities carry that data.
  List<HubFilterGroup> get groups => switch (this) {
    all => const [
      HubFilterGroup('when', 'When', [
        'Upcoming',
        'Today',
        'Tomorrow',
        'Weekend',
      ]),
      HubFilterGroup.sport,
      HubFilterGroup('fee', 'Price', ['Any', 'Free', 'Paid']),
    ],
    meet => const [
      HubFilterGroup('when', 'Schedule', [
        'Upcoming',
        'Today',
        'Tomorrow',
        'Weekend',
      ]),
      HubFilterGroup('style', 'Style', ['All', 'Casual', 'Ranked']),
      HubFilterGroup('fee', 'Fee', ['Any', 'Free', 'Paid']),
      HubFilterGroup.sport,
    ],
    tournament => const [
      HubFilterGroup('when', 'Dates', ['Upcoming', 'This month', 'Next month']),
      HubFilterGroup('tier', 'Tier', ['All', 'Club', 'Regional', 'National']),
      HubFilterGroup('reg', 'Entries', [
        'Any',
        'Open now',
        'Closing this week',
      ]),
      HubFilterGroup.sport,
    ],
    event => const [
      HubFilterGroup('when', 'Dates', [
        'Upcoming',
        'Today',
        'Weekend',
        'This month',
      ]),
      HubFilterGroup('format', 'Format', [
        'All',
        'Offline',
        'Online',
        'Live now',
      ]),
      HubFilterGroup('ticket', 'Ticket', ['All', 'Free', 'Paid']),
      HubFilterGroup.sport,
    ],
  };
}

/// One filter: a title and single-choice options, the first meaning "any".
class HubFilterGroup {
  const HubFilterGroup(this.key, this.title, this.options);

  /// The sport filter is the picked sports, not an option list.
  static const sport = HubFilterGroup('sport', 'Sport', []);

  final String key;
  final String title;
  final List<String> options;

  bool get isSport => key == 'sport';
}

/// "LI–HI", "MI", or "All levels" for a sport's level range.
String bandRange(PlaySportPref p) {
  if (p.levelMin <= 1 && p.levelMax >= 8) return 'All levels';
  final lo = SkillBand.forLevel(p.levelMin);
  final hi = SkillBand.forLevel(p.levelMax);
  return lo == hi ? lo.code : '${lo.code}–${hi.code}';
}

/// What a picked sport's pill says on [tab]: "Doubles · LI–HI".
String sportPillText(PlaySportPref p, HubTab tab) => [
  if (tab.hasGameType && p.gameType != null) p.gameType!.label,
  if (tab.hasLevels) bandRange(p),
].join(' · ');

/// Whether [a] passes [tab]'s filters [f] and the picked sports.
bool hubMatches(
  Activity a,
  HubTab tab,
  Map<String, String> f,
  List<PlaySportPref> picked, {
  DateTime? now,
}) {
  if (picked.isNotEmpty) {
    final pref = picked.where((p) => a.sports.contains(p.sport)).firstOrNull;
    if (pref == null) return false;
    if (tab.hasLevels && a.levelMin != null && a.levelMax != null) {
      if (a.levelMax! < pref.levelMin || a.levelMin! > pref.levelMax) {
        return false;
      }
    }
    if (tab.hasGameType &&
        pref.gameType != null &&
        a.gameType != null &&
        a.gameType != pref.gameType) {
      return false;
    }
  }
  final t = now ?? DateTime.now();
  final today = DateTime(t.year, t.month, t.day);
  final day = DateTime(a.startsAt.year, a.startsAt.month, a.startsAt.day);
  final days = day.difference(today).inDays;
  switch (f['when']) {
    case 'Today' when days != 0:
    case 'Tomorrow' when days != 1:
    case 'Weekend' when !(days < 7 && a.startsAt.weekday >= DateTime.saturday):
    case 'This month'
        when !(a.startsAt.year == t.year && a.startsAt.month == t.month):
    case 'Next month'
        when !(a.startsAt.year * 12 + a.startsAt.month ==
            t.year * 12 + t.month + 1):
      return false;
  }
  switch (f['fee'] ?? f['ticket']) {
    case 'Free' when a.feeCents > 0:
    case 'Paid' when a.feeCents == 0:
      return false;
  }
  switch (f['style']) {
    case 'Casual' when a.ranked:
    case 'Ranked' when !a.ranked:
      return false;
  }
  switch (f['tier']) {
    case 'Club' when a.clubId == null && a.tier != 'Club':
    case 'Regional' when a.tier != 'Regional':
    case 'National' when a.tier != 'National':
      return false;
  }
  final closes = a.registrationClosesAt;
  switch (f['reg']) {
    case 'Open now' when closes != null && closes.isBefore(t):
    case 'Closing this week'
        when closes == null ||
            closes.isBefore(t) ||
            closes.difference(t).inDays >= 7:
      return false;
  }
  switch (f['format']) {
    case 'Offline' when a.online:
    case 'Online' when !a.online:
    case 'Live now' when !a.live:
      return false;
  }
  return true;
}
