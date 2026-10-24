import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/demo/demo_world.dart';
import '../../../core/format.dart';
import '../../auth/data/auth_repository.dart';
import '../../clubs/domain/club_sport.dart';
import '../../social/domain/social_models.dart';
import '../domain/activity.dart';
import '../domain/draw_logic.dart';
import '../domain/event_models.dart';
import '../domain/tournament_models.dart';
import 'play_repository.dart';

/// Tournament pages: divisions, entries, the draw and results.
abstract interface class TournamentRepository {
  Future<TournamentInfo> info(String id);
  Future<List<Entry>> entries(String id, String divisionId);
  Future<List<DrawGroup>> groups(String id, String divisionId);
  Future<List<KnockoutRound>> knockout(String id, String divisionId);
  Future<List<MyMatch>> myMatches(String id);
  Future<TournamentResult?> result(String id);
  Future<List<PartnerPick>> partners(String id);

  /// Enters the viewer in [divisionIds], inviting [partnerId] for doubles.
  Future<void> register(
    String id, {
    required List<String> divisionIds,
    String? partnerId,
  });

  /// Withdraws. Returns the refund in cents.
  Future<int> withdraw(
    String id, {
    required bool toWallet,
    required bool injury,
  });

  /// The invited partner says yes or no.
  Future<void> answerInvite(String id, String entryId, {required bool accept});

  /// Every match in the draw, or one event's.
  Future<List<DrawMatch>> matches(String id, {String? divisionId});

  // Organizer.
  Future<void> setCheckedIn(String id, String entryId, bool here);
  Future<int> message(String id, {required String to, required String text});
  Future<void> cancel(String id, {String message = ''});

  /// Makes the draw for one event. Returns how many entries are in it.
  Future<int> makeDraw(String id, String divisionId);
  Future<void> callMatch(String matchId);

  /// The umpire's final score, side A first.
  Future<void> saveScore(String matchId, List<(int, int)> games);
}

/// Event pages: the programme, the live court and tickets.
abstract interface class EventRepository {
  Future<EventInfo> info(String id);
  Future<Ticket> buy(String id, {required int qty});
  Future<Ticket?> ticket(String id);

  /// Gives [qty] tickets back. Returns the refund in cents.
  Future<int> release(String id, {required int qty});
  Future<void> cheer(String id, {required bool sideA});
  Future<void> remind(String id, String itemId, bool on);

  // Organizer.
  Future<ScanResult> scan(String id, String code);
  Future<void> cancel(String id, {String message = ''});
}

/// Tournaments on Supabase: entries per event, partner invites, the draw,
/// scores and results.
class SupabaseTournamentRepository implements TournamentRepository {
  SupabaseTournamentRepository(this._client, this._play);
  final SupabaseClient _client;
  final PlayRepository _play;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Tournament error: ${e.code} ${e.message}');
      if (e.message == 'payment_required') {
        throw const AuthFailure(
          "Card payments aren't switched on yet, so paid entries open once "
          'payments are connected.',
        );
      }
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Tournament network error: $e');
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  Future<dynamic> _rpc(String fn, Map<String, dynamic> params) =>
      _client.rpc(fn, params: params);

  Future<List<Map<String, dynamic>>> _list(
    String fn,
    Map<String, dynamic> params,
  ) async => [
    for (final r in (await _rpc(fn, params)) as List? ?? const [])
      (r as Map).cast<String, dynamic>(),
  ];

  static double? _num(Object? v) => (v as num?)?.toDouble();

  static DrawMatch _match(Map<String, dynamic> r) {
    final mine = r['mine'] as String?;
    final winner = r['winner'] as String?;
    return DrawMatch(
      id: r['id'] as String,
      divisionId: r['division'] as String,
      stage: DrawStage.values.byName(r['stage'] as String),
      round: r['round'] as int,
      slot: r['slot'] as int,
      group: r['group'] as String?,
      a: r['a_name'] as String?,
      b: r['b_name'] as String?,
      srcA: r['src_a'] as String?,
      srcB: r['src_b'] as String?,
      at: r['at'] == null ? null : DateTime.parse(r['at'] as String).toLocal(),
      court: r['court'] as int?,
      games: [
        for (final g in (r['games'] as List?) ?? const [])
          ((g as List)[0] as int, g[1] as int),
      ],
      winnerA: winner == null ? null : winner == 'a',
      walkover: r['walkover'] as bool? ?? false,
      state: DrawMatchState.values.byName(r['state'] as String),
      mineA: mine == null ? null : mine == 'a',
    );
  }

