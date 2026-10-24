import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../../play/data/play_repository.dart';
import '../../play/domain/activity.dart';
import '../../social/domain/social_models.dart';
import '../domain/club_models.dart';
import '../domain/club_sport.dart';
import 'club_repository.dart';

/// Clubs, teams and group chat on Supabase. Reads and changes go through
/// database functions that check the player's club role; see the clubs
/// migration.
class SupabaseClubRepository implements ClubRepository {
  SupabaseClubRepository(this._client, this._play);

  final SupabaseClient _client;
  final SupabasePlayRepository _play;

  String get _me {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthFailure('Log in again to continue.');
    return id;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Club error: ${e.code} ${e.message}');
      // Club functions raise readable messages; pass those through.
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on StorageException catch (e) {
      debugPrint('Club photo error: ${e.statusCode} ${e.message}');
      throw const AuthFailure("Couldn't send the photo. Try again.");
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Club network error: $e');
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) =>
      _client.rpc(fn, params: params);

  Future<List<Map<String, dynamic>>> _list(
    String fn, [
    Map<String, dynamic>? params,
  ]) async => [
    for (final r in (await _rpc(fn, params) as List? ?? const []))
      Map<String, dynamic>.from(r as Map),
  ];

  static DateTime _at(Object? v) => DateTime.parse(v as String).toLocal();
  static int _int(Object? v) => (v as num?)?.toInt() ?? 0;
  static double? _num(Object? v) => (v as num?)?.toDouble();

  static PlayerSummary _player(Object? v) =>
      PlayerSummary.fromRow(Map<String, dynamic>.from(v as Map));

  // ─── Mapping ─────────────────────────────────────────────────────────────

  static Club _club(Map<String, dynamic> j) => Club(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String? ?? '',
    rules: [for (final r in j['rules'] as List? ?? const []) r as String],
    area: j['area'] as String? ?? '',
    homeVenue: j['home_venue'] as String?,
    sports: [
      for (final s in j['sports'] as List? ?? const [])
        if (ClubSport.values.any((x) => x.id == s['sport']))
          ClubSportLevel(
            sport: ClubSport.fromId(s['sport'] as String),
            range: LevelRange(
              _int(s['min'] ?? 0),
              (s['max'] as num?)?.toInt() ?? 7,
            ),
          ),
    ],
    visibility: ClubVisibility.fromId(j['visibility'] as String),
    joinMode: JoinMode.fromId(j['join_mode'] as String),
    memberCount: _int(j['member_count']),
    logoColor: _int(j['logo_color']),
    logoInk: _int(j['logo_ink']),
    coverColor: _int(j['cover_color']),
    createdAt: j['created_at'] == null ? null : _at(j['created_at']),
    meetsPerWeek: _int(j['meets_per_week']),
    standing: ClubStanding.values.byName(j['standing'] as String),
    isOwner: j['is_owner'] as bool? ?? false,
    myPermissions: {
      for (final p in j['permissions'] as List? ?? const [])
        ?ClubPermission.fromId(p as String),
    },
    myRoleName: j['role_name'] as String?,
    pendingRequests: _int(j['pending_requests']),
    unreadChat: _int(j['unread_chat']),
    roleCount: _int(j['role_count']),
    banCount: _int(j['ban_count']),
    activeInvites: _int(j['active_invites']),
    playRules: {
      for (final e
          in (j['play_rules'] as Map? ?? const <String, dynamic>{}).entries)
        '${e.key}': '${e.value}',
    },
    inviteCode: j['invite_code'] as String?,
    rating: _num(j['rating']),
    ratingCount: _int(j['rating_count']),
    ratingSpread: [
      for (final n in j['rating_spread'] as List? ?? const [0, 0, 0, 0, 0])
        _int(n),
    ],
    myStars: (j['my_stars'] as num?)?.toInt(),
  );

  static ClubRole _role(Map<String, dynamic> j) => ClubRole(
    id: j['id'] as String,
    name: j['name'] as String,
    color: _int(j['color']),
    level: RoleLevel.values.byName(j['level'] as String),
    permissions: {
      for (final p in j['permissions'] as List? ?? const [])
        ?ClubPermission.fromId(p as String),
    },
    memberCount: _int(j['member_count']),
    showBadge: j['show_badge'] as bool? ?? true,
    isOwner: j['is_owner'] as bool? ?? false,
    position: _int(j['position']),
  );

  static Team _team(Map<String, dynamic> j) => Team(
    id: j['id'] as String,
    name: j['name'] as String,
    represents: j['represents'] as String? ?? '',
    sport: ClubSport.values.firstWhere(
      (s) => s.id == j['sport'],
      orElse: () => ClubSport.badminton,
    ),
    season: j['season'] as String? ?? '',
    logoColor: _int(j['logo_color']),
    logoInk: _int(j['logo_ink']),
    subTeams: [
      for (final s in j['sub_teams'] as List? ?? const [])
        SubTeam(
          name: s['name'] as String,
          rule: s['rule'] as String? ?? '',
          enabled: s['enabled'] as bool? ?? false,
          players: _int(s['players']),
        ),
    ],
    linkedClubs: [
      for (final c in j['linked_clubs'] as List? ?? const [])
        Club(
          id: c['id'] as String,
          name: c['name'] as String,
          logoColor: _int(c['logo_color']),
          logoInk: _int(c['logo_ink']),
        ),
    ],
    playerCount: _int(j['player_count']),
    reserveCount: _int(j['reserve_count']),
    staffCount: _int(j['staff_count']),
    myRole: TeamRole.values.byName(j['my_role'] as String),
    unreadChat: _int(j['unread_chat']),
  );

  static Availability _availability(Object? v) =>
      Availability.fromId(v as String? ?? 'no_reply');

  static Map<String, dynamic> _sports(List<ClubSportLevel> sports) => {
    'sports': [
      for (final s in sports)
        {'sport': s.sport.id, 'min': s.range.min, 'max': s.range.max},
    ],
  };

  // ─── Browse ──────────────────────────────────────────────────────────────

  @override
  Future<List<ClubListItem>> clubs(ClubTab tab) => _guard(() async {
    final rows = await _list('club_list', {'p_tab': tab.name});
    final now = DateTime.now();
    return [
      for (final r in rows)
        () {
          final c = _club(r);
          final note = switch (tab) {
            ClubTab.mine =>
              c.isOwner ? 'You run this club' : (c.myRoleName ?? 'Member'),
            ClubTab.fresh when c.createdAt != null => switch (now
                .difference(c.createdAt!)
                .inDays) {
              0 => 'Started today',
              1 => 'Started yesterday',
              final d => 'Started $d days ago',
            },
            _ => [
              '${c.memberCount} ${c.memberCount == 1 ? 'member' : 'members'}',
              if (c.area.isNotEmpty) c.area,
            ].join(' · '),
          };
          return ClubListItem(club: c, note: note);
        }(),
    ];
  });

  @override
  Future<List<TeamListItem>> teams(ClubTab tab) => _guard(() async {
    final rows = await _list('team_list', {'p_tab': tab.name});
    return [
      for (final r in rows)
        () {
          final t = _team(r);
          return TeamListItem(
            team: t,
            meta:
                '${t.playerCount} ${t.playerCount == 1 ? 'player' : 'players'}, '
                '${t.staffCount} staff',
            tag: t.sport.label,
          );
        }(),
    ];
  });

  // ─── One club ────────────────────────────────────────────────────────────

  @override
  Future<Club> club(String id) => _guard(() async {
    final j = await _rpc('club_get', {'p_club': id});
    if (j == null) throw const AuthFailure('This club no longer exists.');
    return _club(Map<String, dynamic>.from(j as Map));
  });

  @override
  Future<String?> clubIdForCode(String code) => _guard(
    () async => await _rpc('club_for_code', {'p_code': code}) as String?,
  );

  @override
  Future<List<Activity>> sessions(String clubId) => _play.forClub(clubId);

  @override
  Future<void> join(String clubId, {String message = ''}) =>
      _guard(() => _rpc('club_join', {'p_club': clubId, 'p_message': message}));

  @override
  Future<void> cancelRequest(String clubId) =>
      _guard(() => _rpc('club_cancel_request', {'p_club': clubId}));

  @override
  Future<void> leave(String clubId) =>
      _guard(() => _rpc('club_leave', {'p_club': clubId}));

  // ─── Members, roles and moderation ───────────────────────────────────────

  @override
  Future<List<ClubMember>> members(String clubId) => _guard(() async {
    final rows = await _list('club_member_list', {'p_club': clubId});
    return [
      for (final r in rows)
        ClubMember(
          player: PlayerSummary.fromRow(r),
          rating: _num(r['rating']),
          roleIds: [for (final id in r['role_ids'] as List) id as String],
          joinedAt: r['joined_at'] == null ? null : _at(r['joined_at']),
          meetsPlayed: _int(r['meets_played']),
          noShows: _int(r['no_shows']),
        ),
    ];
  });

  @override
  Future<List<ClubRole>> roles(String clubId) => _guard(() async {
    final rows = await _list('club_role_list', {'p_club': clubId});
    return rows.map(_role).toList();
  });

  @override
  Future<void> setMemberRole(String clubId, String userId, String? roleId) =>
      _guard(
        () => _rpc('club_set_member_role', {
          'p_club': clubId,
          'p_user': userId,
          'p_role': roleId,
        }),
      );

  @override
  Future<void> removeMember(String clubId, String userId) => _guard(
    () => _rpc('club_remove_member', {'p_club': clubId, 'p_user': userId}),
  );

  @override
  Future<void> banMember(String clubId, String userId, String reason) => _guard(
    () => _rpc('club_ban', {
      'p_club': clubId,
      'p_user': userId,
      'p_reason': reason,
    }),
  );

  @override
  Future<List<ClubBan>> bans(String clubId) => _guard(() async {
    final rows = await _list('club_ban_list', {'p_club': clubId});
    return [
      for (final r in rows)
        ClubBan(
          player: _player(r['player']),
          bannedBy: r['banned_by'] as String,
          at: _at(r['at']),
          reason: r['reason'] as String? ?? '',
        ),
    ];
  });

  @override
  Future<void> unban(String clubId, String userId) =>
      _guard(() => _rpc('club_unban', {'p_club': clubId, 'p_user': userId}));

  @override
  Future<List<JoinRequest>> requests(String clubId) => _guard(() async {
    final rows = await _list('club_request_list', {'p_club': clubId});
    final club = await this.club(clubId);
    return [
      for (final r in rows)
        () {
          final rating = _num(r['rating']);
          return JoinRequest(
            id: r['id'] as String,
            player: _player(r['player']),
            createdAt: _at(r['created_at']),
            rating: rating,
            sessions: _int(r['sessions']),
            mutual: _int(r['mutual']),
            provisional: _int(r['sessions']) < 5,
            belowRange:
                rating != null &&
                SkillBand.forLevel(rating).index < club.primaryRange.min,
            message: r['message'] as String? ?? '',
            status: RequestStatus.values.byName(r['status'] as String),
          );
        }(),
    ];
  });

  @override
  Future<void> decideRequest(
    String clubId,
    String requestId,
    RequestStatus status,
  ) => _guard(
    () => _rpc('club_decide_request', {
      'p_request': requestId,
      'p_status': status.name,
    }),
  );

  @override
  Future<List<AuditEntry>> audit(String clubId) => _guard(() async {
    final rows = await _list('club_audit_list', {'p_club': clubId});
    return [
      for (final r in rows)
        AuditEntry(
          id: '${r['id']}',
          category: AuditCategory.fromId(r['category'] as String),
          actor: r['actor'] as String,
          action: r['action'] as String,
          detail: r['detail'] as String? ?? '',
          at: _at(r['at']),
        ),
    ];
  });

  @override
  Future<ClubRole> createRole(
    String clubId, {
    required String name,
    required int color,
    required RoleLevel level,
    required Set<String> members,
  }) => _guard(() async {
    final id = await _rpc('club_role_create', {
      'p_club': clubId,
      'p_name': name,
      'p_color': color,
      'p_level': level.name,
      'p_members': members.toList(),
    }) as String;
    final all = await roles(clubId);
    return all.firstWhere((r) => r.id == id);
  });

  @override
  Future<void> updateRole(String clubId, ClubRole role) => _guard(
    () => _rpc('club_role_update', {
      'p_role': role.id,
      'p_name': role.name,
      'p_color': role.color,
      'p_level': role.level.name,
      'p_permissions': [for (final p in role.permissions) p.id],
      'p_show_badge': role.showBadge,
    }),
  );

  @override
  Future<void> deleteRole(String clubId, String roleId) =>
      _guard(() => _rpc('club_role_delete', {'p_role': roleId}));

  @override
  Future<void> reorderRoles(String clubId, List<String> roleIds) => _guard(
    () => _rpc('club_role_reorder', {'p_club': clubId, 'p_ids': roleIds}),
  );

  @override
  Future<void> setRoleMembers(String clubId, String roleId, Set<String> ids) =>
      _guard(
        () => _rpc('club_role_set_members', {
          'p_role': roleId,
          'p_ids': ids.toList(),
        }),
      );

  // ─── Announcements and chat ──────────────────────────────────────────────

  @override
  Future<List<Announcement>> announcements(String clubId) => _guard(() async {
    final rows = await _list('club_announcement_list', {'p_club': clubId});
    return [
      for (final r in rows)
        Announcement(
          id: r['id'] as String,
          author: r['author'] as String,
          authorRole: r['author_role'] as String,
          title: r['title'] as String,
          body: r['body'] as String? ?? '',
          pinned: r['pinned'] as bool? ?? false,
          at: _at(r['at']),
        ),
    ];
  });

  @override
  Future<void> announce(
    String clubId, {
    required String title,
    required String body,
    required String audience,
    required bool pinned,
  }) => _guard(
    () => _rpc('club_announce', {
      'p_club': clubId,
      'p_title': title,
      'p_body': body,
      'p_audience': audience,
      'p_pinned': pinned,
    }),
  );

  @override
  Stream<List<GroupMessage>> chat(ChatScope scope) {
    // Opening the chat marks it read.
    _rpc(scope.isTeam ? 'team_chat_read' : 'club_chat_read', {
      scope.isTeam ? 'p_team' : 'p_club': scope.id,
    }).catchError((Object _) {});
    final people = <String, PlayerSummary>{};
    final meets = <String, SharedMeet>{};
    // Private photo paths and their short-lived links.
    final photos = <String, String>{};
    Map<String, (String, int)>? badges;

    Future<Map<String, (String, int)>> roleBadges() async {
      if (scope.isTeam) return const {};
      final roles = {for (final r in await this.roles(scope.id)) r.id: r};
      final out = <String, (String, int)>{};
      for (final m in await members(scope.id)) {
        final shown =
            m.roleIds
                .map((id) => roles[id])
                .whereType<ClubRole>()
                .where((r) => r.showBadge && !r.isLabel)
                .toList()
              ..sort((a, b) => a.position.compareTo(b.position));
        if (shown.isNotEmpty) {
          out[m.player.id] = (shown.first.name, shown.first.color);
        }
      }
      return out;
    }

    return _client
        .from('group_messages')
        .stream(primaryKey: ['id'])
        .eq(scope.isTeam ? 'team_id' : 'club_id', scope.id)
        .order('created_at')
        .asyncMap((rows) async {
          final missing = {for (final r in rows) r['sender_id'] as String}
              .difference(people.keys.toSet());
          if (missing.isNotEmpty) {
            final found = await _client
                .from('profiles')
                .select('id, username, full_name, avatar_url')
                .inFilter('id', missing.toList());
            for (final p in found) {
              people[p['id'] as String] = PlayerSummary.fromRow(p);
            }
          }
          final meetIds = {
            for (final r in rows)
              if (r['activity_id'] != null) r['activity_id'] as String,
          }.difference(meets.keys.toSet());
          for (final id in meetIds) {
            try {
              final a = await _play.activity(id);
              meets[id] = SharedMeet(
                activityId: a.id,
                title: a.title,
                startsAt: a.startsAt,
                detail: '${a.levelRange} · ${a.spotsTaken} of ${a.capacity}',
              );
            } on AuthFailure {
              // A cancelled or hidden Meet shows as plain text.
            }
          }
          try {
            badges ??= await roleBadges();
          } on AuthFailure {
            badges = const {};
          }
          final paths = {
            for (final r in rows)
              if (r['photo_url'] case final String p when !p.startsWith('http'))
                p,
          }.difference(photos.keys.toSet());
          if (paths.isNotEmpty) {
            try {
              final signed = await _client.storage
                  .from('chat-photos')
                  .createSignedUrlsResult(paths.toList(), 60 * 60 * 12);
              for (final s in signed.whereType<SignedUrlSuccess>()) {
                photos[s.path] = s.signedUrl;
              }
            } on StorageException {
              // Shown as a removed photo until the next update.
            }
          }
          return [
            for (final r in rows)
              () {
                final sender = r['sender_id'] as String;
                final badge = badges![sender];
                final removedBy = r['removed_by'] as String?;
                return GroupMessage(
                  id: r['id'] as String,
                  sender: people[sender] ?? PlayerSummary(id: sender),
                  body: r['body'] as String? ?? '',
                  kind: MessageKind.values.byName(r['kind'] as String),
                  roleName: badge?.$1,
                  roleColor: badge?.$2,
                  meet: meets[r['activity_id']],
                  photo: switch (r['photo_url'] as String?) {
                    final String p when p.startsWith('http') => p,
                    final String p => photos[p],
                    null => null,
                  },
                  removed: r['removed'] as bool? ?? false,
                  removedBy: removedBy == null
                      ? null
                      : people[removedBy]?.displayName,
                  at: _at(r['created_at']),
                );
              }(),
          ];
        });
  }

  Map<String, dynamic> _scope(ChatScope scope) => {
    scope.isTeam ? 'team_id' : 'club_id': scope.id,
    'sender_id': _me,
  };

  @override
  Future<void> send(ChatScope scope, String body, {String? activityId}) =>
      _guard(
        () => _client.from('group_messages').insert({
          ..._scope(scope),
          'kind': activityId == null ? 'text' : 'meet',
          'body': body,
          'activity_id': ?activityId,
        }),
      );

  @override
  Future<void> sendPhoto(ChatScope scope, String filePath) => _guard(() async {
    final ext = filePath.split('.').last.toLowerCase();
    // Private to the club or team: club/<id>/<sender>/<file>.
    final path =
        '${scope.isTeam ? 'team' : 'club'}/${scope.id}/$_me/'
        '${DateTime.now().microsecondsSinceEpoch}.${ext.length <= 4 ? ext : 'jpg'}';
    await _client.storage.from('chat-photos').upload(path, File(filePath));
    await _client.from('group_messages').insert({
      ..._scope(scope),
      'kind': 'photo',
      'photo_url': path,
    });
  });

  @override
  Future<void> removeMessage(ChatScope scope, String messageId, bool removed) =>
      _guard(
        () => _rpc('group_message_set_removed', {
          'p_id': messageId,
          'p_removed': removed,
        }),
      );

  @override
  Future<void> report(ReportTarget target, ContentReport reason, String note) =>
      _guard(
        () => _client.from('content_reports').insert({
          'target_kind':
              target.video ??
              (target.isActivity
                  ? 'activity'
                  : target.isClub
                  ? 'club'
                  : 'message'),
          'target_id': target.id,
          'reason': reason.id,
          'note': note,
        }),
      );

  // ─── Club info and settings ──────────────────────────────────────────────

  @override
  Future<ClubLeaderboard> leaderboard(String clubId, ClubSport sport) =>
      _guard(() async {
        final rows = await _list('club_leaderboard', {
          'p_club': clubId,
          'p_sport': sport.id,
        });
        final entries = [
          for (final r in rows)
            LeaderboardEntry(
              player: _player(r['player']),
              score: (r['level'] as num).toStringAsFixed(1),
              sub: '${_int(r['meets'])} club Meets',
            ),
        ];
        final mine = entries.indexWhere((e) => e.player.id == _me);
        return ClubLeaderboard(
          period: 'Current ratings',
          rows: entries,
          me: mine < 0 ? null : entries[mine],
          myRank: mine < 0 ? null : mine + 1,
          myNote: mine < 0
              ? 'Add ${sport.label} to your Passport to be ranked.'
              : '',
        );
      });

  @override
  Future<ClubReward> reward(String clubId) => _guard(() async {
    final now = DateTime.now();
    final played = await _play.forClub(
      clubId,
      from: DateTime(now.year, now.month),
    );
    return ClubReward(
      meets: [
        for (final a in played)
          if (a.kind == ActivityKind.meet && a.startsAt.isBefore(now))
            RewardMeet(
              title: a.title,
              at: a.startsAt,
              paidPresent: a.spotsTaken,
            ),
      ],
    );
  });

  @override
  Future<void> updateClub(Club club) => _guard(
    () => _rpc('club_update', {
      'p_club': club.id,
      'p': {
        'name': club.name,
        'description': club.description,
        'rules': club.rules,
        'area': club.area,
        'home_venue': club.homeVenue,
        ..._sports(club.sports),
        'visibility': club.visibility.id,
        'join_mode': club.joinMode.id,
        'play_rules': club.playRules,
        'logo_color': club.logoColor,
        'logo_ink': club.logoInk,
        'cover_color': club.coverColor,
      },
    }),
  );

  @override
  Future<void> rateClub(String clubId, int stars, String review) => _guard(
    () => _rpc('club_rate', {
      'p_club': clubId,
      'p_stars': stars,
      'p_review': review,
    }),
  );

  @override
  Future<void> transfer(String clubId, String toUserId) =>
      _guard(() => _rpc('club_transfer', {'p_club': clubId, 'p_to': toUserId}));

  @override
  Future<void> deleteClub(String clubId) =>
      _guard(() => _rpc('club_delete', {'p_club': clubId}));

  @override
  Future<String> createClub(ClubDraft draft) => _guard(() async {
    final id = await _rpc('club_create', {
      'p': {
        'name': draft.name,
        'description': draft.description,
        'area': draft.area,
        'venue_id': draft.venueId,
        'venue_name': draft.venueName,
        'visibility': draft.visibility.id,
        'join_mode': draft.joinMode.id,
        ..._sports([
          for (final s in draft.sports)
            ClubSportLevel(
              sport: s,
              range: draft.ranges[s] ?? const LevelRange.all(),
            ),
        ]),
      },
    }) as String;
    if (draft.invite.isNotEmpty) await invite(id, draft.invite);
    return id;
  });

  @override
  Future<List<InviteCandidate>> inviteCandidates() => _guard(() async {
    final rows = await _list('club_invite_candidates');
    return [
      for (final r in rows)
        InviteCandidate(
          player: PlayerSummary.fromRow(r),
          rating: _num(r['rating']),
          meetsTogether: _int(r['meets_together']),
        ),
    ];
  });

  @override
  Future<void> invite(String clubId, Set<String> userIds) => _guard(
    () => _rpc('club_invite', {'p_club': clubId, 'p_ids': userIds.toList()}),
  );

  // ─── Teams ───────────────────────────────────────────────────────────────

  @override
  Future<Team> team(String id) => _guard(() async {
    final j = await _rpc('team_get', {'p_team': id});
    if (j == null) throw const AuthFailure('This team no longer exists.');
    return _team(Map<String, dynamic>.from(j as Map));
  });

  Future<List<Map<String, dynamic>>> _fixtures(String teamId) =>
      _list('team_fixture_list', {'p_team': teamId});

  @override
  Future<List<TeamSession>> teamSessions(String teamId) => _guard(() async {
    final now = DateTime.now();
    return [
      for (final f in await _fixtures(teamId))
        if (!_at(f['starts_at']).isBefore(now))
          TeamSession(
            id: f['id'] as String,
            title: 'vs ${f['opponent']}',
            startsAt: _at(f['starts_at']),
            venue: f['venue'] as String? ?? '',
            fixture: true,
            attending: _int(f['attending']),
            squad: _int(f['squad']),
          ),
    ];
  });

  @override
  Future<List<TeamResult>> teamResults(String teamId) => _guard(() async {
    return [
      for (final f in (await _fixtures(teamId)).reversed)
        if (f['score'] != null && f['won'] != null)
          TeamResult(
            opponent: f['opponent'] as String,
            at: _at(f['starts_at']),
            competition: f['competition'] as String? ?? '',
            won: f['won'] as bool,
            score: f['score'] as String,
          ),
    ];
  });

  @override
  Future<List<TeamMember>> teamMembers(String teamId) => _guard(() async {
    final rows = await _list('team_member_list', {'p_team': teamId});
    return [
      for (final r in rows)
        TeamMember(
          player: PlayerSummary.fromRow(r),
          rating: _num(r['rating']),
          club: r['club'] as String? ?? '',
          captain: r['captain'] as String?,
          availability: _availability(r['availability']),
          reserve: r['reserve'] as bool? ?? false,
          staff: r['staff'] as bool? ?? false,
          staffTitle: r['staff_title'] as String? ?? '',
        ),
    ];
  });

  @override
  Future<String?> nextFixtureId(String teamId) async =>
      (await teamSessions(teamId)).firstOrNull?.id;

  @override
  Future<Fixture> fixture(String fixtureId) => _guard(() async {
    final j = Map<String, dynamic>.from(
      await _rpc('team_fixture_get', {'p_fixture': fixtureId}) as Map,
    );
    return Fixture(
      id: j['id'] as String,
      teamId: j['team_id'] as String,
      teamName: j['team_name'] as String,
      opponent: j['opponent'] as String,
      startsAt: _at(j['starts_at']),
      competition: j['competition'] as String? ?? '',
      venue: j['venue'] as String? ?? '',
      lineupLocksAt: j['lineup_locks_at'] == null
          ? null
          : _at(j['lineup_locks_at']),
      notes: [for (final n in j['notes'] as List? ?? const []) n as String],
      setBy: j['set_by'] as String? ?? '',
      myAvailability: _availability(j['my_availability']),
      slots: lineupSlotsFor(
        ClubSport.values.firstWhere(
          (s) => s.id == j['sport'],
          orElse: () => ClubSport.badminton,
        ),
      ),
      lineup: {
        for (final e in (j['lineup'] as Map? ?? const {}).entries)
          '${e.key}': [for (final p in e.value as List) p as String?],
      },
      published: j['published'] as bool? ?? false,
    );
  });

  @override
  Future<String> createFixture(
    String teamId, {
    required String opponent,
    required DateTime startsAt,
    String competition = '',
    String venue = '',
    DateTime? lineupLocksAt,
    List<String> notes = const [],
  }) => _guard(
    () async => await _rpc('team_fixture_create', {
      'p_team': teamId,
      'p_opponent': opponent,
      'p_starts_at': startsAt.toUtc().toIso8601String(),
      'p_competition': competition,
      'p_venue': venue,
      'p_locks_at': lineupLocksAt?.toUtc().toIso8601String(),
      'p_notes': notes,
    }) as String,
  );

  @override
  Future<void> recordResult(
    String fixtureId, {
    required String score,
    required bool won,
  }) => _guard(
    () => _rpc('team_fixture_result', {
      'p_fixture': fixtureId,
      'p_score': score,
      'p_won': won,
    }),
  );

  @override
  Future<void> setAvailability(String fixtureId, Availability availability) =>
      _guard(
        () => _rpc('team_set_availability', {
          'p_fixture': fixtureId,
          'p_value': availability.id,
        }),
      );

  @override
  Future<void> saveLineup(
    String fixtureId,
    Map<String, List<String?>> lineup, {
    required bool publish,
  }) => _guard(
    () => _rpc('team_save_lineup', {
      'p_fixture': fixtureId,
      'p_lineup': lineup,
      'p_publish': publish,
    }),
  );

  @override
  Future<List<InviteCandidate>> teamCandidates(String teamId) =>
      _guard(() async {
        final rows = await _list('team_candidates', {'p_team': teamId});
        return [
          for (final r in rows)
            InviteCandidate(
              player: PlayerSummary.fromRow(r),
              rating: _num(r['rating']),
              club: r['club'] as String? ?? '',
            ),
        ];
      });

  @override
  Future<void> addTeamPlayers(String teamId, Set<String> userIds) => _guard(
    () =>
        _rpc('team_add_players', {'p_team': teamId, 'p_ids': userIds.toList()}),
  );

  @override
  Future<String> createTeam(TeamDraft draft) => _guard(() async {
    const rules = {
      'Under 13': 'Born 2014 or later',
      'Under 15': 'Born 2012 or later',
      'Under 17': 'Born 2010 or later',
      'Open': 'Any age',
    };
    return await _rpc('team_create', {
      'p': {
        'name': draft.name,
        'represents': draft.represents,
        'sport': draft.sport.id,
        'season': 'Season ${DateTime.now().year}',
        'sub_teams': [
          for (final e in rules.entries)
            {
              'name': e.key,
              'rule': e.value,
              'enabled': draft.subTeams.contains(e.key),
            },
          if (draft.ownSubTeam?.trim().isNotEmpty ?? false)
            {'name': draft.ownSubTeam!.trim(), 'rule': '', 'enabled': true},
        ],
        'players': draft.players.toList(),
      },
    }) as String;
  });

  @override
  Future<void> updateTeam(Team team) => _guard(
    () => _rpc('team_update', {
      'p_team': team.id,
      'p': {
        'name': team.name,
        'represents': team.represents,
        'season': team.season,
        'sub_teams': [
          for (final s in team.subTeams)
            {'name': s.name, 'rule': s.rule, 'enabled': s.enabled},
        ],
        'logo_color': team.logoColor,
        'logo_ink': team.logoInk,
      },
    }),
  );

  @override
  Future<void> leaveTeam(String teamId) =>
      _guard(() => _rpc('team_leave', {'p_team': teamId}));

  @override
  Future<void> deleteTeam(String teamId) =>
      _guard(() => _rpc('team_delete', {'p_team': teamId}));
}
