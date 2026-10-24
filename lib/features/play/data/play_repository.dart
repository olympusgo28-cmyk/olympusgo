import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/demo/demo_world.dart';
import '../../auth/data/auth_repository.dart';
import '../../clubs/domain/club_sport.dart';
import '../../onboarding/domain/sport.dart';
import '../../social/domain/social_models.dart';
import '../domain/activity.dart';
import '../domain/meet_ops.dart';

/// Meets, tournaments and events: browsing, joining and hosting.
abstract interface class PlayRepository {
  Future<List<Activity>> browse({
    required ActivityKind kind,
    Sport? sport,
    PlayFilters filters,
  });
  Future<List<Activity>> upcoming({
    ActivityKind kind = ActivityKind.meet,
    int limit = 5,
  });
  Future<List<Activity>> search(String query);
  Future<Activity> activity(String id);
  Future<List<Activity>> mySchedule();
  Future<List<Activity>> hosting();
  Future<List<Venue>> venues(String query);

  /// Joins a free activity (paid ones go through the payment gateway).
  Future<MyStatus> join(String id, {String? guestName, double? guestLevel});
  Future<int> joinWaitlist(String id, {bool notify = true});

  /// Gives up a spot. Returns what is refunded, in cents: to the Wallet
  /// all of it, to a card the session fee only. 0 once it has started.
  Future<int> leave(String id, {bool toWallet = true});

  /// Checks in at the venue. Returns how many players are here.
  Future<int> checkIn(String id);

  Future<String> publish(ActivityDraft draft);

  /// Saves changes to one published activity (one date of a series).
  Future<void> update(String id, ActivityDraft draft);

  // Organizer tools.

  /// Who is going (the host first) and who is waiting, in order.
  Future<List<MeetPlayer>> players(String id);

  /// The host takes a spot (paying the platform fee) or gives it up and
  /// keeps organizing.
  Future<void> hostPlays(String id, {required bool playing});

  /// Club members who could be added as a walk-in.
  Future<List<MeetPlayer>> walkInCandidates(String id);
  Future<void> addWalkIn(String id, String playerId, {required bool cash});
  Future<void> saveAttendance(String id, Map<String, Attendance> marks);
  Future<CancelPreview> cancelPreview(String id);

  /// Cancels this Meet, or this and the later ones in its series, refunds
  /// everyone and sends them [message].
  Future<void> cancel(String id, {bool series = false, String message = ''});
  Future<MeetRecap> recap(String id);

  // Ranked scores.
  Future<MatchScore> score(String scoreId);
  Future<MatchScore> submitScore(
    String activityId, {
    required List<String> partners,
    required List<String> opponents,
    required List<(int, int)> games,
  });
  Future<MatchScore> answerScore(
    String scoreId, {
    required bool confirm,
    String? reason,
  });

  Future<List<PlaySportPref>> playSports();
  Future<void> savePlaySports(List<PlaySportPref> prefs);
}

class SupabasePlayRepository implements PlayRepository {
  SupabasePlayRepository(this._client);
  final SupabaseClient _client;