  @override
  Future<TournamentInfo> info(String id) => _guard(() async {
    final a = await _play.activity(id);
    final t = ((await _rpc('tournament_info', {'p_activity': id})) as Map)
        .cast<String, dynamic>();
    final divisions = [
      for (final d in (t['divisions'] as List).cast<Map>())
        () {
          final k = d['key'] as String;
          final doubles = k == 'main'
              ? a.gameType != GameType.singles
              : k.endsWith('D');
          return Division(
            id: k,
            name: k == 'main'
                ? (a.gameType?.label ?? a.format.label)
                : divisionNames[k] ?? k,
            doubles: doubles,
            feeCents: k != 'main' && doubles ? a.feeCents * 2 : a.feeCents,
            capacity: a.capacity,
            entries: d['entries'] as int,
            waiting: d['waiting'] as int,
            bands: a.bands,
            drawn: d['drawn'] as bool? ?? false,
          );
        }(),
    ];
    String nameOf(String k) =>
        divisions.where((d) => d.id == k).firstOrNull?.name ?? k;
    final m = (t['mine'] as Map?)?.cast<String, dynamic>();
    final inv = (t['invite'] as Map?)?.cast<String, dynamic>();
    final mineDivision = m == null
        ? null
        : divisions.where((d) => d.id == m['division']).firstOrNull;
    return TournamentInfo(
      activity: a,
      divisions: divisions,
      host: a.host.displayName,
      hostMark: a.host.initials,
      drawFormat: a.format.label,
      mine: m == null
          ? null
          : MyEntry(
              divisionId: m['division'] as String,
              divisionName: nameOf(m['division'] as String),
              partner: m['partner'] == null
                  ? null
                  : PlayerSummary.fromRow(
                      (m['partner'] as Map).cast<String, dynamic>(),
                    ),
              group: m['group'] as String?,
              seed: m['seed'] as int?,
              firstMatchAt: m['first_match_at'] == null
                  ? null
                  : DateTime.parse(m['first_match_at'] as String).toLocal(),
              firstCourt: m['first_court'] == null
                  ? null
                  : 'Court ${m['first_court']}',
              paidCents: a.isFree ? 0 : a.totalCents,
              entryCents: mineDivision?.feeCents ?? a.feeCents,
            ),
      invite: inv == null
          ? null
          : PartnerInvite(
              entryId: inv['entry'] as String,
              divisionId: inv['division'] as String,
              divisionName: nameOf(inv['division'] as String),
              from: PlayerSummary.fromRow(
                (inv['from'] as Map).cast<String, dynamic>(),
              ),
            ),
      checkedIn: t['checked_in'] as int? ?? 0,
      finished: t['finished'] as bool? ?? false,
      myLevel: _num(t['level']),
    );
  });

  @override
  Future<List<Entry>> entries(String id, String divisionId) => _guard(() async {
    final rows = await _list('tournament_entry_list', {
      'p_activity': id,
      'p_division': divisionId,
    });
    return [
      for (final r in rows)
        () {
          final first = r['first_match_at'] == null
              ? null
              : DateTime.parse(r['first_match_at'] as String).toLocal();
          final group = r['group'] as String?;
          return Entry(
            id: r['id'] as String,
            divisionId: divisionId,
            names: r['names'] as String,
            rating: _num(r['rating']),
            seed: r['seed'] as int?,
            status: r['status'] == 'waitlist'
                ? EntryStatus.waitlist
                : (r['partner_pending'] == true || r['needs_partner'] == true)
                ? EntryStatus.partnerPending
                : EntryStatus.paid,
            mine: r['mine'] as bool? ?? false,
            checkedIn: r['checked_in'] as bool? ?? false,
            group: group,
            firstMatch: first == null
                ? null
                : [?group, 'first match ${Fmt.time(first)}'].join(', '),
          );
        }(),
    ];
  });

  @override
  Future<List<DrawGroup>> groups(String id, String divisionId) =>
      _guard(() async {
        final rows = await _list('tournament_groups', {
          'p_activity': id,
          'p_division': divisionId,
        });
        return [
          for (final g in rows)
            DrawGroup(g['name'] as String, [
              for (final (i, r)
                  in ((g['rows'] as List?) ?? const []).cast<Map>().indexed)
                GroupRow(
                  pos: i + 1,
                  names: r['names'] as String,
                  seed: r['seed'] as int? ?? 0,
                  rating: _num(r['rating']) ?? 0,
                  wins: r['wins'] as int? ?? 0,
                  losses: r['losses'] as int? ?? 0,
                  points: r['points'] as int? ?? 0,
                  mine: r['mine'] as bool? ?? false,
                ),
            ]),
        ];
      });

  @override
  Future<List<DrawMatch>> matches(String id, {String? divisionId}) =>
      _guard(() async {
        final rows = await _list('tournament_match_list', {
          'p_activity': id,
          'p_division': divisionId,
        });
        return [for (final r in rows) _match(r)];
      });

  @override
  Future<List<KnockoutRound>> knockout(String id, String divisionId) async =>
      knockoutRounds(await matches(id, divisionId: divisionId));

  @override
  Future<List<MyMatch>> myMatches(String id) async =>
      myMatchesFrom(await matches(id));

  @override
  Future<TournamentResult?> result(String id) async {
    final t = await info(id);
    final mine = t.mine;
    if (mine == null) return null;
    final ms = await matches(id, divisionId: mine.divisionId);
    final hasKo = ms.any((m) => m.stage != DrawStage.group);
    return resultFrom(
      division: mine.divisionName,
      ms: ms,
      entries:
          t.divisions
              .where((d) => d.id == mine.divisionId)
              .firstOrNull
              ?.entries ??
          0,
      table: hasKo ? const [] : await groups(id, mine.divisionId),
    );
  }

