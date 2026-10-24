import 'dart:async';

import '../../../core/demo/demo_world.dart';
import '../../../core/widgets/og_kit.dart';
import '../../auth/data/auth_repository.dart';
import '../../play/data/play_repository.dart';
import '../../play/domain/activity.dart';
import '../../social/domain/social_models.dart';
import '../domain/club_models.dart';
import '../domain/club_sport.dart';
import 'club_repository.dart';

/// Clubs and teams from the design, kept in memory so every club screen
/// works without a backend. Aaron is an Admin of Tampines Smashers and owns
/// Sunday Warriors, so both the admin and owner screens can be reached.
class DemoClubRepository implements ClubRepository {
  DemoClubRepository(this._play) {
    _seed();
  }

  final DemoPlayRepository _play;
  final _w = DemoWorld.instance;
  static const _me = DemoWorld.me;

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 200));

  final _people = <String, (PlayerSummary, double)>{};
  final _clubs = <String, Club>{};
  final _notes = <String, String>{};
  final _lists = <ClubTab, List<String>>{};
  final _members = <String, Map<String, ClubMember>>{};
  final _roles = <String, List<ClubRole>>{};
  final _requests = <String, List<JoinRequest>>{};
  final _bans = <String, List<ClubBan>>{};
  final _audit = <String, List<AuditEntry>>{};
  final _news = <String, List<Announcement>>{};
  final _chat = <ChatScope, List<GroupMessage>>{};
  final _streams = <ChatScope, StreamController<List<GroupMessage>>>{};
  final _teams = <String, Team>{};
  final _teamLists = <ClubTab, List<TeamListItem>>{};
  final _teamMembers = <String, List<TeamMember>>{};
  final _teamSessions = <String, List<TeamSession>>{};
  final _results = <String, List<TeamResult>>{};
  final _fixtures = <String, Fixture>{};
  var _counter = 0;

  String _id(String prefix) => '$prefix-${++_counter}';

  PlayerSummary _p(String id) => _people[id]?.$1 ?? _w.players[id] ?? _aaron;

  static const _aaron = DemoWorld.meSummary;

  // ─── Seed ────────────────────────────────────────────────────────────────

  void _person(
    String id,
    String name,
    String username,
    int color,
    double rating, {
    int ink = 0xFFFFFFFF,
  }) {
    final p = PlayerSummary(id: id, username: username, fullName: name);
    _people[id] = (p, rating);
    Faces.overrides[id] = (color, ink);
    _w.register(p, badminton: rating);
  }

  DateTime _daysAgo(int days, int hour, [int minute = 0]) {
    final n = DateTime.now().subtract(Duration(days: days));
    return DateTime(n.year, n.month, n.day, hour, minute);
  }

  /// The next [weekday] at [hour], at least a day away.
  DateTime _next(int weekday, int hour, [int minute = 0]) {
    final now = DateTime.now();
    var days = (weekday - now.weekday) % 7;
    if (days == 0) days = 7;
    final d = now.add(Duration(days: days));
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  void _seed() {
    Faces.overrides[_me] = (0xFFF2C14E, 0xFF3A2C00); // Aaron's gold "AN"
    _person(
      'cp-hannah',
      'Hannah Goh',
      'hannahgoh',
      0xFF101010,
      6.2,
      ink: 0xFFC6FF00,
    );
    _person('cp-siti', 'Siti Kamal', 'sitikamal', 0xFF0E6B4E, 5.7);
    _person(
      'cp-jason',
      'Jason Lim',
      'jasonlim',
      0xFF1C1F23,
      6.1,
      ink: 0xFFF2C14E,
    );
    _person('cp-ravi', 'Ravi Tan', 'ravitan', 0xFFC8553D, 6.4);
    _person('cp-mei', 'Mei Wong', 'meiwong', 0xFF2F3A5F, 4.6);
    _person('cp-hafiz', 'Hafiz Rahman', 'hafiz_r', 0xFFE0A82E, 5.4);
    _person('cp-daniel', 'Daniel Lee', 'daniel_lee', 0xFF0E6B4E, 4.2);
    _person('cp-priya', 'Priya Chandra', 'priyac', 0xFFC8553D, 3.8);
    _person('cp-kelvin', 'Kelvin Ho', 'kelvinho', 0xFF3E6B8A, 5.2);
    _person('cp-weiming', 'Wei Ming Chua', 'weiming', 0xFFE0A82E, 5.3);
    _person('cp-priyar', 'Priya Raman', 'priyaraman', 0xFF3E6B8A, 5.1);
    _person('cp-nurul', 'Nurul Aisyah', 'nurul_a', 0xFF0E6B4E, 4.3);
    _person('cp-marcusg', 'Marcus Goh', 'marcusgoh', 0xFFC8553D, 3.4);
    _person('cp-darren', 'Darren Koh', 'darrenkoh', 0xFF2F3A5F, 5.2);
    _person('cp-ryan', 'Ryan Teo', 'ryanteo', 0xFFC8553D, 4.4);
    _person('cp-jiale', 'Jia Le', 'jiale', 0xFF3E6B8A, 4.0);
    _person('cp-marcusk', 'Marcus Koh', 'marcuskoh', 0xFF7B5EA7, 4.8);
    _person('cp-marcuss', 'Marcus Seah', 'marcusseah', 0xFFB9832A, 4.5);
    _person('cp-nicole', 'Nicole Lau', 'nicolelau', 0xFF3E6B8A, 4.4);
    _person('cp-ben', 'Ben Ong', 'benong', 0xFF2F3A5F, 3.6);
    _person('cp-danielt', 'Daniel Tan', 'danieltan', 0xFF0E6B4E, 4.2);
    _person('cp-sitil', 'Siti Lim', 'sitilim', 0xFFC8553D, 5.0);
    _person('cp-marcusy', 'Marcus Yeo', 'marcusyeo', 0xFF7A4E9C, 4.9);
    _person('cp-meiling', 'Mei Ling', 'meiling', 0xFF7B5EA7, 5.4);
    _person('cp-coach', 'Coach Tan', 'coachtan', 0xFF1C1F23, 6.6);
    _person('cp-mslee', 'Ms Lee', 'mslee', 0xFF2F3A5F, 4.0);
    _person('cp-rahman', 'Mr Rahman', 'mrrahman', 0xFFB9832A, 4.0);

    _seedClubs();
    _seedTampines();
    _seedTeams();
  }

  Club _club(
    String id,
    String name, {
    required int members,
    required String area,
    required List<ClubSportLevel> sports,
    required int logo,
    int ink = 0xFFFFFFFF,
    int? cover,
    ClubVisibility visibility = ClubVisibility.public,
    JoinMode join = JoinMode.request,
    String description = '',
    int createdDaysAgo = 400,
  }) => Club(
    id: id,
    name: name,
    memberCount: members,
    area: area,
    sports: sports,
    logoColor: logo,
    logoInk: ink,
    coverColor: cover ?? logo,
    visibility: visibility,
    joinMode: join,
    description: description,
    createdAt: DateTime.now().subtract(Duration(days: createdDaysAgo)),
    homeVenue: '$area Sports Hall',
    meetsPerWeek: 2,
  );

  void _seedClubs() {
    const bad = ClubSport.badminton;
    _clubs['c-ts'] =
        _club(
          'c-ts',
          'Tampines Smashers',
          members: 128,
          area: 'Tampines',
          sports: const [
            ClubSportLevel(sport: bad, range: LevelRange(3, 5)),
            ClubSportLevel(sport: ClubSport.pickleball),
          ],
          logo: 0xFF1C1F23,
          ink: 0xFFF2C14E,
          cover: 0xFFE8590C,
          description: 'Friendly doubles club. Rotating games, hosts for new members, and a ladder for those who want to compete.',
          createdDaysAgo: 560,
        ).copyWith(
          rating: 4.6,
          ratingCount: 32,
          ratingSpread: const [22, 7, 2, 1, 0],
          homeVenue: 'Our Tampines Hub',
          rules: const [
            'Give up your spot in the app at least 24 hours before the start.',
            'Court fees are split evenly between the players on the night.',
            'Shuttles are provided. Bring your own racquet.',
          ],
          playRules: const {
            'meet': 'Arrive 10 minutes early. Winners stay on for one game only. If you can’t come, give up your spot in the app before the start.',
            'tournament': 'Check in 30 minutes before your first match. Umpire or both sides confirm scores.',
            'event': 'Tickets are scanned at the door. Under-12s come with an adult.',
          },
          standing: ClubStanding.member,
          unreadChat: 5,
          inviteCode: 'TS8KQ2',
          activeInvites: 2,
        );
    _notes['c-ts'] = 'Next Meet tonight, 8:00 PM';
    _clubs['c-pr'] = _club(
      'c-pr',
      'Pasir Ris Rally Crew',
      members: 64,
      area: 'Pasir Ris',
      sports: const [ClubSportLevel(sport: bad)],
      logo: 0xFFB9832A,
      description: 'Saturday morning rallies by the beach. All levels welcome.',
    ).copyWith(standing: ClubStanding.member);
    _notes['c-pr'] = 'Next Meet Sat, 9:00 AM';
    _clubs['c-sw'] = _club(
      'c-sw',
      'Sunday Warriors',
      members: 22,
      area: 'Tampines',
      sports: const [ClubSportLevel(sport: bad, range: LevelRange(4, 6))],
      logo: 0xFF2F3A5F,
      visibility: ClubVisibility.private,
      description: 'Early Sunday doubles for mid and advanced players.',
    ).copyWith(standing: ClubStanding.member, isOwner: true);
    _notes['c-sw'] = 'Next Meet Sun, 8:00 AM';
    _clubs['c-bn'] = _club(
      'c-bn',
      'Bedok Night Owls',
      members: 46,
      area: 'Bedok',
      sports: const [ClubSportLevel(sport: bad, range: LevelRange(4, 6))],
      logo: 0xFF2F3A5F,
      visibility: ClubVisibility.private,
    );
    _clubs['c-ec'] = _club(
      'c-ec',
      'East Coast Smash',
      members: 91,
      area: 'Marine Parade',
      sports: const [ClubSportLevel(sport: bad, range: LevelRange(3, 5))],
      logo: 0xFFC8553D,
      join: JoinMode.anyone,
      description:
          'Big, social club by the sea. Rotating doubles every weeknight.',
    );
    _clubs['c-sk'] = _club(
      'c-sk',
      'Simei Kakis',
      members: 37,
      area: 'Simei',
      sports: const [ClubSportLevel(sport: bad, range: LevelRange(2, 4))],
      logo: 0xFF0E6B4E,
      join: JoinMode.anyone,
      description: 'Neighbourhood badminton for improvers.',
    );
    _clubs['c-cs'] = _club(
      'c-cs',
      'Changi Shuttlers',
      members: 9,
      area: 'Changi',
      sports: const [ClubSportLevel(sport: bad)],
      logo: 0xFF3E6B8A,
      join: JoinMode.anyone,
      createdDaysAgo: 3,
    );
    _notes['c-cs'] = 'Started 3 days ago';
    _clubs['c-tt'] = _club(
      'c-tt',
      'Tampines Tuesdays',
      members: 14,
      area: 'Tampines',
      sports: const [ClubSportLevel(sport: bad, range: LevelRange(0, 3))],
      logo: 0xFF7B5EA7,
      join: JoinMode.anyone,
      createdDaysAgo: 8,
    );
    _notes['c-tt'] = 'Started last week';
    _lists[ClubTab.mine] = ['c-ts', 'c-pr', 'c-sw'];
    _lists[ClubTab.recommended] = ['c-bn', 'c-ec', 'c-sk'];
    _lists[ClubTab.fresh] = ['c-cs', 'c-tt'];

    // Every club gets an owner role, an admin role and someone to run it.
    final runners = {
      'c-pr': ('cp-ravi', 'cp-hafiz'),
      'c-sw': (_me, 'cp-siti'),
      'c-bn': ('cp-jason', 'cp-mei'),
      'c-ec': ('cp-ravi', 'cp-weiming'),
      'c-sk': ('cp-nurul', 'cp-daniel'),
      'c-cs': ('cp-marcusy', 'cp-ben'),
      'c-tt': ('cp-nicole', 'cp-priya'),
    };
    for (final e in runners.entries) {
      final owner = ClubRole(
        id: '${e.key}-owner',
        name: 'Owner',
        color: 0xFF1C1F23,
        level: RoleLevel.admin,
        isOwner: true,
        permissions: ClubPermission.values.toSet(),
      );
      final admin = ClubRole(
        id: '${e.key}-admin',
        name: 'Admin',
        color: 0xFFC8553D,
        level: RoleLevel.admin,
        permissions: ClubPermission.admin,
        position: 1,
      );
      _roles[e.key] = [owner, admin];
      _members[e.key] = {
        e.value.$1: _member(e.value.$1, [owner.id], joinedDays: 300),
        e.value.$2: _member(e.value.$2, [admin.id], joinedDays: 200),
        if (e.key == 'c-pr') _me: _member(_me, const [], joinedDays: 90),
      };
    }
  }

  ClubMember _member(
    String id,
    List<String> roles, {
    int joinedDays = 120,
    int played = 12,
    int noShows = 0,
    int paid = 9600,
  }) => ClubMember(
    player: _p(id),
    rating: id == _me ? 4.0 : _people[id]?.$2,
    roleIds: roles,
    joinedAt: DateTime.now().subtract(Duration(days: joinedDays)),
    meetsPlayed: played,
    noShows: noShows,
    paidCents: paid,
  );

  void _seedTampines() {
    const club = 'c-ts';
    final roles = [
      const ClubRole(
        id: 'ts-owner',
        name: 'Owner',
        color: 0xFF1C1F23,
        level: RoleLevel.admin,
        isOwner: true,
        permissions: {...ClubPermission.values},
      ),
      const ClubRole(
        id: 'ts-admin',
        name: 'Admin',
        color: 0xFFC8553D,
        level: RoleLevel.admin,
        permissions: ClubPermission.admin,
        position: 1,
      ),
      const ClubRole(
        id: 'ts-captain',
        name: 'Court Captain',
        color: 0xFFF2C14E,
        level: RoleLevel.organizer,
        permissions: ClubPermission.organizer,
        position: 2,
      ),
      const ClubRole(
        id: 'ts-founding',
        name: 'Founding Member',
        color: 0xFF3E6B8A,
        level: RoleLevel.label,
        position: 3,
      ),
    ];
    _roles[club] = roles;
    _members[club] = {
      'cp-hannah': _member('cp-hannah', ['ts-owner'], joinedDays: 560),
      'cp-siti': _member('cp-siti', ['ts-admin'], joinedDays: 730),
      'cp-jason': _member('cp-jason', ['ts-admin', 'ts-founding']),
      'cp-ravi': _member('cp-ravi', ['ts-admin', 'ts-founding']),
      _me: _member(_me, ['ts-admin'], joinedDays: 400, played: 23),
      'cp-mei': _member('cp-mei', ['ts-captain', 'ts-founding']),
      'cp-hafiz': _member('cp-hafiz', ['ts-founding'], joinedDays: 420),
      'cp-daniel': _member('cp-daniel', ['ts-founding']),
      'cp-priya': _member('cp-priya', ['ts-founding']),
      'cp-kelvin': _member(
        'cp-kelvin',
        const [],
        joinedDays: 21,
        played: 3,
        noShows: 1,
        paid: 2400,
      ),
      'cp-weiming': _member('cp-weiming', const []),
      'cp-priyar': _member('cp-priyar', const []),
    };
    _requests[club] = [
      JoinRequest(
        id: 'rq-darren',
        player: _p('cp-darren'),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        rating: 5.2,
        sessions: 18,
        mutual: 2,
        message: 'Hi! I play Tue and Thu nights in Tampines, mostly doubles. Would love to join your regular games.',
      ),
      JoinRequest(
        id: 'rq-nurul',
        player: _p('cp-nurul'),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        rating: 4.3,
        sessions: 7,
        mutual: 1,
        message: 'Looking for a regular doubles club near home.',
      ),
      JoinRequest(
        id: 'rq-marcus',
        player: _p('cp-marcusg'),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        rating: 3.4,
        sessions: 2,
        provisional: true,
        belowRange: true,
      ),
    ];
    _bans[club] = [
      ClubBan(
        player: _p('cp-ryan'),
        bannedBy: 'Siti Kamal',
        at: _daysAgo(32, 21),
        reason: 'No-show 3 times without cancelling',
      ),
      ClubBan(
        player: _p('cp-jiale'),
        bannedBy: 'Hannah Goh',
        at: _daysAgo(72, 20),
        reason: 'Abusive messages in club chat',
      ),
      ClubBan(
        player: _p('cp-marcusk'),
        bannedBy: 'Siti Kamal',
        at: _daysAgo(116, 19),
        reason: 'Unpaid court fees',
      ),
    ];
    AuditEntry a(
      int days,
      int h,
      int m,
      AuditCategory c,
      String who,
      String what, [
      String detail = '',
    ]) => AuditEntry(
      id: _id('au'),
      category: c,
      actor: who,
      action: what,
      detail: detail,
      at: _daysAgo(days, h, m),
    );
    _audit[club] = [
      a(
        0,
        9,
        12,
        AuditCategory.members,
        'Jason Lim',
        'approved Kelvin Ho’s join request',
      ),
      a(
        0,
        8,
        40,
        AuditCategory.meets,
        'Siti Kamal',
        'created the Meet Doubles Social',
        'Thu 1 Oct, 8–10 PM',
      ),
      a(
        0,
        8,
        5,
        AuditCategory.roles,
        'Jason Lim',
        'changed permissions for Court Captain',
        'Make Meets public: off → on',
      ),
      a(
        1,
        21,
        31,
        AuditCategory.meets,
        'Ravi Tan',
        'made the Meet Morning Singles public',
      ),
      a(
        1,
        19,
        2,
        AuditCategory.members,
        'Siti Kamal',
        'declined Marcus Goh’s join request',
      ),
      a(
        1,
        18,
        48,
        AuditCategory.roles,
        'Jason Lim',
        'gave Mei Wong the Court Captain role',
      ),
      a(
        3,
        22,
        15,
        AuditCategory.members,
        'Jason Lim',
        'banned a member',
        'Reason: repeated no-shows',
      ),
      a(3, 16, 20, AuditCategory.club, 'Jason Lim', 'updated the club rules'),
      a(
        3,
        11,
        3,
        AuditCategory.members,
        'Siti Kamal',
        'created an invite link',
        'Expires in 7 days · 20 uses',
      ),
    ];
    _news[club] = [
      Announcement(
        id: 'an-1',
        author: 'Hannah Goh',
        authorRole: 'owner',
        title: 'Courts move to Hall B from next week',
        body: 'Tuesday and Friday Meets are in Hall B, courts 7 to 9, from next week. Same time. Parking is on level 2.',
        pinned: true,
        at: _daysAgo(0, 8),
      ),
      Announcement(
        id: 'an-2',
        author: 'Siti Kamal',
        authorRole: 'admin',
        title: 'Club reward: 2 Meets to go',
        body: 'We need 2 more Meets with 6 or more paid players to unlock the S\$20 shuttle voucher.',
        at: _daysAgo(2, 19),
      ),
      Announcement(
        id: 'an-3',
        author: 'Hannah Goh',
        authorRole: 'owner',
        title: 'Welcome 5 new members',
        body: 'Say hi at Friday’s Doubles Social. New members play their first Meet with a host pair.',
        at: _daysAgo(6, 20),
      ),
    ];

    // Club Meets live in the Play repository (clubId 'c-ts'), so they open
    // and join like any other Meet.
    final scope = const ChatScope.club(club);
    GroupMessage msg(
      String who,
      int minutesAgo,
      String body, {
      SharedMeet? meet,
      MessageKind kind = MessageKind.text,
    }) {
      final role = _topRole(club, who);
      return GroupMessage(
        id: _id('m'),
        sender: _p(who),
        body: body,
        kind: meet != null ? MessageKind.meet : kind,
        meet: meet,
        roleName: role?.showBadge == true && role!.level != RoleLevel.member
            ? role.name
            : null,
        roleColor: role?.color,
        at: DateTime.now().subtract(Duration(minutes: minutesAgo)),
      );
    }

    final social = _play.byId('ts-social')!;
    _chat[scope] = [
      msg(
        'cp-kelvin',
        75,
        'Kelvin Ho joined the club',
        kind: MessageKind.system,
      ),
      msg('cp-siti', 70, 'Courts confirmed for tonight, 3 courts booked.'),
      msg(
        'cp-siti',
        69,
        '',
        meet: SharedMeet(
          activityId: social.id,
          title: social.title,
          startsAt: social.startsAt,
          detail: '8–10 PM · LI–HI · 8 of 12',
        ),
      ),
      msg(_me, 55, 'Count me in'),
      msg(
        'cp-mei',
        48,
        'Please be on court by 8. I mark attendance at the start.',
      ),
      msg('cp-kelvin', 35, 'Hi all, thanks for having me. See you tonight!'),
      msg(
        'cp-ryan',
        32,
        'Selling 2 tickets, pay me first by PayNow to [number]',
      ),
      msg('cp-mei', 29, 'Please keep ticket sales in the Shop.'),
      msg('cp-daniel', 20, 'Anyone has a spare racket for tonight?'),
      msg(_me, 15, 'Welcome Kelvin!'),
    ];
  }

  void _seedTeams() {
    final ts = _clubs['c-ts']!;
    _teams['t-a'] = Team(
      id: 't-a',
      name: 'School Team A',
      represents: 'Tampines Secondary School',
      sport: ClubSport.badminton,
      season: 'Season ${DateTime.now().year + 1}',
      subTeams: const [
        SubTeam(name: 'Under 13', rule: 'Born 2014 or later'),
        SubTeam(
          name: 'Under 15',
          rule: 'Born 2012 or later',
          enabled: true,
          players: 6,
        ),
        SubTeam(
          name: 'Under 17',
          rule: 'Born 2010 or later',
          enabled: true,
          players: 6,
        ),
        SubTeam(name: 'Open', rule: 'Any age'),
      ],
      linkedClubs: [ts],
      playerCount: 10,
      reserveCount: 2,
      staffCount: 3,
      unreadChat: 3,
    );
    _teams['t-league'] = Team(
      id: 't-league',
      name: 'Smashers League Squad',
      represents: 'Tampines Smashers',
      logoColor: 0xFF1C1F23,
      logoInk: 0xFFF2C14E,
      linkedClubs: [ts],
      playerCount: 8,
      staffCount: 1,
    );
    _teams['t-ec'] = const Team(
      id: 't-ec',
      name: 'East Coast Mixed Team',
      represents: 'East Coast Smash',
      logoColor: 0xFFC8553D,
      playerCount: 8,
      staffCount: 1,
    );
    _teamLists[ClubTab.mine] = [
      TeamListItem(
        team: _teams['t-a']!,
        meta: '12 players, 3 staff',
        tag: 'Badminton',
      ),
    ];
    _teamLists[ClubTab.recommended] = [
      TeamListItem(
        team: _teams['t-league']!,
        meta: 'Tampines Smashers, try-outs open',
        note: 'Your level fits: LI 4.0',
        tag: 'MI–AD',
      ),
    ];
    _teamLists[ClubTab.fresh] = [
      TeamListItem(
        team: _teams['t-ec']!,
        meta: '8 players, looking for 2 women',
        note: 'Started this week',
        tag: 'LI–HI',
      ),
    ];

    TeamMember tm(
      String id, {
      String club = 'Competitive Squad',
      String? cap,
      Availability a = Availability.available,
      bool reserve = false,
    }) => TeamMember(
      player: _p(id),
      rating: id == _me ? 4.6 : _people[id]?.$2,
      club: club,
      captain: cap,
      availability: a,
      reserve: reserve,
    );
    _teamMembers['t-a'] = [
      tm('cp-ravi', cap: 'Captain'),
      tm('cp-jason', cap: 'Vice-captain'),
      tm('cp-weiming'),
      tm(_me, club: 'Badminton Club', a: Availability.noReply),
      tm('cp-mei', club: 'Badminton Club'),
      tm('cp-kelvin'),
      tm('cp-daniel', club: 'Badminton Club'),
      tm('cp-siti', a: Availability.unavailable, reserve: true),
      tm('cp-priya', club: 'Badminton Club', reserve: true),
      tm('cp-marcuss', club: 'Badminton Club'),
      tm('cp-nicole', a: Availability.noReply),
      tm('cp-ben', club: 'Badminton Club'),
      TeamMember(player: _p('cp-coach'), staff: true, staffTitle: 'Head coach'),
      TeamMember(
        player: _p('cp-mslee'),
        staff: true,
        staffTitle: 'Teacher-in-charge',
      ),
      TeamMember(
        player: _p('cp-rahman'),
        staff: true,
        staffTitle: 'Team manager',
      ),
    ];
    final fixtureAt = _next(DateTime.saturday, 9);
    _teamSessions['t-a'] = [
      TeamSession(
        id: 'ts-1',
        title: 'Doubles drills',
        startsAt: _next(DateTime.tuesday, 16),
        endsAt: _next(DateTime.tuesday, 18),
        venue: 'School hall',
        attending: 9,
        squad: 12,
      ),
      TeamSession(
        id: 'ts-2',
        title: 'Match practice',
        startsAt: _next(DateTime.thursday, 16),
        endsAt: _next(DateTime.thursday, 18),
        venue: 'School hall',
        attending: 7,
        squad: 12,
      ),
      TeamSession(
        id: 'fx-a1',
        title: 'vs Bedok Racquets',
        startsAt: fixtureAt,
        venue: 'Bedok Sports Hall',
        fixture: true,
        attending: 10,
        squad: 12,
      ),
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    _results['t-a'] = [
      TeamResult(
        opponent: 'vs Bedok Racquets',
        at: _daysAgo(18, 9),
        competition: 'Inter-school',
        won: true,
        score: '3–2',
      ),
      TeamResult(
        opponent: 'vs Pasir Ris Primary',
        at: _daysAgo(32, 9),
        competition: 'Inter-school',
        won: false,
        score: '1–4',
      ),
    ];
    _fixtures['fx-a1'] = Fixture(
      id: 'fx-a1',
      teamId: 't-a',
      teamName: 'School Team A',
      opponent: 'Bedok Racquets',
      startsAt: fixtureAt,
      competition: 'League · Round 4',
      venue: 'Bedok Sports Hall, Courts 1 to 3',
      lineupLocksAt: fixtureAt.subtract(const Duration(hours: 15)),
      notes: const [
        'Meet at 8:30 AM at the front desk',
        'Team shirt, own racket, shuttles provided',
      ],
      setBy: 'Coach Tan',
      lineupRule: '3 singles and 2 doubles, 2 reserves',
      slots: const [
        LineupSlot(key: 'S1', label: 'Singles 1'),
        LineupSlot(key: 'S2', label: 'Singles 2'),
        LineupSlot(key: 'S3', label: 'Singles 3'),
        LineupSlot(key: 'D1', label: 'Doubles 1', size: 2),
        LineupSlot(key: 'D2', label: 'Doubles 2', size: 2),
        LineupSlot(key: 'R', label: 'Reserve', size: 2),
      ],
      lineup: const {
        'S1': ['cp-ravi'],
        'S2': ['cp-jason'],
        'S3': ['cp-weiming'],
        'D1': [_me, 'cp-mei'],
        'D2': ['cp-kelvin', 'cp-daniel'],
        'R': ['cp-siti', 'cp-priya'],
      },
      published: true,
    );

    const team = ChatScope.team('t-a');
    GroupMessage tmsg(
      String who,
      int ago,
      String body, {
      String? role,
      MessageKind kind = MessageKind.text,
    }) => GroupMessage(
      id: _id('tm'),
      sender: _p(who),
      body: body,
      kind: kind,
      roleName: role,
      roleColor: role == 'Staff' ? 0xFF2F3A5F : 0xFFB9832A,
      at: DateTime.now().subtract(Duration(minutes: ago)),
    );
    _chat[team] = [
      tmsg(
        'cp-coach',
        120,
        'Lineup for Saturday is up. Please reply with your availability by Thursday.',
        role: 'Staff',
        kind: MessageKind.lineup,
      ),
      tmsg(
        'cp-ravi',
        105,
        'Doubles pairs, let’s stay back after Thursday training for 20 min of serve-return.',
        role: 'Captain',
      ),
      tmsg('cp-mei', 88, 'Available for Saturday. See you Thursday!'),
    ];
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  ClubRole? _topRole(String clubId, String userId) {
    final m = _members[clubId]?[userId];
    if (m == null) return null;
    final roles = (_roles[clubId] ?? const <ClubRole>[])
        .where((r) => m.roleIds.contains(r.id))
        .toList();
    if (roles.isEmpty) return null;
    roles.sort((a, b) {
      final byLevel = b.level.index.compareTo(a.level.index);
      if (b.isOwner != a.isOwner) return b.isOwner ? 1 : -1;
      return byLevel != 0 ? byLevel : a.position.compareTo(b.position);
    });
    return roles.first;
  }

  Club _view(String id) {
    final base = _clubs[id];
    if (base == null) throw const AuthFailure('This club no longer exists.');
    final mine = _members[id]?[_me];
    final roles = _roles[id] ?? const <ClubRole>[];
    final myRoles = roles.where((r) => mine?.roleIds.contains(r.id) ?? false);
    final perms = {for (final r in myRoles) ...r.permissions};
    final owner = myRoles.any((r) => r.isOwner) || base.isOwner;
    final top = mine == null ? null : _topRole(id, _me);
    return base.copyWith(
      standing: mine != null
          ? ClubStanding.member
          : (base.standing == ClubStanding.member
                ? ClubStanding.outsider
                : base.standing),
      isOwner: owner,
      myPermissions: owner ? ClubPermission.values.toSet() : perms,
      myRoleName: top?.name,
      pendingRequests: (_requests[id] ?? const [])
          .where((r) => r.status == RequestStatus.pending)
          .length,
      roleCount: roles.length,
      banCount: (_bans[id] ?? const []).length,
    );
  }

  void _log(String clubId, AuditCategory c, String action, [String d = '']) {
    (_audit[clubId] ??= []).insert(
      0,
      AuditEntry(
        id: _id('au'),
        category: c,
        actor: 'Aaron Ng',
        action: action,
        detail: d,
        at: DateTime.now(),
      ),
    );
  }

  String _levelNote(Club c) {
    final band = SkillBand.forLevel(4.0);
    return c.primaryRange.contains(band)
        ? 'Your level fits: ${band.code} 4.0'
        : 'Your level: ${band.code} 4.0';
  }

  // ─── Browse ──────────────────────────────────────────────────────────────

  @override
  Future<List<ClubListItem>> clubs(ClubTab tab) async {
    await _tick();
    return [
      for (final id in _lists[tab] ?? const <String>[])
        if (_clubs.containsKey(id))
          ClubListItem(
            club: _view(id),
            note: tab == ClubTab.recommended
                ? _levelNote(_clubs[id]!)
                : (_notes[id] ?? ''),
          ),
    ];
  }

  @override
  Future<List<TeamListItem>> teams(ClubTab tab) async {
    await _tick();
    return [
      for (final t in _teamLists[tab] ?? const <TeamListItem>[])
        if (_teams.containsKey(t.team.id)) t.copyWith(team: _teams[t.team.id]!),
    ];
  }

  // ─── A club ──────────────────────────────────────────────────────────────

  @override
  Future<Club> club(String id) async {
    await _tick();
    return _view(id);
  }

  @override
  Future<String?> clubIdForCode(String code) async {
    await _tick();
    final want = code.trim().toUpperCase();
    return _clubs.values
        .where((c) => c.inviteCode?.toUpperCase() == want)
        .firstOrNull
        ?.id;
  }

  @override
  Future<List<Activity>> sessions(String clubId) async {
    await _tick();
    return _play.forClub(clubId);
  }

  @override
  Future<void> join(String clubId, {String message = ''}) async {
    await _tick();
    final c = _clubs[clubId]!;
    final instant =
        c.visibility == ClubVisibility.public && c.joinMode == JoinMode.anyone;
    if (instant) {
      (_members[clubId] ??= {})[_me] = _member(_me, const [], joinedDays: 0);
      _clubs[clubId] = c.copyWith(memberCount: c.memberCount + 1);
      final mine = _lists[ClubTab.mine]!;
      if (!mine.contains(clubId)) mine.add(clubId);
    } else {
      _clubs[clubId] = c.copyWith(standing: ClubStanding.requested);
    }
  }

  @override
  Future<void> cancelRequest(String clubId) async {
    await _tick();
    _clubs[clubId] = _clubs[clubId]!.copyWith(standing: ClubStanding.outsider);
  }

  @override
  Future<void> leave(String clubId) async {
    await _tick();
    final c = _clubs[clubId]!;
    if (_view(clubId).isOwner) {
      throw const AuthFailure(
        'Transfer ownership to an Admin before you leave.',
      );
    }
    _members[clubId]?.remove(_me);
    _clubs[clubId] = c.copyWith(
      memberCount: c.memberCount - 1,
      standing: ClubStanding.outsider,
    );
    _lists[ClubTab.mine]!.remove(clubId);
  }

  // ─── Members and roles ───────────────────────────────────────────────────

  @override
  Future<List<ClubMember>> members(String clubId) async {
    await _tick();
    return [...?_members[clubId]?.values];
  }

  @override
  Future<List<ClubRole>> roles(String clubId) async {
    await _tick();
    final members = _members[clubId] ?? const {};
    return [
      for (final r in _roles[clubId] ?? const <ClubRole>[])
        r.copyWith(
          memberCount: members.values
              .where((m) => m.roleIds.contains(r.id))
              .length,
        ),
    ]..sort((a, b) => a.position.compareTo(b.position));
  }

  @override
  Future<void> setMemberRole(
    String clubId,
    String userId,
    String? roleId,
  ) async {
    await _tick();
    final m = _members[clubId]![userId]!;
    final labels = (_roles[clubId] ?? const <ClubRole>[])
        .where((r) => r.isLabel && m.roleIds.contains(r.id))
        .map((r) => r.id);
    _members[clubId]![userId] = m.copyWith(roleIds: [...labels, ?roleId]);
    final role = _roles[clubId]!.where((r) => r.id == roleId).firstOrNull;
    _log(
      clubId,
      AuditCategory.roles,
      role == null
          ? 'set ${m.player.displayName} to Everyone'
          : 'gave ${m.player.displayName} the ${role.name} role',
    );
  }

  @override
  Future<void> removeMember(String clubId, String userId) async {
    await _tick();
    final m = _members[clubId]!.remove(userId);
    final c = _clubs[clubId]!;
    _clubs[clubId] = c.copyWith(memberCount: c.memberCount - 1);
    _log(clubId, AuditCategory.members, 'removed ${m?.player.displayName}');
  }

  @override
  Future<void> banMember(String clubId, String userId, String reason) async {
    await _tick();
    final m = _members[clubId]!.remove(userId);
    final c = _clubs[clubId]!;
    if (m != null) {
      _clubs[clubId] = c.copyWith(memberCount: c.memberCount - 1);
    }
    (_bans[clubId] ??= []).insert(
      0,
      ClubBan(
        player: m?.player ?? _p(userId),
        bannedBy: 'Aaron Ng',
        at: DateTime.now(),
        reason: reason,
      ),
    );
    _log(clubId, AuditCategory.members, 'banned a member', 'Reason: $reason');
  }

  @override
  Future<List<ClubBan>> bans(String clubId) async {
    await _tick();
    return [...?_bans[clubId]];
  }

  @override
  Future<void> unban(String clubId, String userId) async {
    await _tick();
    _bans[clubId]?.removeWhere((b) => b.player.id == userId);
    _log(clubId, AuditCategory.members, 'unbanned ${_p(userId).displayName}');
  }

  @override
  Future<List<JoinRequest>> requests(String clubId) async {
    await _tick();
    final range = _clubs[clubId]!.primaryRange;
    return [
      for (final r in _requests[clubId] ?? const <JoinRequest>[])
        r.copyWith(
          belowRange:
              r.rating != null &&
              !range.contains(SkillBand.forLevel(r.rating!)),
        ),
    ];
  }

  @override
  Future<void> decideRequest(
    String clubId,
    String requestId,
    RequestStatus status,
  ) async {
    await _tick();
    final list = _requests[clubId]!;
    final i = list.indexWhere((r) => r.id == requestId);
    final r = list[i];
    list[i] = r.copyWith(status: status);
    final members = _members[clubId]!;
    final c = _clubs[clubId]!;
    if (status == RequestStatus.approved && !members.containsKey(r.player.id)) {
      members[r.player.id] = ClubMember(
        player: r.player,
        rating: r.rating,
        joinedAt: DateTime.now(),
      );
      _clubs[clubId] = c.copyWith(memberCount: c.memberCount + 1);
      _log(
        clubId,
        AuditCategory.members,
        'approved ${r.player.displayName}’s join request',
      );
    } else if (status != RequestStatus.approved &&
        members.containsKey(r.player.id) &&
        r.status == RequestStatus.approved) {
      members.remove(r.player.id);
      _clubs[clubId] = c.copyWith(memberCount: c.memberCount - 1);
    }
    if (status == RequestStatus.declined) {
      _log(
        clubId,
        AuditCategory.members,
        'declined ${r.player.displayName}’s join request',
      );
    }
  }

  @override
  Future<List<AuditEntry>> audit(String clubId) async {
    await _tick();
    return [...?_audit[clubId]];
  }

  @override
  Future<ClubRole> createRole(
    String clubId, {
    required String name,
    required int color,
    required RoleLevel level,
    required Set<String> members,
  }) async {
    await _tick();
    final roles = _roles[clubId]!;
    final role = ClubRole(
      id: _id('role'),
      name: name,
      color: color,
      level: level,
      permissions: level.permissions,
      position: roles.length,
    );
    roles.add(role);
    for (final id in members) {
      final m = _members[clubId]![id];
      if (m != null) {
        _members[clubId]![id] = m.copyWith(roleIds: [...m.roleIds, role.id]);
      }
    }
    _log(clubId, AuditCategory.roles, 'created the role $name');
    return role;
  }

  @override
  Future<void> updateRole(String clubId, ClubRole role) async {
    await _tick();
    final roles = _roles[clubId]!;
    final i = roles.indexWhere((r) => r.id == role.id);
    final before = roles[i];
    roles[i] = role;
    if (before.permissions != role.permissions) {
      _log(clubId, AuditCategory.roles, 'changed permissions for ${role.name}');
    } else if (before.name != role.name) {
      _log(
        clubId,
        AuditCategory.roles,
        'renamed ${before.name} to ${role.name}',
      );
    }
  }

  @override
  Future<void> deleteRole(String clubId, String roleId) async {
    await _tick();
    final role = _roles[clubId]!.firstWhere((r) => r.id == roleId);
    _roles[clubId]!.removeWhere((r) => r.id == roleId);
    _members[clubId]!.updateAll(
      (_, m) =>
          m.copyWith(roleIds: m.roleIds.where((id) => id != roleId).toList()),
    );
    _log(clubId, AuditCategory.roles, 'deleted the role ${role.name}');
  }

  @override
  Future<void> reorderRoles(String clubId, List<String> roleIds) async {
    await _tick();
    final roles = _roles[clubId]!;
    for (var i = 0; i < roleIds.length; i++) {
      final j = roles.indexWhere((r) => r.id == roleIds[i]);
      roles[j] = roles[j].copyWith(position: i + 1);
    }
  }

  @override
  Future<void> setRoleMembers(
    String clubId,
    String roleId,
    Set<String> ids,
  ) async {
    await _tick();
    _members[clubId]!.updateAll((id, m) {
      final has = m.roleIds.contains(roleId);
      if (ids.contains(id) && !has) {
        return m.copyWith(roleIds: [...m.roleIds, roleId]);
      }
      if (!ids.contains(id) && has) {
        return m.copyWith(
          roleIds: m.roleIds.where((r) => r != roleId).toList(),
        );
      }
      return m;
    });
  }

  // ─── Announcements and chat ──────────────────────────────────────────────

  @override
  Future<List<Announcement>> announcements(String clubId) async {
    await _tick();
    final list = [...?_news[clubId]];
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.at.compareTo(a.at);
    });
    return list;
  }

  @override
  Future<void> announce(
    String clubId, {
    required String title,
    required String body,
    required String audience,
    required bool pinned,
  }) async {
    await _tick();
    final list = _news[clubId] ??= [];
    if (pinned) {
      for (var i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(pinned: false);
      }
    }
    final role = _topRole(clubId, _me);
    list.insert(
      0,
      Announcement(
        id: _id('an'),
        author: 'Aaron Ng',
        authorRole: (role?.isOwner ?? false) ? 'owner' : 'admin',
        title: title,
        body: body,
        pinned: pinned,
        at: DateTime.now(),
      ),
    );
    _log(clubId, AuditCategory.club, 'posted an announcement', title);
  }

  StreamController<List<GroupMessage>> _stream(ChatScope scope) =>
      _streams.putIfAbsent(scope, StreamController.broadcast);

  @override
  Stream<List<GroupMessage>> chat(ChatScope scope) async* {
    yield [...?_chat[scope]];
    yield* _stream(scope).stream;
  }

  @override
  Future<void> send(ChatScope scope, String body, {String? activityId}) async {
    final list = _chat[scope] ??= [];
    Activity? a;
    if (activityId != null) a = await _play.activity(activityId);
    final role = scope.isTeam ? null : _topRole(scope.id, _me);
    list.add(
      GroupMessage(
        id: _id('m'),
        sender: _aaron,
        body: body,
        kind: a != null ? MessageKind.meet : MessageKind.text,
        roleName: role != null && role.level != RoleLevel.member
            ? role.name
            : null,
        roleColor: role?.color,
        meet: a == null
            ? null
            : SharedMeet(
                activityId: a.id,
                title: a.title,
                startsAt: a.startsAt,
                detail: '${a.levelRange} · ${a.spotsTaken} of ${a.capacity}',
              ),
        at: DateTime.now(),
      ),
    );
    _stream(scope).add([...list]);
  }

  @override
  Future<void> sendPhoto(ChatScope scope, String filePath) async {
    final list = _chat[scope] ??= [];
    list.add(
      GroupMessage(
        id: _id('m'),
        sender: _aaron,
        kind: MessageKind.photo,
        photo: filePath,
        at: DateTime.now(),
      ),
    );
    _stream(scope).add([...list]);
  }

  @override
  Future<void> removeMessage(
    ChatScope scope,
    String messageId,
    bool removed,
  ) async {
    final list = _chat[scope]!;
    final i = list.indexWhere((m) => m.id == messageId);
    list[i] = list[i].copyWith(
      removed: removed,
      removedBy: removed ? 'Aaron' : null,
    );
    _stream(scope).add([...list]);
  }

  @override
  Future<void> report(
    ReportTarget target,
    ContentReport reason,
    String note,
  ) async {
    await _tick();
  }

  // ─── Club info ───────────────────────────────────────────────────────────

  @override
  Future<ClubLeaderboard> leaderboard(String clubId, ClubSport sport) async {
    await _tick();
    if (clubId == 'c-ts' && sport == ClubSport.badminton) {
      LeaderboardEntry e(String id, String score, String sub, String move) =>
          LeaderboardEntry(player: _p(id), score: score, sub: sub, move: move);
      return ClubLeaderboard(
        period: 'This month',
        rows: [
          e('cp-ravi', '6.4', '14 matches · HI', 'same'),
          e('cp-jason', '6.1', '11 matches · HI', 'up 1'),
          e('cp-siti', '5.7', '9 matches · MI', 'down 1'),
          e('cp-weiming', '5.3', '8 matches · MI', 'up 2'),
          e('cp-mei', '4.6', '6 matches · LI', 'same'),
          e('cp-daniel', '4.2', '5 matches · LI', 'down 1'),
          e('cp-kelvin', '4.2', '4 matches · LI', 'new'),
          e('cp-priya', '3.8', '4 matches · HB', 'up 1'),
        ],
        me: LeaderboardEntry(player: _aaron, score: '3.6'),
        myRank: 9,
        myNote: '0.2 behind #8',
      );
    }
    final ranked =
        (_members[clubId]?.values.where((m) => m.rating != null).toList() ??
              <ClubMember>[])
          ..sort((a, b) => b.rating!.compareTo(a.rating!));
    final rows = [
      for (final m in ranked)
        LeaderboardEntry(
          player: m.player,
          score: m.rating!.toStringAsFixed(1),
          sub: '${m.meetsPlayed} matches · ${m.band!.code}',
        ),
    ];
    final mine = rows.indexWhere((r) => r.player.id == _me);
    return ClubLeaderboard(
      period: 'This month',
      rows: rows,
      me: mine < 0 ? null : rows[mine],
      myRank: mine < 0 ? null : mine + 1,
      myNote: mine <= 0
          ? 'Top of the club'
          : '${(double.parse(rows[mine - 1].score) - double.parse(rows[mine].score)).toStringAsFixed(1)} behind #$mine',
    );
  }

  @override
  Future<ClubReward> reward(String clubId) async {
    await _tick();
    final now = DateTime.now();
    final month = now.month;
    String monthName(int m) => const [
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
    ][(m - 1) % 12];
    return ClubReward(
      meets: [
        RewardMeet(
          title: 'Doubles Social',
          at: _daysAgo(12, 20),
          paidPresent: 9,
        ),
        RewardMeet(
          title: 'Morning Singles',
          at: _daysAgo(11, 9),
          paidPresent: 6,
        ),
        RewardMeet(
          title: 'Beginner Rotation',
          at: _daysAgo(8, 19),
          paidPresent: 5,
        ),
      ],
      past: [
        (monthName(month - 1 + 12), 'S\$20 shuttle voucher, used'),
        (monthName(month - 2 + 12), 'Not reached, 3 of 4'),
      ],
    );
  }

  @override
  Future<void> updateClub(Club club) async {
    await _tick();
    final before = _clubs[club.id]!;
    _clubs[club.id] = before.copyWith(
      name: club.name,
      description: club.description,
      rules: club.rules,
      visibility: club.visibility,
      joinMode: club.joinMode,
      sports: club.sports,
      playRules: club.playRules,
    );
    _log(club.id, AuditCategory.club, 'updated the club info');
  }

  @override
  Future<void> transfer(String clubId, String toUserId) async {
    await _tick();
    _log(
      clubId,
      AuditCategory.club,
      'asked ${_p(toUserId).displayName} to take over the club',
    );
  }

  @override
  Future<void> deleteClub(String clubId) async {
    await _tick();
    _clubs.remove(clubId);
    for (final list in _lists.values) {
      list.remove(clubId);
    }
  }

  @override
  Future<String> createClub(ClubDraft d) async {
    await _tick();
    final id = _id('club');
    const palette = [0xFF0E6B4E, 0xFF2F3A5F, 0xFFC8553D, 0xFF3E6B8A];
    _clubs[id] = Club(
      id: id,
      name: d.name.trim(),
      description: d.description.trim(),
      area: d.area,
      homeVenue: d.venueName,
      sports: [
        for (final s in d.sports)
          ClubSportLevel(
            sport: s,
            range: d.ranges[s] ?? const LevelRange.all(),
          ),
      ],
      visibility: d.visibility,
      joinMode: d.visibility == ClubVisibility.public
          ? d.joinMode
          : JoinMode.request,
      memberCount: 1,
      logoColor: palette[_counter % palette.length],
      coverColor: 0xFFE8590C,
      createdAt: DateTime.now(),
      standing: ClubStanding.member,
      isOwner: true,
      inviteCode: 'OG${_counter.toString().padLeft(4, '0')}',
    );
    final owner = ClubRole(
      id: '$id-owner',
      name: 'Owner',
      color: 0xFF1C1F23,
      level: RoleLevel.admin,
      isOwner: true,
      permissions: ClubPermission.values.toSet(),
    );
    _roles[id] = [
      owner,
      ClubRole(
        id: '$id-admin',
        name: 'Admin',
        color: 0xFFC8553D,
        level: RoleLevel.admin,
        permissions: ClubPermission.admin,
        position: 1,
      ),
    ];
    _members[id] = {
      _me: _member(_me, [owner.id], joinedDays: 0, played: 0),
    };
    _requests[id] = [];
    _audit[id] = [];
    _log(id, AuditCategory.club, 'created the club');
    _notes[id] = 'You started this club';
    _lists[ClubTab.mine]!.insert(0, id);
    if (d.invite.isNotEmpty) await invite(id, d.invite);
    return id;
  }

  @override
  Future<List<InviteCandidate>> inviteCandidates() async {
    await _tick();
    InviteCandidate c(String id, int together) => InviteCandidate(
      player: _p(id),
      rating: _people[id]?.$2,
      meetsTogether: together,
    );
    return [
      c('cp-mei', 6),
      c('cp-hafiz', 4),
      c('cp-daniel', 3),
      c('cp-priya', 2),
      c('cp-kelvin', 1),
    ];
  }

  @override
  Future<void> invite(String clubId, Set<String> userIds) async {
    await _tick();
    _log(
      clubId,
      AuditCategory.members,
      'invited ${userIds.length} ${userIds.length == 1 ? 'player' : 'players'}',
    );
  }

  // ─── Teams ───────────────────────────────────────────────────────────────

  @override
  Future<Team> team(String id) async {
    await _tick();
    final t = _teams[id];
    if (t == null) throw const AuthFailure('This team no longer exists.');
    return t;
  }

  @override
  Future<List<TeamSession>> teamSessions(String teamId) async {
    await _tick();
    return [...?_teamSessions[teamId]];
  }

  @override
  Future<List<TeamResult>> teamResults(String teamId) async {
    await _tick();
    return [...?_results[teamId]];
  }

  @override
  Future<List<TeamMember>> teamMembers(String teamId) async {
    await _tick();
    return [...?_teamMembers[teamId]];
  }

  @override
  Future<String?> nextFixtureId(String teamId) async {
    final upcoming =
        _fixtures.values
            .where(
              (f) => f.teamId == teamId && f.startsAt.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return upcoming.firstOrNull?.id;
  }

  @override
  Future<Fixture> fixture(String fixtureId) async {
    await _tick();
    final f = _fixtures[fixtureId]!;
    final mine = _teamMembers[f.teamId]
        ?.where((m) => m.player.id == _me)
        .firstOrNull;
    return f.copyWith(myAvailability: mine?.availability ?? f.myAvailability);
  }

  @override
  Future<void> setAvailability(
    String fixtureId,
    Availability availability,
  ) async {
    await _tick();
    final f = _fixtures[fixtureId]!;
    final list = _teamMembers[f.teamId]!;
    final i = list.indexWhere((m) => m.player.id == _me);
    if (i >= 0) list[i] = list[i].copyWith(availability: availability);
    _fixtures[fixtureId] = f.copyWith(myAvailability: availability);
  }

  @override
  Future<void> saveLineup(
    String fixtureId,
    Map<String, List<String?>> lineup, {
    required bool publish,
  }) async {
    await _tick();
    final f = _fixtures[fixtureId]!;
    _fixtures[fixtureId] = f.copyWith(lineup: lineup, published: publish);
    if (publish) {
      final scope = ChatScope.team(f.teamId);
      (_chat[scope] ??= []).add(
        GroupMessage(
          id: _id('tm'),
          sender: _aaron,
          body: 'Shared the lineup for ${f.opponent}',
          kind: MessageKind.lineup,
          at: DateTime.now(),
        ),
      );
      _stream(scope).add([...?_chat[scope]]);
    }
  }

  @override
  Future<List<InviteCandidate>> teamCandidates(String teamId) async {
    await _tick();
    InviteCandidate c(String id, String age) => InviteCandidate(
      player: _p(id),
      rating: _people[id]?.$2,
      club: 'Tampines Smashers',
      age: age,
    );
    final have = {for (final m in _teamMembers[teamId] ?? []) m.player.id};
    return [
      for (final x in [
        c('cp-priyar', 'Under 17'),
        c('cp-danielt', 'Under 15'),
        c('cp-sitil', 'Under 17'),
        c('cp-marcusy', 'Under 15'),
        c('cp-hafiz', 'Under 17'),
      ])
        if (!have.contains(x.player.id)) x,
    ];
  }

  @override
  Future<void> addTeamPlayers(String teamId, Set<String> userIds) async {
    await _tick();
    final list = _teamMembers[teamId] ??= [];
    for (final id in userIds) {
      if (list.any((m) => m.player.id == id)) continue;
      list.add(
        TeamMember(
          player: _p(id),
          rating: _people[id]?.$2,
          club: 'Tampines Smashers',
        ),
      );
    }
    final t = _teams[teamId]!;
    _teams[teamId] = t.copyWith(playerCount: t.playerCount + userIds.length);
  }

  @override
  Future<String> createTeam(TeamDraft d) async {
    await _tick();
    final id = _id('team');
    const rules = {
      'Under 13': 'Born 2014 or later',
      'Under 15': 'Born 2012 or later',
      'Under 17': 'Born 2010 or later',
      'Open': 'Any age',
    };
    _teams[id] = Team(
      id: id,
      name: d.name.trim(),
      represents: d.represents.trim(),
      sport: d.sport,
      season: 'Season ${DateTime.now().year}',
      subTeams: [
        for (final e in rules.entries)
          SubTeam(
            name: e.key,
            rule: e.value,
            enabled: d.subTeams.contains(e.key),
          ),
        if (d.ownSubTeam != null && d.ownSubTeam!.trim().isNotEmpty)
          SubTeam(name: d.ownSubTeam!.trim(), enabled: true),
      ],
      linkedClubs: [
        for (final cid in _lists[ClubTab.mine]!)
          if (_clubs.containsKey(cid)) _clubs[cid]!,
      ],
      staffCount: 1 + d.staff.length,
      myRole: TeamRole.owner,
    );
    _teamMembers[id] = [
      TeamMember(
        player: _aaron,
        staff: true,
        staffTitle: 'Head coach · team owner',
      ),
      for (final pid in d.players)
        TeamMember(player: _p(pid), rating: _people[pid]?.$2, club: 'Invited'),
    ];
    _teamSessions[id] = [];
    _results[id] = [];
    _teamLists[ClubTab.mine]!.insert(
      0,
      TeamListItem(
        team: _teams[id]!,
        meta: '${d.players.length} players, ${1 + d.staff.length} staff',
        note: 'Invites sent',
        tag: d.sport.label,
      ),
    );
    return id;
  }

  @override
  Future<void> updateTeam(Team team) async {
    await _tick();
    _teams[team.id] = team;
  }

  @override
  Future<void> leaveTeam(String teamId) async {
    await _tick();
    _teamMembers[teamId]?.removeWhere((m) => m.player.id == _me);
    _teamLists[ClubTab.mine]!.removeWhere((t) => t.team.id == teamId);
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    await _tick();
    _teams.remove(teamId);
    for (final list in _teamLists.values) {
      list.removeWhere((t) => t.team.id == teamId);
    }
  }
}