  String get _me {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthFailure('Log in again to continue.');
    return id;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      // Functions raise readable messages; pass those through.
      if (e.code == 'P0001' && e.message != 'payment_required') {
        throw AuthFailure(e.message);
      }
      if (e.message == 'payment_required') {
        throw const AuthFailure('This one has a fee. Pay to join.');
      }
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  Activity _fromRow(Map<String, dynamic> r) {
    final my = r['my_status'] as String?;
    return Activity(
      id: r['id'] as String,
      kind: ActivityKind.fromId(r['kind'] as String),
      title: r['title'] as String,
      description: r['description'] as String?,
      sports: [
        for (final s in (r['sports'] as List)) Sport.fromId(s as String),
      ],
      gameType: GameType.fromId(r['game_type'] as String?),
      format: ActivityFormat.fromId(r['format'] as String),
      levelMin: (r['level_min'] as num?)?.toDouble(),
      levelMax: (r['level_max'] as num?)?.toDouble(),
      startsAt: DateTime.parse(r['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(r['ends_at'] as String).toLocal(),
      venue: Venue(
        id: r['venue_id'] as String,
        name: r['venue_name'] as String,
        address: r['venue_address'] as String,
      ),
      capacity: r['capacity'] as int,
      spotsTaken: r['spots_taken'] as int,
      waitlistCount: r['waitlist_count'] as int,
      feeCents: r['fee_cents'] as int,
      allowGuests: r['allow_guests'] as bool,
      approvalRequired: r['approval_required'] as bool,
      registrationClosesAt: r['registration_closes_at'] == null
          ? null
          : DateTime.parse(r['registration_closes_at'] as String).toLocal(),
      host: PlayerSummary(
        id: r['host_id'] as String,
        fullName: r['host_name'] as String?,
      ),
      hostMeetCount: r['host_meet_count'] as int,
      myStatus: switch (my) {
        'joined' => MyStatus.joined,
        'waitlist' => MyStatus.waitlist,
        'requested' => MyStatus.requested,
        _ => MyStatus.none,
      },
      myWaitlistPosition: r['my_waitlist_position'] as int? ?? 0,
      iAmHost: r['host_id'] == _client.auth.currentUser?.id,
      hostPlaying:
          r['host_id'] != _client.auth.currentUser?.id || my == 'joined',
      playersPayFee: r['players_pay_fee'] as bool? ?? false,
      levelAsNumbers: r['level_numbers'] as bool? ?? false,
      minPlayers: r['min_players'] as int? ?? 0,
      divisionKeys: [...?(r['division_keys'] as List?)?.cast<String>()],
      linkedId: r['linked_id'] as String?,
      clubId: r['club_id'] as String?,
      ranked: r['ranked'] as bool? ?? false,
      recurrence: r['recurrence'] as String?,
      subtitle: r['subtitle'] as String?,
      coverTitle: r['cover_title'] as String?,
      coverColor: _hex(r['cover_color'] as String?) ?? 0xFF16181B,
      coverInk: _hex(r['cover_ink'] as String?) ?? 0xFFFFFFFF,
      tier: r['tier'] as String?,
      live: r['live'] as bool? ?? false,
      online: r['online'] as bool? ?? false,
      watching: r['watching'] as int? ?? 0,
      audience: r['audience'] as String?,
    );
  }

  /// 0xFFF2C14E → "#F2C14E".
  static String _toHex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  /// "#F2C14E" → 0xFFF2C14E.
  static int? _hex(String? s) => s == null || s.length != 7
      ? null
      : int.tryParse('FF${s.substring(1)}', radix: 16);

  PostgrestFilterBuilder<List<Map<String, dynamic>>> get _cards =>
      _client.from('activity_cards').select().eq('status', 'published');

  /// A club's published activities from [from] (default now), soonest first.
  Future<List<Activity>> forClub(String clubId, {DateTime? from}) => _guard(
    () async {
      final rows = await _cards
          .eq('club_id', clubId)
          .gte('starts_at', (from ?? DateTime.now()).toUtc().toIso8601String())
          .order('starts_at');
      return rows.map(_fromRow).toList();
    },
  );

  @override
  Future<List<Activity>> browse({
    required ActivityKind kind,
    Sport? sport,
    PlayFilters filters = const PlayFilters(),
  }) => _guard(() async {
    final now = DateTime.now();
    var q = _cards
        .eq('kind', kind.id)
        .gte('starts_at', now.toUtc().toIso8601String());
    if (sport != null) q = q.contains('sports', [sport.id]);
    final until = switch (filters.when) {
      'today' => DateTime(now.year, now.month, now.day + 1),
      'week' => now.add(const Duration(days: 7)),
      'weekend' => DateTime(now.year, now.month, now.day + (8 - now.weekday)),
      'month' => DateTime(now.year, now.month + 1, now.day),
      _ => null,
    };
    if (until != null) q = q.lt('starts_at', until.toUtc().toIso8601String());
    if (filters.gameType != null) q = q.eq('game_type', filters.gameType!.id);
    if (filters.format != null) q = q.eq('format', filters.format!.id);
    if (kind != ActivityKind.event) {
      q = q
          .lte('level_min', filters.levelMax)
          .gte('level_max', filters.levelMin);
    }
    q = switch (filters.fee) {
      'free' => q.eq('fee_cents', 0),
      'under10' => q.lt('fee_cents', 1000),
      'over10' => q.gte('fee_cents', 1000),
      'under30' => q.lt('fee_cents', 3000),
      '30to60' => q.gte('fee_cents', 3000).lte('fee_cents', 6000),
      'over60' => q.gt('fee_cents', 6000),
      'paid' => q.gt('fee_cents', 0),
      _ => q,
    };
    final rows = await q.order('starts_at').limit(50);
    return rows.map(_fromRow).toList();
  });

  @override
  Future<List<Activity>> upcoming({
    ActivityKind kind = ActivityKind.meet,
    int limit = 5,
  }) => _guard(() async {
    final rows = await _cards
        .eq('kind', kind.id)
        .gte('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at')
        .limit(limit);
    return rows.map(_fromRow).toList();
  });

  @override
  Future<List<Activity>> search(String query) => _guard(() async {
    final q = query.replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();
    if (q.isEmpty) return const [];
    final rows = await _cards
        .gte('starts_at', DateTime.now().toUtc().toIso8601String())
        .or('title.ilike.%$q%,venue_name.ilike.%$q%')
        .order('starts_at')
        .limit(20);
    return rows.map(_fromRow).toList();
  });

  @override
  Future<Activity> activity(String id) => _guard(() async {
    final row = await _client
        .from('activity_cards')
        .select()
        .eq('id', id)
        .single();
    final going = await _client
        .from('activity_participants')
        .select('user_id')
        .eq('activity_id', id)
        .eq('status', 'joined')
        .order('created_at')
        .limit(20);
    final ids = going.map((g) => g['user_id'] as String).toList();
    final people = ids.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _client
              .from('profiles')
              .select('id, username, full_name, avatar_url')
              .inFilter('id', ids);
    return _fromRow(row)
        .copyWith(going: people.map(PlayerSummary.fromRow).toList());
  });

  @override
  Future<List<Activity>> mySchedule() => _guard(() async {
    final mine = await _client
        .from('activity_participants')
        .select('activity_id')
        .eq('user_id', _me)
        .inFilter('status', ['joined', 'waitlist', 'requested']);
    final ids = mine.map((r) => r['activity_id'] as String).toList();
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('activity_cards')
        .select()
        .inFilter('id', ids)
        .gte('ends_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at');
    return rows.map(_fromRow).toList();
  });

  @override
  Future<List<Activity>> hosting() => _guard(() async {
    final rows = await _client
        .from('activity_cards')
        .select()
        .eq('host_id', _me)
        .gte('ends_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at');
    return rows.map(_fromRow).toList();
  });

  @override
  Future<List<Venue>> venues(String query) => _guard(() async {
    var q = _client.from('venues').select('id, name, address');
    final t = query.replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();
    if (t.isNotEmpty) q = q.ilike('name', '%$t%');
    final rows = await q.order('name').limit(30);
    return [
      for (final r in rows)
        Venue(
          id: r['id'] as String,
          name: r['name'] as String,
          address: r['address'] as String,
        ),
    ];
  });

  @override
  Future<MyStatus> join(String id, {String? guestName, double? guestLevel}) =>
      _guard(() async {
        final status = await _client.rpc(
          'join_activity',
          params: {'activity': id, 'guest': guestName, 'guest_lvl': guestLevel},
        );
        return status == 'requested' ? MyStatus.requested : MyStatus.joined;
      });

  @override
  Future<int> joinWaitlist(String id, {bool notify = true}) => _guard(() async {
    return await _client.rpc(
      'join_waitlist',
      params: {'activity': id, 'notify': notify},
    ) as int;
  });

  @override
  Future<int> leave(String id, {bool toWallet = true}) => _guard(
    () async => await _client.rpc(
      'leave_activity',
      params: {'activity': id, 'to_wallet': toWallet},
    ) as int,
  );

  MeetPlayer _player(Map<String, dynamic> r, {int? waitlistAt}) {
    final level = (r['level'] as num?)?.toDouble();
    return MeetPlayer(
      player: PlayerSummary(
        id: r['user_id'] as String,
        username: r['username'] as String?,
        fullName: r['full_name'] as String?,
        avatarUrl: r['avatar_url'] as String?,
      ),
      role: (r['is_host'] as bool? ?? false) ? 'Organizer' : 'Member',
      rating: level,
      band: level == null ? null : SkillBand.forLevel(level).code,
      sessions: r['sessions'] as int? ?? 0,
      waitlistAt: waitlistAt,
      attendance: Attendance.fromId(r['attendance'] as String?),
      isHost: r['is_host'] as bool? ?? false,
      walkIn: r['walk_in'] as bool? ?? false,
      paidCash: r['paid_cash'] as bool? ?? false,
      checkedInAt: r['checked_in_at'] == null
          ? null
          : DateTime.parse(r['checked_in_at'] as String).toLocal(),
    );
  }

  @override
  Future<List<MeetPlayer>> players(String id) => _guard(() async {
    final rows = (await _client.rpc(
      'meet_players',
      params: {'activity': id},
    ) as List).cast<Map<String, dynamic>>();
    final out = <MeetPlayer>[];
    var queue = 0;
    for (final r in rows) {
      final waiting = r['status'] == 'waitlist';
      final p = _player(r, waitlistAt: waiting ? ++queue : null);
      out.add(p);
      // A guest rides on the player who brought them.
      if (r['guest_name'] case final String guest when !waiting) {
        out.add(
          MeetPlayer(
            player: PlayerSummary(id: '${p.player.id}:guest', fullName: guest),
            guestOf: p.player.displayName,
            attendance: p.attendance,
          ),
        );
      }
    }
    return out;
  });

  @override
  Future<void> hostPlays(String id, {required bool playing}) async {
    try {
      await _guard(
        () => _client.rpc(
          'host_plays',
          params: {'activity': id, 'playing': playing},
        ),
      );
    } on AuthFailure catch (e) {
      // The organizer's platform fee is a card payment too.
      if (e.message.startsWith('This one has a fee')) {
        throw const AuthFailure(
          "Card payments aren't switched on yet, so you can't take a paid spot.",
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<MeetPlayer>> walkInCandidates(String id) => _guard(() async {
    final rows = await _client.rpc(
      'walk_in_candidates',
      params: {'activity': id},
    ) as List;
    return [for (final r in rows.cast<Map<String, dynamic>>()) _player(r)];
  });

  @override
  Future<void> addWalkIn(String id, String playerId, {required bool cash}) =>
      _guard(
        () => _client.rpc(
          'add_walk_in',
          params: {'activity': id, 'player': playerId, 'cash': cash},
        ),
      );

  @override
  Future<void> saveAttendance(String id, Map<String, Attendance> marks) =>
      _guard(
        () => _client.rpc(
          'save_attendance',
          params: {
            'activity': id,
            'marks': {
              // Guests are marked with the player who brought them.
              for (final e in marks.entries)
                if (!e.key.endsWith(':guest'))
                  e.key: e.value == Attendance.unmarked ? '' : e.value.id,
            },
          },
        ),
      );

  @override
  Future<CancelPreview> cancelPreview(String id) => _guard(() async {
    final r = await _client.rpc(
      'cancel_preview',
      params: {'activity': id},
    ) as Map<String, dynamic>?;
    if (r == null) throw const AuthFailure('Only the organizer can cancel.');
    return CancelPreview(
      players: r['players'] as int,
      eachCents: (r['each_cents'] as num).toInt(),
      cardPayments: r['card_payments'] as int,
      cardFeeCents: (r['card_fee_cents'] as num).toInt(),
      laterMeets: r['later_meets'] as int,
      lastMeet: r['last_meet'] == null
          ? null
          : DateTime.parse(r['last_meet'] as String).toLocal(),
    );
  });

  @override
  Future<void> cancel(String id, {bool series = false, String message = ''}) =>
      _guard(
        () => _client.rpc(
          'cancel_activity',
          params: {'activity': id, 'series': series, 'message': message},
        ),
      );

  @override
  Future<MeetRecap> recap(String id) => _guard(() async {
    // Points, ratings and partners come with the rating engine. Until then
    // the recap counts the confirmed scores this player was in.
    final me = _me;
    final rows =
        (await _client
                .from('match_scores')
                .select('side_a, side_b, games')
                .eq('activity_id', id)
                .eq('status', 'confirmed'))
            .cast<Map<String, dynamic>>();
    var wins = 0, losses = 0;
    String? best;
    var bestGap = -1;
    for (final r in rows) {
      final onA = (r['side_a'] as List).contains(me);
      if (!onA && !(r['side_b'] as List).contains(me)) continue;
      final games = [
        for (final g in (r['games'] as List).cast<List>())
          onA ? (g[0] as int, g[1] as int) : (g[1] as int, g[0] as int),
      ];
      final won = games.where((g) => g.$1 > g.$2).length >= 2;
      won ? wins++ : losses++;
      for (final g in games) {
        if (g.$1 > g.$2 && g.$1 - g.$2 > bestGap) {
          bestGap = g.$1 - g.$2;
          best = '${g.$1}–${g.$2}';
        }
      }
    }
    final sessions = await _client
        .from('activity_participants')
        .select('id')
        .eq('user_id', me)
        .eq('status', 'joined')
        .count(CountOption.exact);
    return MeetRecap(
      games: wins + losses,
      wins: wins,
      losses: losses,
      bestGame: best,
      points: 4,
      session: sessions.count,
    );
  });

  @override
  Future<MatchScore> score(String scoreId) => _guard(() async {
    final r = await _client
        .from('match_scores')
        .select('*, activities(title, host_id)')
        .eq('id', scoreId)
        .single();
    final ids = <String>{
      ...(r['side_a'] as List).cast<String>(),
      ...(r['side_b'] as List).cast<String>(),
      (r['activities'] as Map)['host_id'] as String,
    };
    final people = {
      for (final p
          in await _client
              .from('profiles')
              .select('id, username, full_name, avatar_url')
              .inFilter('id', ids.toList()))
        p['id'] as String: PlayerSummary.fromRow(p),
    };
    PlayerSummary who(String id) => people[id] ?? PlayerSummary(id: id);
    return MatchScore(
      id: r['id'] as String,
      activityId: r['activity_id'] as String,
      activityTitle: (r['activities'] as Map)['title'] as String,
      sideA: [for (final id in (r['side_a'] as List).cast<String>()) who(id)],
      sideB: [for (final id in (r['side_b'] as List).cast<String>()) who(id)],
      games: [
        for (final g in (r['games'] as List).cast<List>())
          (g[0] as int, g[1] as int),
      ],
      enteredBy: who(r['entered_by'] as String),
      enteredAt: DateTime.parse(r['created_at'] as String).toLocal(),
      status: ScoreStatus.fromId(r['status'] as String?),
      reason: r['reason'] as String?,
      organizer: who((r['activities'] as Map)['host_id'] as String),
    );
  });

  @override
  Future<MatchScore> submitScore(
    String activityId, {
    required List<String> partners,
    required List<String> opponents,
    required List<(int, int)> games,
  }) => _guard(() async {
    final id = await _client.rpc(
      'submit_score',
      params: {
        'activity': activityId,
        'partners': partners,
        'opponents': opponents,
        'games': [
          for (final g in games) [g.$1, g.$2],
        ],
      },
    ) as String;
    return score(id);
  });

  @override
  Future<MatchScore> answerScore(
    String scoreId, {
    required bool confirm,
    String? reason,
  }) => _guard(() async {
    await _client.rpc(
      'answer_score',
      params: {'score': scoreId, 'ok': confirm, 'why': reason},
    );
    return score(scoreId);
  });

  @override
  Future<int> checkIn(String id) => _guard(
    () async => await _client.rpc('check_in', params: {'activity': id}) as int,
  );

  /// The activities row for [d] starting at [starts].
  Map<String, dynamic> _row(ActivityDraft d, DateTime starts) {
    final meet = d.kind == ActivityKind.meet;
    final levels = d.kind != ActivityKind.event && (!meet || d.restrictLevel);
    final ends = switch (d.kind) {
      ActivityKind.tournament => DateTime(
        d.endDate!.year,
        d.endDate!.month,
        d.endDate!.day,
        23,
        59,
      ),
      ActivityKind.event => starts.add(const Duration(hours: 6)),
      ActivityKind.meet => starts.add(Duration(minutes: d.durationMinutes)),
    };
    return {
      'kind': d.kind.id,
      'host_id': _me,
      'club_id': d.clubId,
      if (d.coverTitle != null) ...{
        'cover_title': d.coverTitle,
        'cover_color': _toHex(d.coverColor),
        'cover_ink': _toHex(bannerInk(d.coverColor)),
      },
      'title': d.title.trim(),
      'description': d.description.trim().isEmpty ? null : d.description.trim(),
      'sports': d.sports.map((s) => s.id).toList(),
      'game_type': d.kind == ActivityKind.event ? null : d.gameType?.id,
      'format': d.format!.id,
      'level_min': levels ? d.levelMin : null,
      'level_max': levels ? d.levelMax : null,
      'starts_at': starts.toUtc().toIso8601String(),
      'ends_at': ends.toUtc().toIso8601String(),
      'venue_id': d.venue!.id,
      'capacity': d.capacity,
      'courts': d.kind == ActivityKind.event ? null : d.courts,
      'fee_cents': d.chargeFee ? d.feeCents : 0,
      'approval_required': d.approvalRequired,
      'allow_guests': d.allowGuests,
      'scoring': d.kind == ActivityKind.tournament ? d.scoring : null,
      'seed_by_level': d.kind == ActivityKind.tournament ? d.seedByLevel : null,
      'umpire_scores': d.kind == ActivityKind.tournament
          ? d.umpireScores
          : null,
      'allow_refunds': d.allowRefunds,
      'registration_closes_at': d.registrationCloses?.toUtc().toIso8601String(),
      if (d.kind == ActivityKind.tournament) ...{
        'tier': d.tier,
        'division_keys': d.teamEntry ? <String>[] : d.divisionKeys,
        'age_divisions': d.ageDivisions,
        'team_entry': d.teamEntry,
        'min_players': d.minEntries,
        'verified_only': d.verifiedOnly,
        'match_check_in': d.matchCheckIn,
        'waitlist_when_full': d.waitlistWhenFull,
        'public_listing': d.listPublicly,
        'linked_id': d.linkedId,
      },
      if (d.kind == ActivityKind.event) ...{
        'online': d.online,
        'linked_id': d.linkedId,
      },
      if (meet) ...{
        'ranked': d.ranked,
        'recurrence': d.recurrenceLabel,
        'min_players': d.minPlayers,
        'players_pay_fee': !d.chargeFee && d.playersPayFee,
        'level_numbers': d.levelAsNumbers,
        'host_invites_only': d.hostInvitesOnly,
        'public_listing': d.listPublicly,
      },
    };
  }

  @override
  Future<String> publish(ActivityDraft d) => _guard(() async {
    final meet = d.kind == ActivityKind.meet;
    Map<String, dynamic> row(DateTime starts) => _row(d, starts);

    final dates = meet ? d.occurrences : [d.startsAt!];
    final ids = [
      for (final r
          in await _client
              .from('activities')
              .insert([for (final at in dates) row(at)])
              .select('id'))
        r['id'] as String,
    ];
    // A repeating Meet is one series, so it can be cancelled together.
    if (ids.length > 1) {
      await _client
          .from('activities')
          .update({'series_id': ids.first})
          .inFilter('id', ids);
    }
    return ids.first;
  });

  @override
  Future<void> update(String id, ActivityDraft d) => _guard(() async {
    // Who hosts it and what kind it is stay as they were.
    final row = _row(d, d.startsAt!)
      ..remove('kind')
      ..remove('host_id')
      ..remove('club_id')
      ..remove('recurrence');
    await _client.from('activities').update(row).eq('id', id);
  });

  @override
  Future<List<PlaySportPref>> playSports() => _guard(() async {
    final rows = await _client
        .from('play_preferences')
        .select()
        .eq('user_id', _me)
        .order('position');
    return [
      for (final r in rows)
        PlaySportPref(
          sport: Sport.fromId(r['sport'] as String),
          gameType: GameType.fromId(r['game_type'] as String?),
          levelMin: (r['level_min'] as num).toDouble(),
          levelMax: (r['level_max'] as num).toDouble(),
        ),
    ];
  });

  @override
  Future<void> savePlaySports(List<PlaySportPref> prefs) => _guard(() async {
    await _client.from('play_preferences').delete().eq('user_id', _me);
    if (prefs.isEmpty) return;
    await _client.from('play_preferences').insert([
      for (final (i, p) in prefs.indexed)
        {
          'user_id': _me,
          'sport': p.sport.id,
          'game_type': p.gameType?.id,
          'level_min': p.levelMin,
          'level_max': p.levelMax,
          'position': i,
        },
    ]);
  });
}

/// The design's sample Meets, tournaments and events for demo mode.
class DemoPlayRepository implements PlayRepository {
  DemoPlayRepository() {
    _seed();
  }

  final _w = DemoWorld.instance;
  final _items = <Activity>[];
  List<PlaySportPref> _prefs = const [
    PlaySportPref(
      sport: Sport.badminton,
      gameType: GameType.doubles,
      levelMin: 3,
      levelMax: 5,
    ),
    PlaySportPref(sport: Sport.pickleball),
  ];

  static const _venues = [
    Venue(
      id: 'v-tampines',
      name: 'Our Tampines Hub',
      address: '1 Tampines Walk, Tampines',
      distance: '1.2 km',
    ),
    Venue(
      id: 'v-bedok',
      name: 'Bedok Sports Hall',
      address: '1 Bedok North St 2, Bedok',
      distance: '3.4 km',
    ),
    Venue(
      id: 'v-pasirris',
      name: 'Pasir Ris Sports Centre',
      address: '120 Pasir Ris Central, Pasir Ris',
      distance: '4.1 km',
    ),
    Venue(
      id: 'v-eastcoast',
      name: 'East Coast Park, Area C',
      address: 'East Coast Park Service Rd, Bedok',
      distance: '6.0 km',
    ),
  ];

  /// The next [weekday] at [hour], today included when it is still ahead.
  DateTime _next(int weekday, int hour, [int minute = 0, int weeks = 0]) {
    final now = DateTime.now();
    var days = (weekday - now.weekday) % 7;
    var d = DateTime(now.year, now.month, now.day + days, hour, minute);
    if (d.isBefore(now)) d = d.add(const Duration(days: 7));
    return d.add(Duration(days: 7 * weeks));
  }

  /// [days] from today at [hour].
  DateTime _in(int days, int hour, [int minute = 0]) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + days, hour, minute);
  }

  void _seed() {
    final hannah =
        _w.players['cp-hannah'] ??
        const PlayerSummary(
          id: 'cp-hannah',
          username: 'hannahgoh',
          fullName: 'Hannah Goh',
        );
    final going = [
      for (final id in ['cp-hannah', 'cp-priyar', 'cp-sitil', 'cp-mei'])
        _w.players[id]!,
    ];
    const priya = SocialProof(
      mark: 'PR',
      color: 0xFF3E6B8A,
      name: 'Priya Raman',
      text: 'and 2 friends are going',
      playerId: 'cp-priyar',
    );
    Activity meet({
      required String id,
      required String title,
      required DateTime starts,
      int minutes = 120,
      required int venue,
      required double min,
      required double max,
      required int cap,
      required int taken,
      int fee = 0,
      List<Sport> sports = const [Sport.badminton],
      GameType game = GameType.doubles,
      bool ranked = false,
      int men = 0,
      int women = 0,
      String? recurrence,
      SocialProof? proof,
      MyStatus my = MyStatus.none,
      String? clubId,
      int waitlist = 0,
      PlayerSummary? host,
    }) => Activity(
      id: id,
      kind: ActivityKind.meet,
      title: title,
      sports: sports,
      gameType: game,
      format: ActivityFormat.roundRobin,
      levelMin: min,
      levelMax: max,
      startsAt: starts,
      endsAt: starts.add(Duration(minutes: minutes)),
      venue: _venues[venue],
      court: 'Courts 3 – 5',
      capacity: cap,
      spotsTaken: taken,
      waitlistCount: waitlist,
      feeCents: fee,
      allowGuests: true,
      host: host ?? hannah,
      hostMeetCount: 124,
      myStatus: my,
      going: going,
      clubId: clubId,
      ranked: ranked,
      men: men,
      women: women,
      recurrence: recurrence,
      proof: proof,
      description: 'Rotating doubles for intermediate players. Shuttles provided, bring your own racket.',
    );

    _items.addAll([
      meet(
        id: 'ts-social',
        title: 'Doubles Social',
        starts: _next(DateTime.friday, 20),
        venue: 0,
        min: 4,
        max: 6.9,
        cap: 12,
        taken: 8,
        fee: 600,
        ranked: true,
        men: 5,
        women: 3,
        recurrence: 'Every Tue and Fri',
        proof: priya,
        my: MyStatus.joined,
        clubId: 'c-ts',
      ),
      meet(
        id: 'ts-singles',
        title: 'Morning Singles',
        starts: _next(DateTime.saturday, 9),
        venue: 0,
        min: 5,
        max: 6.9,
        cap: 6,
        taken: 3,
        fee: 600,
        game: GameType.singles,
        men: 2,
        women: 1,
        proof: const SocialProof(
          mark: 'MW',
          color: 0xFF2F3A5F,
          name: 'Mei Wong',
          text: 'is going',
          playerId: 'cp-mei',
        ),
        clubId: 'c-ts',
      ),
      meet(
        id: 'ts-rotation',
        title: 'Beginner Rotation',
        starts: _next(DateTime.tuesday, 19),
        venue: 0,
        min: 3,
        max: 4.9,
        cap: 16,
        taken: 1,
        men: 1,
        recurrence: 'Every Tuesday',
        clubId: 'c-ts',
      ),
      meet(
        id: 'bd-friday',
        title: 'Friday Night Doubles',
        starts: _next(DateTime.friday, 20, 0, 1),
        venue: 1,
        min: 5,
        max: 7.9,
        cap: 12,
        taken: 12,
        fee: 800,
        ranked: true,
        men: 8,
        women: 4,
      ),
      meet(
        id: 'pr-dinks',
        title: 'Weekend Dinks',
        starts: _next(DateTime.sunday, 9),
        venue: 2,
        min: 2,
        max: 4.9,
        cap: 12,
        taken: 7,
        fee: 400,
        sports: const [Sport.pickleball],
        game: GameType.mixed,
        men: 4,
        women: 3,
        recurrence: 'Every Sunday',
      ),
      Activity(
        id: 't-open',
        kind: ActivityKind.tournament,
        title: 'Tampines Open 2026',
        sports: const [Sport.badminton],
        gameType: GameType.doubles,
        format: ActivityFormat.groupsKnockout,
        levelMin: 2,
        levelMax: 7.9,
        startsAt: _next(DateTime.saturday, 9, 0, 1),
        endsAt: _next(DateTime.sunday, 18, 0, 1),
        registrationClosesAt: _next(DateTime.sunday, 23, 45),
        venue: _venues[0],
        capacity: 96,
        spotsTaken: 66,
        feeCents: 1500,
        host: hannah,
        hostMeetCount: 124,
        myStatus: MyStatus.joined,
        going: going,
        coverTitle: 'Tampines Open',
        coverColor: 0xFF16181B,
        coverInk: 0xFFF2C14E,
        tier: 'Regional',
        proof: const SocialProof(
          mark: 'SK',
          color: 0xFF0E6B4E,
          name: 'Siti Kamal',
          text: "registered for Women's singles",
          playerId: 'cp-siti',
        ),
      ),
      Activity(
        id: 't-ladder',
        kind: ActivityKind.tournament,
        title: 'Smashers Ladder Night',
        sports: const [Sport.badminton],
        gameType: GameType.doubles,
        format: ActivityFormat.roundRobin,
        levelMin: 4,
        levelMax: 7.9,
        startsAt: _next(DateTime.friday, 19, 30),
        endsAt: _next(DateTime.friday, 22, 30),
        registrationClosesAt: _next(DateTime.wednesday, 23, 59),
        venue: _venues[0],
        capacity: 16,
        spotsTaken: 12,
        feeCents: 800,
        host: hannah,
        hostMeetCount: 124,
        going: going,
        ranked: true,
        clubId: 'c-ts',
      ),
      Activity(
        id: 'e-finals',
        kind: ActivityKind.event,
        title: 'Tampines Open, Finals Day',
        sports: const [Sport.badminton],
        format: ActivityFormat.festival,
        startsAt: _next(DateTime.sunday, 9, 0, 1),
        endsAt: _next(DateTime.sunday, 18, 0, 1),
        venue: _venues[0],
        capacity: 2000,
        spotsTaken: 1284,
        feeCents: 1000,
        host: hannah,
        hostMeetCount: 124,
        myStatus: MyStatus.joined,
        going: going,
        coverTitle: 'Finals Day',
        coverColor: 0xFF2F3A5F,
        live: true,
        online: true,
        watching: 1284,
        audience: 'All ages',
        subtitle: "Men's doubles final on Court 1 now",
        proof: const SocialProof(
          mark: 'PR',
          color: 0xFF3E6B8A,
          name: 'Priya Raman',
          text: 'and 3 friends are going',
          playerId: 'cp-priyar',
        ),
      ),
      Activity(
        id: 'e-festival',
        kind: ActivityKind.event,
        title: 'East Side Sports Festival',
        sports: const [Sport.badminton, Sport.pickleball, Sport.tennis],
        format: ActivityFormat.festival,
        startsAt: _in(24, 10),
        endsAt: _in(24, 20),
        venue: _venues[3],
        capacity: 500,
        spotsTaken: 320,
        host: DemoWorld.meSummary,
        iAmHost: true,
        hostMeetCount: 124,
        going: going,
        coverTitle: 'Sports Festival',
        coverColor: 0xFF0E6B4E,
        audience: 'All ages',
        subtitle: 'Try-outs, clinics and gear booths',
        description: 'A free day of racquet sports for all levels, with try-outs, clinics and gear booths.',
        proof: const SocialProof(
          mark: 'TS',
          color: 0xFF16181B,
          ink: 0xFFF2C14E,
          name: 'Tampines Smashers',
          text: 'is running a badminton try-out',
        ),
      ),
    ]);

    // A tournament the demo player runs, for the organizer screens.
    _items.add(
      Activity(
        id: 'an-cup',
        kind: ActivityKind.tournament,
        title: 'Smashers Club Cup',
        sports: const [Sport.badminton],
        gameType: GameType.doubles,
        format: ActivityFormat.groupsKnockout,
        levelMin: 3,
        levelMax: 6.9,
        startsAt: _next(DateTime.saturday, 9, 0, 2),
        endsAt: _next(DateTime.saturday, 18, 0, 2),
        registrationClosesAt: _next(DateTime.sunday, 23, 59, 1),
        venue: _venues[0],
        capacity: 24,
        spotsTaken: 14,
        feeCents: 1200,
        host: DemoWorld.meSummary,
        iAmHost: true,
        hostMeetCount: 18,
        clubId: 'c-ts',
        coverTitle: 'Club Cup',
        coverColor: 0xFF0E6B4E,
        tier: 'Club',
      ),
    );

    // A Meet the demo player runs, on now, so the organizer tools (players,
    // walk-ins, attendance, recap, cancel) have something to work on.
    final now = DateTime.now();
    final starts = DateTime(now.year, now.month, now.day, now.hour - 1);
    _items.add(
      meet(
        id: 'an-tuesday',
        title: 'Smashers Club Night',
        starts: starts,
        venue: 0,
        min: 3,
        max: 6.9,
        cap: 12,
        taken: 8,
        fee: 600,
        ranked: true,
        men: 5,
        women: 3,
        recurrence: 'Every week',
        clubId: 'c-ts',
        host: DemoWorld.meSummary,
      ).copyWith(iAmHost: true, myStatus: MyStatus.joined, hostMeetCount: 18),
    );
    _people['an-tuesday'] = [
      const MeetPlayer(
        player: DemoWorld.meSummary,
        role: 'Organizer',
        rating: 5.3,
        band: 'MI',
        sessions: 42,
        isHost: true,
        attendance: Attendance.present,
      ),
      for (final (id, r, n) in const [
        ('cp-hannah', 6.2, 31),
        ('cp-priyar', 5.1, 18),
        ('cp-danielt', 4.2, 7),
        ('cp-sitil', 5.0, 25),
        ('cp-meiling', 4.9, 12),
        ('cp-hafiz', 5.6, 20),
      ])
        MeetPlayer(
          player: _w.players[id]!,
          rating: r,
          band: SkillBand.forLevel(r).code,
          sessions: n,
          checkedInAt: id == 'cp-priyar'
              ? starts.subtract(const Duration(minutes: 8))
              : null,
        ),
      const MeetPlayer(
        player: PlayerSummary(id: 'g-jiahui', fullName: 'Jia Hui Lee'),
        guestOf: 'Aaron Ng',
        rating: 4.9,
      ),
    ];
    _seedScores();
  }

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 250));

  bool _upcoming(Activity a) => a.endsAt.isAfter(DateTime.now());

  @override
  Future<List<Activity>> browse({
    required ActivityKind kind,
    Sport? sport,
    PlayFilters filters = const PlayFilters(),
  }) async {
    await _tick();
    final now = DateTime.now();
    return _items.where((a) {
      if (a.kind != kind || a.iAmHost || !_upcoming(a)) return false;
      if (sport != null && !a.sports.contains(sport)) return false;
      if (filters.gameType != null && a.gameType != filters.gameType) {
        return false;
      }
      if (filters.format != null && a.format != filters.format) return false;
      if (filters.when == 'today' &&
          !(a.startsAt.day == now.day && a.startsAt.month == now.month)) {
        return false;
      }
      if (filters.when == 'week' &&
          a.startsAt.isAfter(now.add(const Duration(days: 7)))) {
        return false;
      }
      if (filters.fee == 'free' && !a.isFree) return false;
      if (filters.fee == 'paid' && a.isFree) return false;
      if (filters.fee == 'under10' && a.feeCents >= 1000) return false;
      if (filters.fee == 'over10' && a.feeCents < 1000) return false;
      return true;
    }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  @override
  Future<List<Activity>> upcoming({
    ActivityKind kind = ActivityKind.meet,
    int limit = 5,
  }) async =>
      (_items
              .where((a) => a.kind == kind && !a.iAmHost && _upcoming(a))
              .toList()
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt)))
          .take(limit)
          .toList();

  @override
  Future<List<Activity>> search(String query) async {
    final q = query.toLowerCase();
    return _items
        .where(
          (a) =>
              _upcoming(a) &&
              (a.title.toLowerCase().contains(q) ||
                  a.sports.any((s) => s.label.toLowerCase().contains(q))),
        )
        .toList();
  }

  @override
  Future<Activity> activity(String id) async {
    await _tick();
    return _items.firstWhere((a) => a.id == id);
  }

  @override
  Future<List<Activity>> mySchedule() async =>
      _items.where((a) => a.myStatus != MyStatus.none && _upcoming(a)).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  @override
  Future<List<Activity>> hosting() async =>
      _items.where((a) => a.iAmHost && _upcoming(a)).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  @override
  Future<List<Venue>> venues(String query) async => _venues
      .where((v) => v.name.toLowerCase().contains(query.toLowerCase()))
      .toList();

  void _update(String id, Activity Function(Activity) edit) {
    final i = _items.indexWhere((a) => a.id == id);
    _items[i] = edit(_items[i]);
  }

  @override
  Future<MyStatus> join(
    String id, {
    String? guestName,
    double? guestLevel,
  }) async {
    await _tick();
    _join(id, guestName);
    return MyStatus.joined;
  }

  @override
  Future<int> joinWaitlist(String id, {bool notify = true}) async {
    await _tick();
    final a = _items.firstWhere((x) => x.id == id);
    final pos = a.myStatus == MyStatus.waitlist
        ? a.myWaitlistPosition
        : a.waitlistCount + 1;
    _update(
      id,
      (a) => a.copyWith(
        myStatus: MyStatus.waitlist,
        myWaitlistPosition: pos,
        waitlistCount: a.myStatus == MyStatus.waitlist
            ? a.waitlistCount
            : a.waitlistCount + 1,
      ),
    );
    return pos;
  }

  @override
  Future<int> leave(String id, {bool toWallet = true}) async {
    await _tick();
    final a = _items.firstWhere((x) => x.id == id);
    _update(
      id,
      (a) => a.copyWith(
        myStatus: MyStatus.none,
        spotsTaken: a.myStatus == MyStatus.joined
            ? a.spotsTaken - 1
            : a.spotsTaken,
        waitlistCount: a.myStatus == MyStatus.waitlist
            ? a.waitlistCount - 1
            : a.waitlistCount,
      ),
    );
    _people.remove(id);
    final early = a.startsAt.isAfter(DateTime.now());
    if (a.isFree || !early || a.myStatus != MyStatus.joined) return 0;
    return toWallet ? a.totalCents : a.feeCents;
  }

  @override
  Future<int> checkIn(String id) async {
    await _tick();
    return 9;
  }

  @override
  Future<String> publish(ActivityDraft d) async {
    await _tick();
    final base = DateTime.now().millisecondsSinceEpoch;
    final meet = d.kind == ActivityKind.meet;
    final levels = d.kind != ActivityKind.event && (!meet || d.restrictLevel);
    final dates = meet ? d.occurrences : [d.startsAt!];
    for (final (i, starts) in dates.indexed) {
      _items.add(
        Activity(
          id: 'a-${base + i}',
          kind: d.kind,
          title: d.title.trim(),
          description: d.description,
          sports: d.sports,
          gameType: d.kind == ActivityKind.event ? null : d.gameType,
          format: d.format!,
          levelMin: levels ? d.levelMin : null,
          levelMax: levels ? d.levelMax : null,
          startsAt: starts,
          venue: d.venue!,
          capacity: d.capacity,
          feeCents: d.chargeFee ? d.feeCents : 0,
          allowGuests: d.allowGuests,
          host: DemoWorld.meSummary,
          iAmHost: true,
          // The organizer starts out organizing only, as the design says.
          hostPlaying: false,
          clubId: d.clubId,
          coverTitle: d.coverTitle,
          coverColor: d.coverColor,
          coverInk: bannerInk(d.coverColor),
          ranked: meet && d.ranked,
          recurrence: meet ? d.recurrenceLabel : null,
          minPlayers: meet ? d.minPlayers : 0,
          playersPayFee: meet && !d.chargeFee && d.playersPayFee,
          levelAsNumbers: d.levelAsNumbers,
          tier: d.kind == ActivityKind.tournament ? d.tier : null,
          divisionKeys: d.kind == ActivityKind.tournament && !d.teamEntry
              ? d.divisionKeys
              : const [],
          online: d.kind == ActivityKind.event && d.online,
          linkedId: d.linkedId,
          registrationClosesAt: d.registrationCloses,
          endsAt: d.kind == ActivityKind.tournament && d.endDate != null
              ? DateTime(d.endDate!.year, d.endDate!.month, d.endDate!.day, 18)
              : starts.add(Duration(minutes: d.durationMinutes)),
        ),
      );
    }
    return 'a-$base';
  }

  @override
  Future<void> update(String id, ActivityDraft d) async {
    await _tick();
    final i = _items.indexWhere((a) => a.id == id);
    if (i < 0) return;
    final a = _items[i];
    final meet = d.kind == ActivityKind.meet;
    final levels = d.kind != ActivityKind.event && (!meet || d.restrictLevel);
    final starts = d.startsAt!;
    _items[i] = a.copyWith(
      title: d.title.trim(),
      description: d.description,
      sports: d.sports,
      gameType: d.kind == ActivityKind.event ? null : d.gameType,
      format: d.format!,
      levelMin: levels ? d.levelMin : null,
      levelMax: levels ? d.levelMax : null,
      startsAt: starts,
      endsAt: d.kind == ActivityKind.tournament && d.endDate != null
          ? DateTime(d.endDate!.year, d.endDate!.month, d.endDate!.day, 18)
          : starts.add(Duration(minutes: d.durationMinutes)),
      venue: d.venue!,
      capacity: d.capacity,
      feeCents: d.chargeFee ? d.feeCents : 0,
      allowGuests: d.allowGuests,
      approvalRequired: d.approvalRequired,
      coverTitle: d.coverTitle,
      coverColor: d.coverColor,
      coverInk: bannerInk(d.coverColor),
      ranked: meet && d.ranked,
      minPlayers: meet ? d.minPlayers : 0,
      playersPayFee: meet && !d.chargeFee && d.playersPayFee,
      levelAsNumbers: d.levelAsNumbers,
      tier: d.kind == ActivityKind.tournament ? d.tier : null,
      divisionKeys: d.kind == ActivityKind.tournament && !d.teamEntry
          ? d.divisionKeys
          : const [],
      online: d.kind == ActivityKind.event && d.online,
      registrationClosesAt: d.registrationCloses,
    );
  }

  // Organizer tools and scores.

  /// Player lists, made the first time a Meet's list is asked for.
  final _people = <String, List<MeetPlayer>>{};
  final _scores = <String, MatchScore>{};

  /// A steady made-up rating inside the Meet's range.
  double _rating(String id, Activity a) {
    final lo = a.levelMin ?? 3.0;
    final hi = (a.levelMax ?? 6.9).clamp(lo, 7.9);
    final step = id.codeUnits.fold(0, (x, c) => x * 31 + c) % 1000 / 1000;
    return double.parse((lo + (hi - lo) * step).toStringAsFixed(1));
  }

  MeetPlayer _member(Activity a, PlayerSummary p, {int? waitlistAt}) {
    final r = _rating(p.id, a);
    return MeetPlayer(
      player: p,
      rating: r,
      band: SkillBand.forLevel(r).code,
      sessions: 3 + p.id.length * 7 % 40,
      waitlistAt: waitlistAt,
    );
  }

  List<MeetPlayer> _listFor(Activity a) => _people.putIfAbsent(a.id, () {
    final out = <MeetPlayer>[];
    final seen = <String>{};
    void add(MeetPlayer p) {
      if (seen.add(p.player.id)) out.add(p);
    }

    if (a.hostPlaying) {
      final r = a.iAmHost ? 5.3 : _rating(a.host.id, a);
      add(
        MeetPlayer(
          player: a.host,
          role: 'Organizer',
          rating: r,
          band: SkillBand.forLevel(r).code,
          sessions: a.hostMeetCount,
          isHost: true,
        ),
      );
    }
    if (a.myStatus == MyStatus.joined && !a.iAmHost) {
      add(
        MeetPlayer(
          player: DemoWorld.meSummary,
          rating: 5.3,
          band: 'MI',
          sessions: 42,
        ),
      );
    }
    final pool = [...a.going, ..._w.players.values];
    for (final p in pool) {
      if (out.length >= a.spotsTaken) break;
      if (p.id == DemoWorld.me) continue;
      add(_member(a, p));
    }
    var queue = 0;
    for (final p in pool.reversed) {
      if (queue >= a.waitlistCount) break;
      if (seen.contains(p.id) || p.id == DemoWorld.me) continue;
      add(_member(a, p, waitlistAt: ++queue));
    }
    return out;
  });

  @override
  Future<List<MeetPlayer>> players(String id) async {
    await _tick();
    return List.of(_listFor(_items.firstWhere((a) => a.id == id)));
  }

  @override
  Future<void> hostPlays(String id, {required bool playing}) async {
    await _tick();
    final a = _items.firstWhere((x) => x.id == id);
    if (a.hostPlaying == playing) return;
    if (playing && a.isFull) throw const AuthFailure('The Meet is full.');
    final list = _listFor(a);
    _update(
      id,
      (a) => a.copyWith(
        hostPlaying: playing,
        spotsTaken: a.spotsTaken + (playing ? 1 : -1),
      ),
    );
    if (playing) {
      list.insert(
        0,
        MeetPlayer(
          player: a.host,
          role: 'Organizer',
          rating: 5.3,
          band: 'MI',
          sessions: a.hostMeetCount,
          isHost: true,
        ),
      );
    } else {
      list.removeWhere((p) => p.isHost);
    }
  }

  @override
  Future<List<MeetPlayer>> walkInCandidates(String id) async {
    await _tick();
    final a = _items.firstWhere((x) => x.id == id);
    final taken = {for (final p in _listFor(a)) p.player.id};
    return [
      for (final p in _w.players.values)
        if (!taken.contains(p.id) && p.id != DemoWorld.me)
          _member(a, p).copyWith(),
    ]..sort((x, y) => x.player.displayName.compareTo(y.player.displayName));
  }

  @override
  Future<void> addWalkIn(
    String id,
    String playerId, {
    required bool cash,
  }) async {
    await _tick();
    final a = _items.firstWhere((x) => x.id == id);
    final p = _w.players[playerId];
    if (p == null) throw const AuthFailure("We couldn't find that member.");
    final m = _member(a, p);
    _listFor(a).add(
      MeetPlayer(
        player: p,
        rating: m.rating,
        band: m.band,
        sessions: m.sessions,
        walkIn: true,
        paidCash: cash,
        attendance: Attendance.present,
      ),
    );
    _update(id, (a) => a.copyWith(spotsTaken: a.spotsTaken + 1));
  }

  @override
  Future<void> saveAttendance(String id, Map<String, Attendance> marks) async {
    await _tick();
    final list = _listFor(_items.firstWhere((x) => x.id == id));
    for (var i = 0; i < list.length; i++) {
      final mark = marks[list[i].player.id];
      if (mark != null) list[i] = list[i].copyWith(attendance: mark);
    }
  }

  @override
  Future<CancelPreview> cancelPreview(String id) async {
    await _tick();
    final a = _items.firstWhere((x) => x.id == id);
    final players = _listFor(a)
        .where((p) => p.waitlistAt == null && !p.isHost)
        .length;
    final each = a.totalCents;
    // Most players pay by card; card companies keep about 3.4% + S$0.50.
    final cards = a.isFree ? 0 : (players * 5 / 8).round();
    final series = a.recurrence == null
        ? [a]
        : [
            for (var w = 0; w < 8; w++)
              a.copyWith(startsAt: a.startsAt.add(Duration(days: 7 * w))),
          ];
    return CancelPreview(
      players: players,
      eachCents: each,
      cardPayments: cards,
      cardFeeCents: cards * (each * 0.034 + 50).round(),
      laterMeets: series.length,
      lastMeet: series.last.startsAt,
    );
  }

  @override
  Future<void> cancel(
    String id, {
    bool series = false,
    String message = '',
  }) async {
    await _tick();
    _items.removeWhere((a) => a.id == id);
    _people.remove(id);
  }

  @override
  Future<MeetRecap> recap(String id) async {
    await _tick();
    final a = _items.firstWhere((x) => x.id == id);
    return MeetRecap(
      games: 4,
      wins: 3,
      losses: 1,
      bestGame: '21–12',
      ratingBefore: 5.3,
      ratingAfter: 5.4,
      band: 'MI',
      bestPartner: _w.players['cp-priyar'],
      partnerWins: 2,
      points: 4,
      session: 43,
      clubName: a.clubId == null ? null : 'Tampines Smashers',
      clubLink: a.clubId == null ? null : 'olympus.app/c/tampines-smashers',
    );
  }

  void _seedScores() {
    final mei = _w.players['cp-mei']!;
    final singles = _items.firstWhere((a) => a.id == 'ts-singles');
    _scores['sc-morning'] = MatchScore(
      id: 'sc-morning',
      activityId: singles.id,
      activityTitle: singles.title,
      court: 'Court 2',
      sideA: [mei],
      sideB: const [DemoWorld.meSummary],
      games: const [(15, 21), (21, 18), (17, 21)],
      enteredBy: mei,
      enteredAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ratingBefore: 5.3,
      ratingAfter: 5.4,
      organizer: singles.host,
    );
  }

  @override
  Future<MatchScore> score(String scoreId) async {
    await _tick();
    final s = _scores[scoreId];
    if (s == null) throw const AuthFailure("This score isn't available.");
    return s;
  }

  @override
  Future<MatchScore> submitScore(
    String activityId, {
    required List<String> partners,
    required List<String> opponents,
    required List<(int, int)> games,
  }) async {
    await _tick();
    final a = _items.firstWhere((x) => x.id == activityId);
    PlayerSummary who(String id) => _w.players[id] ?? PlayerSummary(id: id);
    final id = 'sc-${DateTime.now().millisecondsSinceEpoch}';
    return _scores[id] = MatchScore(
      id: id,
      activityId: a.id,
      activityTitle: a.title,
      court: a.court,
      sideA: [DemoWorld.meSummary, ...partners.map(who)],
      sideB: [...opponents.map(who)],
      games: games,
      enteredBy: DemoWorld.meSummary,
      enteredAt: DateTime.now(),
      organizer: a.host,
    );
  }

  @override
  Future<MatchScore> answerScore(
    String scoreId, {
    required bool confirm,
    String? reason,
  }) async {
    await _tick();
    final s = _scores[scoreId]!;
    return _scores[scoreId] = s.copyWith(
      status: confirm ? ScoreStatus.confirmed : ScoreStatus.disputed,
      reason: reason,
    );
  }

  /// Club sessions seeded by the demo club repository.
  void addAll(Iterable<Activity> activities) {
    for (final a in activities) {
      if (_items.every((x) => x.id != a.id)) _items.add(a);
    }
  }

  /// Synchronous lookup for other demo repositories.
  Activity? byId(String id) => _items.where((a) => a.id == id).firstOrNull;

  /// Lets the tournament and event demos change an activity.
  void edit(String id, Activity Function(Activity) change) =>
      _update(id, change);

  void remove(String id) => _items.removeWhere((a) => a.id == id);

  /// A club's upcoming sessions, soonest first.
  List<Activity> forClub(String clubId) =>
      _items.where((a) => a.clubId == clubId && _upcoming(a)).toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  @override
  Future<List<PlaySportPref>> playSports() async => _prefs;

  @override
  Future<void> savePlaySports(List<PlaySportPref> prefs) async =>
      _prefs = prefs;

  /// Used by the demo payment gateway.
  void markPaid(String id, {String? guestName}) => _join(id, guestName);

  /// The player's spot (unless they hold one) and their guest's.
  void _join(String id, String? guestName) {
    final a = _items.firstWhere((x) => x.id == id);
    final mine = a.myStatus == MyStatus.joined ? 0 : 1;
    _update(
      id,
      (a) => a.copyWith(
        myStatus: MyStatus.joined,
        spotsTaken: a.spotsTaken + mine + (guestName == null ? 0 : 1),
      ),
    );
    final list = _people[id];
    if (list == null) return;
    if (mine == 1) {
      list.add(
        const MeetPlayer(
          player: DemoWorld.meSummary,
          rating: 5.3,
          band: 'MI',
          sessions: 42,
        ),
      );
    }
    if (guestName != null) {
      list.add(
        MeetPlayer(
          player: PlayerSummary(
            id: 'g-${DateTime.now().millisecondsSinceEpoch}',
            fullName: guestName,
          ),
          guestOf: DemoWorld.meSummary.displayName,
        ),
      );
    }
  }
}