  @override
  Future<List<PartnerPick>> partners(String id) => _guard(() async {
    final rows = await _list('tournament_partner_picks', {'p_activity': id});
    return [
      for (final r in rows)
        () {
          final n = r['together'] as int? ?? 0;
          final level = _num(r['level']);
          return PartnerPick(
            PlayerSummary.fromRow((r['player'] as Map).cast<String, dynamic>()),
            [
              if (level != null) SkillBand.forLevel(level).code,
              n == 0
                  ? 'You follow them'
                  : '$n ${n == 1 ? 'Meet' : 'Meets'} together',
            ].join(' · '),
          );
        }(),
    ];
  });

  @override
  Future<void> register(
    String id, {
    required List<String> divisionIds,
    String? partnerId,
  }) => _guard(() async {
    await _rpc('tournament_register', {
      'p_activity': id,
      'p_divisions': divisionIds,
      'p_partner': partnerId,
    });
  });

  @override
  Future<void> answerInvite(
    String id,
    String entryId, {
    required bool accept,
  }) => _guard(() async {
    await _rpc('tournament_partner_answer', {
      'p_entry': entryId,
      'p_accept': accept,
    });
  });

  @override
  Future<int> withdraw(
    String id, {
    required bool toWallet,
    required bool injury,
  }) async {
    await _guard(() => _rpc('tournament_withdraw', {'p_activity': id}));
    return _play.leave(id, toWallet: toWallet);
  }

  @override
  Future<void> setCheckedIn(String id, String entryId, bool here) =>
      _guard(() async {
        await _rpc('tournament_check_in', {'p_entry': entryId, 'p_here': here});
      });

  @override
  Future<int> message(String id, {required String to, required String text}) =>
      _guard(() async {
        // [to] is what the organizer picked: everyone, one event, or players
        // not checked in yet.
        var key = 'all';
        if (to.startsWith('Not checked')) {
          key = 'unchecked';
        } else if (!to.startsWith('All')) {
          final t = await info(id);
          key =
              t.divisions
                  .where((d) => to == '${d.name} only')
                  .firstOrNull
                  ?.id ??
              'all';
        }
        return await _rpc('tournament_message', {
          'p_activity': id,
          'p_to': key,
          'p_text': text,
        }) as int;
      });

  @override
  Future<int> makeDraw(String id, String divisionId) => _guard(
    () async => await _rpc('tournament_make_draw', {
      'p_activity': id,
      'p_division': divisionId,
    }) as int,
  );

  @override
  Future<void> callMatch(String matchId) => _guard(() async {
    await _rpc('tournament_call', {'p_match': matchId});
  });

  @override
  Future<void> saveScore(String matchId, List<(int, int)> games) =>
      _guard(() async {
        await _rpc('tournament_score', {
          'p_match': matchId,
          'p_games': [
            for (final g in games) [g.$1, g.$2],
          ],
        });
      });

  @override
  Future<void> cancel(String id, {String message = ''}) =>
      _play.cancel(id, message: message);
}

/// The event layer on the activity tables: a ticket is a participant.
/// Programmes, the live court and multi-person tickets need the event
/// tables, which come later.
class SupabaseEventRepository implements EventRepository {
  SupabaseEventRepository(this._play);
  final PlayRepository _play;

  @override
  Future<EventInfo> info(String id) async {
    final a = await _play.activity(id);
    final mine = a.myStatus == MyStatus.joined;
    return EventInfo(
      activity: a,
      about: a.description ?? '',
      programme: const [],
      tickets: mine ? 1 : 0,
      paidCents: mine ? a.totalCents : 0,
      refundBy: a.startsAt.subtract(const Duration(days: 1)),
    );
  }

  @override
  Future<Ticket> buy(String id, {required int qty}) async {
    final a = await _play.activity(id);
    if (!a.isFree) {
      throw const AuthFailure(
        "Card payments aren't switched on yet. Free tickets work now.",
      );
    }
    if (qty > 1) {
      throw const AuthFailure(
        'For now each person gets their own free ticket in the app.',
      );
    }
    await _play.join(id);
    return (await ticket(id))!;
  }

  @override
  Future<Ticket?> ticket(String id) async {
    final a = await _play.activity(id);
    if (a.myStatus != MyStatus.joined) return null;
    return Ticket(
      eventId: a.id,
      title: a.title,
      startsAt: a.startsAt,
      endsAt: a.endsAt,
      venue: '${a.venue.name}, ${a.venue.address}',
      qty: 1,
      paidCents: a.totalCents,
      code: a.id.substring(0, 8).toUpperCase(),
      refundBy: a.startsAt.subtract(const Duration(days: 1)),
    );
  }

  @override
  Future<int> release(String id, {required int qty}) => _play.leave(id);

  @override
  Future<void> cheer(String id, {required bool sideA}) async {}

  @override
  Future<void> remind(String id, String itemId, bool on) async {}

  @override
  Future<ScanResult> scan(String id, String code) =>
      throw const AuthFailure("Ticket scanning isn't switched on yet.");

  @override
  Future<void> cancel(String id, {String message = ''}) =>
      _play.cancel(id, message: message);
}

// ─── Demo ──────────────────────────────────────────────────────────────────

class DemoTournamentRepository implements TournamentRepository {
  DemoTournamentRepository(this._play) {
    _mine['t-open'] = _openEntry;
  }

  final DemoPlayRepository _play;
  final _w = DemoWorld.instance;
  final _mine = <String, MyEntry>{};
  final _checkedIn = <String>{};

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 200));

  Activity _a(String id) {
    final a = _play.byId(id);
    if (a == null) throw const AuthFailure("This isn't available any more.");
    return a;
  }

  DateTime _on(DateTime day, int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  MyEntry get _openEntry {
    final a = _a('t-open');
    return MyEntry(
      divisionId: 'XD',
      divisionName: 'Mixed doubles',
      partner: _w.players['cp-priyar'],
      group: 'Group B',
      seed: 3,
      firstMatchAt: _on(a.startsAt, 10, 20),
      firstCourt: 'Court 4',
      paidCents: 3300,
      entryCents: 3000,
    );
  }

  List<Division> _divisions(String id) => switch (id) {
    't-open' => const [
      Division(
        id: 'MS',
        name: "Men's singles",
        doubles: false,
        feeCents: 1500,
        capacity: 32,
        entries: 28,
        bands: 'MB–AD',
      ),
      Division(
        id: 'WS',
        name: "Women's singles",
        doubles: false,
        feeCents: 1500,
        capacity: 32,
        entries: 12,
        bands: 'MB–AD',
      ),
      Division(
        id: 'MD',
        name: "Men's doubles",
        doubles: true,
        feeCents: 3000,
        capacity: 16,
        entries: 16,
        waiting: 3,
        bands: 'LI–AD',
      ),
      Division(
        id: 'XD',
        name: 'Mixed doubles',
        doubles: true,
        feeCents: 3000,
        capacity: 16,
        entries: 10,
        bands: 'LI–AD',
      ),
    ],
    'an-cup' => const [
      Division(
        id: 'MS',
        name: "Men's singles",
        doubles: false,
        feeCents: 1200,
        capacity: 16,
        entries: 8,
        bands: 'HB–HI',
      ),
      Division(
        id: 'XD',
        name: 'Mixed doubles',
        doubles: true,
        feeCents: 2400,
        capacity: 8,
        entries: 6,
        bands: 'HB–HI',
      ),
    ],
    _ when _a(id).divisionKeys.isNotEmpty => [
      for (final k in _a(id).divisionKeys)
        Division(
          id: k,
          name: divisionNames[k] ?? k,
          doubles: k.endsWith('D'),
          // Doubles pay per pair.
          feeCents: _a(id).feeCents * (k.endsWith('D') ? 2 : 1),
          capacity: _a(id).capacity,
          bands: _a(id).bands,
        ),
    ],
    _ => () {
      final a = _a(id);
      return [
        Division(
          id: 'main',
          name: a.gameType == GameType.singles
              ? 'Singles ladder'
              : 'Doubles ladder',
          doubles: a.gameType != GameType.singles,
          feeCents: a.feeCents,
          capacity: a.capacity,
          entries: a.spotsTaken,
          bands: a.bands,
        ),
      ];
    }(),
  };

  @override
  Future<TournamentInfo> info(String id) async {
    await _tick();
    final a = _a(id);
    final mine = a.myStatus == MyStatus.joined ? _mine[id] : null;
    return TournamentInfo(
      activity: a,
      divisions: _divisions(id),
      // The Open and club tournaments are run by the club.
      host: a.clubId == null && id != 't-open'
          ? a.host.displayName
          : 'Tampines Smashers',
      hostMark: a.clubId == null && id != 't-open' ? a.host.initials : 'TS',
      courts: id == 't-open' ? 8 : 4,
      drawFormat: a.format == ActivityFormat.roundRobin
          ? 'Round robin'
          : 'Groups, then knockout',
      divisionsText: id == 't-open' ? 'Open, U17' : 'Open',
      spectatorEventId: id == 't-open' ? 'e-finals' : a.linkedId,
      spectatorTitle: id == 't-open'
          ? 'Finals Day'
          : (a.linkedId == null ? null : _play.byId(a.linkedId!)?.title),
      mine: mine,
      checkedIn: id == 'an-cup' ? _checkedIn.length : 41,
      myLevel: 5.1,
    );
  }

  static const _clubs = [
    'Tampines Smashers',
    'Bedok Night Owls',
    'East Coast Smash',
    'Pasir Ris Rally Crew',
    'Simei Kakis',
  ];

  @override
  Future<List<Entry>> entries(String id, String divisionId) async {
    await _tick();
    if (id == 't-open') {
      return switch (divisionId) {
        'MS' => const [
          Entry(
            id: 'e1',
            divisionId: 'MS',
            names: 'Ryan Teo',
            club: 'Bedok Night Owls',
            rating: 6.4,
            seed: 1,
          ),
          Entry(
            id: 'e2',
            divisionId: 'MS',
            names: 'Jun Li',
            club: 'Tampines Smashers',
            rating: 6.1,
            seed: 2,
          ),
          Entry(
            id: 'e3',
            divisionId: 'MS',
            names: 'Marcus Koh',
            club: 'East Coast Smash',
            rating: 5.9,
            seed: 3,
          ),
          Entry(
            id: 'e4',
            divisionId: 'MS',
            names: 'Daniel Tan',
            club: 'Tampines Smashers',
            rating: 4.2,
            seed: 4,
          ),
        ],
        'WS' => const [
          Entry(
            id: 'e5',
            divisionId: 'WS',
            names: 'Mei Wong',
            club: 'Tampines Smashers',
            rating: 5.8,
            seed: 1,
          ),
          Entry(
            id: 'e6',
            divisionId: 'WS',
            names: 'Siti Kamal',
            club: 'Tampines Smashers',
            rating: 5.9,
            seed: 2,
          ),
          Entry(
            id: 'e7',
            divisionId: 'WS',
            names: 'Jia Hui Lee',
            club: 'Pasir Ris Rally Crew',
            rating: 4.9,
            seed: 3,
          ),
        ],
        'MD' => const [
          Entry(
            id: 'e8',
            divisionId: 'MD',
            names: 'Tan and Lee',
            club: 'Bedok Night Owls',
            seed: 1,
          ),
          Entry(
            id: 'e9',
            divisionId: 'MD',
            names: 'Goh and Raman',
            club: 'East Coast Smash',
            seed: 2,
          ),
          Entry(
            id: 'e10',
            divisionId: 'MD',
            names: 'Aaron Ng and Kelvin Ho',
            club: 'Tampines Smashers',
            seed: 3,
            mine: true,
          ),
          Entry(
            id: 'e11',
            divisionId: 'MD',
            names: 'Ong and Lim',
            club: 'Simei Kakis',
            status: EntryStatus.waitlist,
          ),
        ],
        _ => const [
          Entry(
            id: 'e12',
            divisionId: 'XD',
            names: 'Hannah Goh and Ryan Teo',
            club: 'Tampines Smashers',
            seed: 1,
          ),
          Entry(
            id: 'e13',
            divisionId: 'XD',
            names: 'Aaron Ng and Priya Raman',
            club: 'Tampines Smashers',
            seed: 2,
            mine: true,
          ),
          Entry(
            id: 'e14',
            divisionId: 'XD',
            names: 'Siti Lim and Jun Li',
            club: 'Tampines Smashers',
            seed: 3,
            status: EntryStatus.partnerPending,
          ),
          Entry(
            id: 'e15',
            divisionId: 'XD',
            names: 'Mei Wong and Marcus Koh',
            club: 'East Coast Smash',
            seed: 4,
          ),
        ],
      };
    }
    // Made-up entries from the demo cast, seeded by a steady rating.
    final a = _a(id);
    final division = _divisions(
      id,
    ).firstWhere((d) => d.id == divisionId, orElse: () => _divisions(id).first);
    final people = _w.players.values
        .where((p) => p.id != DemoWorld.me)
        .toList();
    final start = a.startsAt;
    final out = <Entry>[];
    for (var i = 0; i < division.entries && i < 12; i++) {
      final p = people[i % people.length];
      final q = people[(i + 5) % people.length];
      final key = '$id-$divisionId-$i';
      String last(PlayerSummary s) => s.displayName.split(' ').last;
      out.add(
        Entry(
          id: key,
          divisionId: division.id,
          names: division.doubles ? '${last(p)} and ${last(q)}' : p.displayName,
          club: _clubs[i % _clubs.length],
          rating: double.parse((6.4 - i * 0.2).toStringAsFixed(1)),
          seed: i + 1,
          checkedIn: _checkedIn.contains(key),
          group: 'Group ${String.fromCharCode(65 + i % 2)}',
          firstMatch:
              'Group ${String.fromCharCode(65 + i % 2)}, first match '
              '${Fmt.time(start.add(Duration(minutes: 40 * (i ~/ 2))))}',
        ),
      );
    }
    return out;
  }

  @override
  Future<List<DrawGroup>> groups(String id, String divisionId) async {
    await _tick();
    if (id == 't-open' && divisionId == 'XD') {
      return const [
        DrawGroup('Group A', [
          GroupRow(pos: 1, names: 'Tan R / Lim J', seed: 1, rating: 6.3),
          GroupRow(pos: 2, names: 'Wong K / Ho D', seed: 8, rating: 4.9),
          GroupRow(pos: 3, names: 'Chua S / Yeo B', seed: 5, rating: 5.2),
          GroupRow(pos: 4, names: 'Koh M / Ng P', seed: 12, rating: 4.4),
        ]),
        DrawGroup('Group B', [
          GroupRow(
            pos: 1,
            names: 'You / Priya Raman',
            seed: 3,
            rating: 5.2,
            mine: true,
          ),
          GroupRow(pos: 2, names: 'Tan / Lee', seed: 6, rating: 5.0),
          GroupRow(pos: 3, names: 'Seah / Lau', seed: 10, rating: 4.6),
          GroupRow(pos: 4, names: 'Goh / Rahman', seed: 14, rating: 4.2),
        ]),
      ];
    }
    final all = await entries(id, divisionId);
    final groups = <String, List<GroupRow>>{};
    for (final e in all.where((e) => e.status != EntryStatus.waitlist)) {
      final g =
          e.group ?? 'Group ${String.fromCharCode(65 + groups.length % 2)}';
      final rows = groups.putIfAbsent(g, () => []);
      rows.add(
        GroupRow(
          pos: rows.length + 1,
          names: e.names,
          seed: e.seed ?? 0,
          rating: e.rating ?? 5.0,
          mine: e.mine,
        ),
      );
    }
    return [for (final e in groups.entries) DrawGroup(e.key, e.value)];
  }

  @override
  Future<List<KnockoutRound>> knockout(String id, String divisionId) async {
    await _tick();
    final a = _a(id);
    String day(DateTime d, int h, int m) =>
        '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]} '
        '${Fmt.time(_on(d, h, m))}';
    return [
      KnockoutRound('Quarter-finals', [
        KnockoutMatch('A1 · winner', 'B2 · runner-up', day(a.startsAt, 15, 0)),
        KnockoutMatch('C1 · winner', 'D2 · runner-up', day(a.startsAt, 15, 0)),
        KnockoutMatch('B1 · winner', 'A2 · runner-up', day(a.startsAt, 15, 40)),
        KnockoutMatch('D1 · winner', 'C2 · runner-up', day(a.startsAt, 15, 40)),
      ]),
      KnockoutRound('Semi-finals', [
        KnockoutMatch('QF1 winner', 'QF2 winner', day(a.endsAt, 10, 0)),
        KnockoutMatch('QF3 winner', 'QF4 winner', day(a.endsAt, 10, 0)),
      ]),
      KnockoutRound('Final', [
        KnockoutMatch(
          'SF1 winner',
          'SF2 winner',
          '${day(a.endsAt, 14, 0)} · Court 1',
        ),
      ]),
    ];
  }

  @override
  Future<List<MyMatch>> myMatches(String id) async {
    await _tick();
    final a = _a(id);
    if (a.myStatus != MyStatus.joined) return const [];
    final d = a.startsAt;
    return [
      MyMatch(
        opponent: 'Goh and Kamal',
        at: _on(d, 9, 0),
        court: 'Court 2',
        state: MatchState.done,
        stage: 'Group B',
        score: '21–17, 21–19',
        won: true,
      ),
      MyMatch(
        opponent: 'Tan and Lee',
        at: _on(d, 10, 20),
        court: 'Court 4',
        state: MatchState.called,
        stage: 'Group B',
      ),
      MyMatch(
        opponent: 'Ong and Lim',
        at: _on(d, 11, 40),
        court: 'Court 4',
        state: MatchState.later,
        stage: 'Group B',
      ),
    ];
  }

  @override
  Future<TournamentResult?> result(String id) async {
    await _tick();
    final a = _a(id);
    if (a.myStatus != MyStatus.joined) return null;
    final sat = a.startsAt;
    final sun = a.endsAt;
    return TournamentResult(
      division: 'Mixed doubles',
      place: 3,
      wins: 4,
      losses: 1,
      entries: 16,
      podium: const ['Tan and Lee', 'Goh and Raman', 'You and Priya'],
      ratingFrom: 5.4,
      ratingTo: 5.6,
      points: 6,
      matches: [
        MyMatch(
          opponent: 'Goh and Kamal',
          at: _on(sat, 9, 0),
          court: 'Court 2',
          state: MatchState.done,
          stage: 'Group B',
          score: '2–0',
          won: true,
        ),
        MyMatch(
          opponent: 'Tan and Lee',
          at: _on(sat, 10, 20),
          court: 'Court 4',
          state: MatchState.done,
          stage: 'Group B',
          score: '2–1',
          won: true,
        ),
        MyMatch(
          opponent: 'Ong and Lim',
          at: _on(sat, 11, 40),
          court: 'Court 4',
          state: MatchState.done,
          stage: 'Group B',
          score: '2–0',
          won: true,
        ),
        MyMatch(
          opponent: 'Goh and Raman',
          at: _on(sun, 10, 0),
          court: 'Court 1',
          state: MatchState.done,
          stage: 'Semi-final',
          score: '0–2',
          won: false,
        ),
        MyMatch(
          opponent: 'Lim and Ho',
          at: _on(sun, 12, 0),
          court: 'Court 2',
          state: MatchState.done,
          stage: '3rd place',
          score: '2–1',
          won: true,
        ),
      ],
    );
  }

  @override
  Future<List<PartnerPick>> partners(String id) async {
    await _tick();
    return [
      PartnerPick(_w.players['cp-priyar']!, 'MI · 8 Meets together'),
      PartnerPick(_w.players['cp-kelvin']!, 'MI · 3 Meets together'),
      PartnerPick(_w.players['cp-danielt']!, 'LI · 2 Meets together'),
    ];
  }

  @override
  Future<void> register(
    String id, {
    required List<String> divisionIds,
    String? partnerId,
  }) async {
    await _tick();
    final divisions = _divisions(id);
    final picked = divisions.where((d) => divisionIds.contains(d.id)).toList();
    if (picked.isEmpty) throw const AuthFailure('Choose at least one event.');
    final first = picked.first;
    final entry = picked.fold(0, (a, d) => d.full ? a : a + d.feeCents);
    final fee = picked.fold(
      0,
      (a, d) => d.full ? a : a + platformFee(d.feeCents),
    );
    _mine[id] = MyEntry(
      divisionId: first.id,
      divisionName: first.name,
      partner: partnerId == null ? null : _w.players[partnerId],
      paidCents: entry + fee,
      entryCents: entry,
    );
    _play.edit(
      id,
      (a) =>
          a.copyWith(myStatus: MyStatus.joined, spotsTaken: a.spotsTaken + 1),
    );
  }

  @override
  Future<int> withdraw(
    String id, {
    required bool toWallet,
    required bool injury,
  }) async {
    await _tick();
    final a = _a(id);
    final mine = _mine.remove(id);
    _play.edit(
      id,
      (a) => a.copyWith(myStatus: MyStatus.none, spotsTaken: a.spotsTaken - 1),
    );
    if (mine == null) return 0;
    final open =
        a.registrationClosesAt == null ||
        DateTime.now().isBefore(a.registrationClosesAt!);
    if (!open && !injury) return 0;
    return toWallet ? mine.paidCents : mine.entryCents;
  }

  @override
  Future<void> setCheckedIn(String id, String entryId, bool here) async {
    await _tick();
    here ? _checkedIn.add(entryId) : _checkedIn.remove(entryId);
  }

  @override
  Future<int> message(
    String id, {
    required String to,
    required String text,
  }) async {
    await _tick();
    if (text.trim().isEmpty) throw const AuthFailure('Write a message first.');
    return _divisions(id).fold<int>(0, (a, d) => a + d.entries);
  }

  @override
  Future<void> cancel(String id, {String message = ''}) async {
    await _tick();
    _play.remove(id);
  }

  @override
  Future<void> answerInvite(
    String id,
    String entryId, {
    required bool accept,
  }) => _tick();

  // The demo draw is fixed, so there's nothing to run.
  @override
  Future<List<DrawMatch>> matches(String id, {String? divisionId}) async =>
      const [];

  @override
  Future<int> makeDraw(String id, String divisionId) async {
    await _tick();
    throw const AuthFailure('The sample draw is already made.');
  }

  @override
  Future<void> callMatch(String matchId) => _tick();

  @override
  Future<void> saveScore(String matchId, List<(int, int)> games) => _tick();
}

class DemoEventRepository implements EventRepository {
  DemoEventRepository(this._play);

  final DemoPlayRepository _play;
  final _tickets = <String, int>{'e-finals': 2};
  final _paid = <String, int>{'e-finals': 2400};
  final _reminders = <String, Set<String>>{
    'e-finals': {'s1'},
    'e-festival': {'s1'},
  };
  var _cheersA = 812;
  var _cheersB = 544;
  var _scanned = 148;

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 200));

  Activity _a(String id) {
    final a = _play.byId(id);
    if (a == null) throw const AuthFailure("This isn't available any more.");
    return a;
  }

  List<ProgrammeItem> _programme(String id) {
    final on = _reminders[id] ?? const {};
    ProgrammeItem item(
      String key,
      String time,
      String title,
      String sub, {
      bool plain = false,
    }) => ProgrammeItem(
      id: key,
      time: time,
      title: title,
      sub: sub,
      plain: plain,
      reminded: on.contains(key),
    );
    return switch (id) {
      'e-finals' => [
        item(
          's1',
          '2:40 PM',
          "Women's singles final",
          'Siti Lim vs Mei Ling · Court 1',
        ),
        item(
          's2',
          '3:30 PM',
          'Mixed doubles final',
          'Raman / Chandran vs TBC · Court 1',
        ),
        item(
          's3',
          '4:20 PM',
          "Women's doubles final",
          'Goh / Kamal vs Lim / Ho · Court 1',
        ),
        item('s4', '5:30 PM', 'Prize giving', 'Main stage', plain: true),
      ],
      _ => [
        item('s1', '10:00 AM', 'Opening and warm-up', 'Main stage · everyone'),
        item(
          's2',
          '10:30 AM',
          'Badminton try-out',
          'Tampines Smashers · Courts 1 – 4',
        ),
        item('s3', '12:00 PM', 'Smash clinic', 'Coach Ravi · 30 spots'),
        item(
          's4',
          '2:00 PM',
          'Pickleball open play',
          'East Dinkers · Courts 5 – 8',
        ),
        item('s5', '5:00 PM', 'Kids’ relay games', 'Field · ages 6 – 12'),
      ],
    };
  }

  @override
  Future<EventInfo> info(String id) async {
    await _tick();
    final a = _a(id);
    final finals = id == 'e-finals';
    return EventInfo(
      activity: a,
      about:
          a.description ??
          (finals
              ? 'Finals of the Tampines Open 2026. Five finals on Court 1 from '
                    '2 PM, with live scores in the app. Seats are first come, '
                    'first served.'
              : 'Try-outs with 12 local clubs, coach clinics every hour, gear '
                    'booths and kids’ games. Open to all ages and levels.'),
      programme: _programme(id),
      programmeDay: Fmt.day(a.startsAt),
      clubs: finals
          ? const [EventClub('TS', 'Tampines Smashers', 0xFF16181B, 0xFFF2C14E)]
          : const [
              EventClub('TS', 'Tampines Smashers', 0xFF16181B, 0xFFF2C14E),
              EventClub('ED', 'East Dinkers', 0xFF0E6B4E, 0xFFFFFFFF),
              EventClub('BR', 'Bedok Racquets', 0xFF3E6B8A, 0xFFFFFFFF),
              EventClub('PS', 'Pasir Smash', 0xFFC8553D, 0xFFFFFFFF),
            ],
      partOfId: finals ? 't-open' : a.linkedId,
      partOfTitle: finals
          ? 'Tampines Open 2026'
          : (a.linkedId == null ? null : _play.byId(a.linkedId!)?.title),
      live: finals && a.live
          ? LiveCourt(
              label: "COURT 1 · MEN'S DOUBLES FINAL",
              sideA: 'Wei Ming Chua / Kenji Wong',
              sideB: 'Marcus Lee / Jun Tan',
              gamesA: const [21, 14],
              gamesB: const [18, 16],
              cheersA: _cheersA,
              cheersB: _cheersB,
            )
          : null,
      gear: finals
          ? const [
              GearPick(
                name: 'Astrox 88D Pro',
                priceCents: 21900,
                player: 'Wei Ming Chua',
                racket: true,
              ),
              GearPick(
                name: 'Power Cushion 65 Z',
                priceCents: 15900,
                player: 'Marcus Lee',
                racket: false,
              ),
            ]
          : const [],
      tickets: _tickets[id] ?? 0,
      paidCents: _paid[id] ?? 0,
      refundBy: a.startsAt.subtract(const Duration(days: 1)),
      scannedIn: _scanned,
    );
  }

  @override
  Future<Ticket> buy(String id, {required int qty}) async {
    await _tick();
    final a = _a(id);
    _tickets[id] = (_tickets[id] ?? 0) + qty;
    _paid[id] = (_paid[id] ?? 0) + a.totalCents * qty;
    _play.edit(
      id,
      (a) =>
          a.copyWith(myStatus: MyStatus.joined, spotsTaken: a.spotsTaken + qty),
    );
    return (await ticket(id))!;
  }

  @override
  Future<Ticket?> ticket(String id) async {
    await _tick();
    final a = _a(id);
    final qty = _tickets[id] ?? 0;
    if (qty == 0) return null;
    return Ticket(
      eventId: id,
      title: a.title,
      startsAt: a.startsAt,
      endsAt: a.endsAt,
      venue: '${a.venue.name}, ${a.venue.address}',
      qty: qty,
      paidCents: _paid[id] ?? 0,
      code: 'OG-${id.hashCode.abs() % 900000 + 100000}',
      refundBy: a.startsAt.subtract(const Duration(days: 1)),
    );
  }

  @override
  Future<int> release(String id, {required int qty}) async {
    await _tick();
    final a = _a(id);
    final had = _tickets[id] ?? 0;
    final n = qty.clamp(0, had);
    final paid = _paid[id] ?? 0;
    final back = had == 0 ? 0 : paid * n ~/ had;
    _tickets[id] = had - n;
    _paid[id] = paid - back;
    _play.edit(
      id,
      (a) => a.copyWith(
        myStatus: had - n == 0 ? MyStatus.none : MyStatus.joined,
        spotsTaken: a.spotsTaken - n,
      ),
    );
    final inTime = DateTime.now().isBefore(
      a.startsAt.subtract(const Duration(days: 1)),
    );
    return inTime ? back : 0;
  }

  @override
  Future<void> cheer(String id, {required bool sideA}) async {
    sideA ? _cheersA++ : _cheersB++;
  }

  @override
  Future<void> remind(String id, String itemId, bool on) async {
    final set = _reminders.putIfAbsent(id, () => {});
    on ? set.add(itemId) : set.remove(itemId);
  }

  @override
  Future<ScanResult> scan(String id, String code) async {
    await _tick();
    final a = _a(id);
    _scanned++;
    return ScanResult(
      valid: true,
      qty: 2,
      bookedBy: 'Jessie Tan',
      title: a.title,
      scanned: _scanned,
      capacity: a.spotsTaken,
    );
  }

  @override
  Future<void> cancel(String id, {String message = ''}) async {
    await _tick();
    _play.remove(id);
  }
}
