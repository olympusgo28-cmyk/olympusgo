import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../../clubs/domain/club_sport.dart';
import '../../onboarding/domain/sport.dart';
import '../domain/game_models.dart';

/// Campaigns, workout and creator challenges, leaderboards and gear.
abstract interface class GameRepository {
  Future<List<Campaign>> campaigns();
  Future<Campaign> campaign(String id);
  Future<void> join(String id);

  /// Records a camera-counted attempt. Returns how it went.
  Future<AttemptResult> finishAttempt(
    String id, {
    required int seconds,
    required int redone,
  });
  Future<void> sendForReview(String id, {required String reason});

  Future<Creator> creator(String id);
  Future<void> followCreator(String id, bool on);
  Future<CreatorEarnings> creatorEarnings();
  Future<CreatorStatus> creatorStatus();
  Future<Campaign> createChallenge({
    required String title,
    required String sport,
    required int days,
    required String goal,
    String reward = '',
  });

  /// Local (rating) or Tournament (points) standings.
  Future<List<Standing>> leaderboard({
    required bool local,
    required String sport,
    required String area,
  });

  Future<List<Gear>> gear();
  Future<Gear> saveGear(Gear gear);
}

const _soon = AuthFailure(
  'Game campaigns open with the next release. Your Meets already count.',
);

/// Gear and leaderboards are real. Campaigns and creator challenges have no
/// tables yet: lists are empty and actions explain why.
class SupabaseGameRepository implements GameRepository {
  SupabaseGameRepository(this._client);
  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Game error: ${e.code} ${e.message}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      if (e.code == '23514') {
        throw const AuthFailure('Check the brand, model and price.');
      }
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Game network error: $e');
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  /// Club areas that count as each leaderboard area.
  static const _areas = {
    'Tampines': ['%Tampines%'],
    'East': [
      '%Tampines%',
      '%Bedok%',
      '%Pasir Ris%',
      '%Simei%',
      '%Changi%',
      '%Tanah Merah%',
      '%Paya Lebar%',
      '%Eunos%',
      '%Kembangan%',
      '%Loyang%',
      '%Marine Parade%',
      '%East Coast%',
      '%Siglap%',
      '%East%',
    ],
  };

  @override
  Future<List<Campaign>> campaigns() async => const [];
  @override
  Future<Campaign> campaign(String id) => throw _soon;
  @override
  Future<void> join(String id) => throw _soon;
  @override
  Future<AttemptResult> finishAttempt(
    String id, {
    required int seconds,
    required int redone,
  }) => throw _soon;
  @override
  Future<void> sendForReview(String id, {required String reason}) =>
      throw _soon;
  @override
  Future<Creator> creator(String id) => throw _soon;
  @override
  Future<void> followCreator(String id, bool on) => throw _soon;
  @override
  Future<CreatorEarnings> creatorEarnings() => throw _soon;
  @override
  Future<CreatorStatus> creatorStatus() async =>
      const CreatorStatus(followers: 0, threshold: 1000);
  @override
  Future<Campaign> createChallenge({
    required String title,
    required String sport,
    required int days,
    required String goal,
    String reward = '',
  }) => throw _soon;
  @override
  Future<List<Standing>> leaderboard({
    required bool local,
    required String sport,
    required String area,
  }) => _guard(() async {
    final id = Sport.values
        .firstWhere((s) => s.label == sport, orElse: () => Sport.badminton)
        .id;
    final rows = (await _client.rpc(
      local ? 'leaderboard_rating' : 'leaderboard_points',
      params: {
        'p_sport': id,
        if (local) 'p_areas': _areas[area] ?? const <String>[],
      },
    )) as List;
    return [
      for (final (i, r) in rows.cast<Map>().indexed)
        local
            ? Standing(
                rank: i + 1,
                name: r['name'] as String,
                score: (r['level'] as num).toStringAsFixed(1),
                sub:
                    '${r['games']} ${r['games'] == 1 ? 'match' : 'matches'} · '
                    '${SkillBand.forLevel((r['level'] as num).toDouble()).code}',
                mine: r['mine'] == true,
              )
            : Standing(
                rank: i + 1,
                name: r['name'] as String,
                score: _thousands(r['points'] as int),
                sub: r['best'] as String? ?? '',
                mine: r['mine'] == true,
              ),
    ];
  });

  static String _thousands(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  static Gear _gear(Map<String, dynamic> r) => Gear(
    id: r['id'] as String,
    type: GearType.values.byName(r['type'] as String),
    brand: r['brand'] as String,
    model: r['model'] as String,
    specs: [
      for (final s in (r['specs'] as List?) ?? const [])
        ((s as List)[0] as String, s[1] as String),
    ],
    priceCents: r['price_cents'] as int?,
  );

  @override
  Future<List<Gear>> gear() => _guard(() async {
    final rows = await _client.from('player_gear').select().order('created_at');
    return [for (final r in rows) _gear(r)];
  });

  @override
  Future<Gear> saveGear(Gear gear) => _guard(() async {
    final row = {
      'type': gear.type.name,
      'brand': gear.brand.trim(),
      'model': gear.model.trim(),
      'specs': [
        for (final (k, v) in gear.specs)
          if (v.trim().isNotEmpty) [k, v.trim()],
      ],
      'price_cents': gear.priceCents,
    };
    final saved = gear.id.isEmpty || gear.id.startsWith('new')
        ? await _client.from('player_gear').insert(row).select().single()
        : await _client
              .from('player_gear')
              .update(row)
              .eq('id', gear.id)
              .select()
              .single();
    return _gear(saved);
  });
}

class DemoGameRepository implements GameRepository {
  DemoGameRepository() {
    _seed();
  }

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 200));

  final _campaigns = <Campaign>[];
  final _following = <String>{};
  final _gear = <Gear>[
    const Gear(
      id: 'g1',
      type: GearType.badmintonRacquet,
      brand: 'Yonex',
      model: 'Astrox 99 Pro',
      priceCents: 28900,
      specs: [
        ('Weight', '4U (83 g)'),
        ('Balance', 'Head heavy'),
        ('Flex', 'Stiff'),
        ('Grip size', 'G5'),
        ('String', 'Yonex BG65 Titanium'),
        ('Vertical (mains)', '26 lbs'),
        ('Horizontal (crosses)', '24 lbs'),
        ('Knots', '4 knots'),
      ],
    ),
    const Gear(
      id: 'g2',
      type: GearType.shoes,
      brand: 'Yonex',
      model: 'Power Cushion 65 Z3',
      priceCents: 23900,
      specs: [
        ('Size', 'UK 8'),
        ('Fit', 'Regular'),
        ('Sole', 'Non-marking gum rubber'),
      ],
    ),
  ];
  int _seq = 0;
  var _status = CreatorStatus(
    followers: 900,
    threshold: 1000,
    graceEnds: DateTime.now().add(const Duration(days: 26)),
  );

  void _seed() {
    final now = DateTime.now();
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59);
    String day(DateTime d) =>
        '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1]} ${d.day} '
        '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]}';
    final in9 = now.add(const Duration(days: 9));
    _campaigns.addAll([
      Campaign(
        id: 'smash-month',
        kind: CampaignKind.meets,
        state: CampaignState.live,
        title: 'Smash Month',
        task: 'Play 5 ranked Meets this month',
        meta: 'Ends ${day(monthEnd)} · 2,140 players in',
        reward: '20 bonus points',
        color: 0xFF17171A,
        ink: 0xFFC6FF00,
        endsAt: monthEnd,
        about: 'Play 5 ranked Meets this month and earn 20 bonus points. Any sport, any club.',
        target: 5,
        progress: 2,
        joined: true,
        players: 2140,
        progressNote: 'Counted when the organizer marks you Present. 3 to go.',
        counted: [
          ('Doubles Social', 'Counted'),
          ('Morning Singles', 'Counted'),
        ],
        rewards: const [
          Reward('Finish all 5', '20 bonus points'),
          Reward('First 500 to finish', 'S\$5 Shop voucher'),
          Reward('Top club by Meets played', 'Club reward voucher doubled'),
        ],
        rules: const [
          'Only ranked Meets where you are marked Present count',
          'One entry per player. Guests do not count',
          'Bonus points arrive within 24 hours of finishing',
        ],
      ),
      Campaign(
        id: 'legs-sprint',
        kind: CampaignKind.workout,
        state: CampaignState.live,
        title: 'Court Legs Sprint',
        task: 'Workout challenge · fastest time with the right form, counted by camera',
        meta: 'Ends ${day(monthEnd)} · 864 players in',
        reward: 'Top 10 win S\$20',
        color: 0xFF0E6B4E,
        ink: 0xFFFFFFFF,
        endsAt: monthEnd,
        about:
            'Finish the set as fast as you can. The camera counts each rep and only '
            'counts it if the form is right. Fastest time wins.',
        players: 864,
        joined: true,
        exercises: const [
          Exercise('Squats', 'Hips below knees, heels down', 20),
          Exercise('Alternating lunges', 'Back knee close to the floor', 20),
          Exercise('Burpees', 'Chest to floor, jump at the top', 10),
        ],
        bestSeconds: 168,
        rank: 37,
        attempts: 3,
        standings: const [
          Standing(
            rank: 1,
            name: 'Mei Ling',
            sub: 'MI 5.4 · 50 of 50 reps valid',
            score: '1:52',
          ),
          Standing(
            rank: 2,
            name: 'Kelvin Ho',
            sub: 'MI 4.8 · 50 of 50 reps valid',
            score: '1:58',
          ),
          Standing(
            rank: 3,
            name: 'Priya Raman',
            sub: 'MI 5.1 · 50 of 50 reps valid',
            score: '2:03',
          ),
        ],
        rewards: const [
          Reward(
            'Finish once with all 50 reps valid',
            '10 bonus points and a badge',
          ),
          Reward('Top 10 times', 'S\$20 Shop voucher'),
        ],
        rules: const [
          'The camera must see your whole body for the whole attempt',
          'A rep with the wrong form is not counted. You repeat it and the clock keeps running',
          'Try as many times as you like. Your best time is kept',
          'Top 10 times are checked from the recording before prizes go out',
        ],
      ),
      Campaign(
        id: 'bring-friend',
        kind: CampaignKind.meets,
        state: CampaignState.live,
        title: 'Bring a Friend Week',
        task: 'Bring a guest to any Meet',
        meta: 'Ends ${day(now.add(const Duration(days: 3)))} · 612 players in',
        reward: 'S\$5 Shop voucher',
        color: 0xFFC8553D,
        ink: 0xFFFFFFFF,
        about: 'Bring a guest to any Meet this week. Both of you play, you earn a voucher.',
        target: 1,
        players: 612,
        progressNote: 'Counted when your guest is marked Present.',
        rewards: const [Reward('Bring 1 guest', 'S\$5 Shop voucher')],
        rules: const [
          'Your guest must be marked Present',
          'One voucher per player',
        ],
      ),
      Campaign(
        id: 'net-kills',
        kind: CampaignKind.creator,
        state: CampaignState.live,
        title: '100 net kills in a week',
        task: 'By Coach Ravi · creator challenge',
        meta: '9 days left · 1,284 players in',
        reward: '1 hour with Coach Ravi',
        color: 0xFF2F3A5F,
        ink: 0xFFFFFFFF,
        by: 'Coach Ravi',
        endsAt: in9,
        target: 100,
        progress: 37,
        joined: true,
        players: 1284,
        progressNote: 'Counted from scores and from clips you post. 63 to go.',
        rules: [
          'Play any ranked game or post a drill clip',
          'Each net kill a camera or your partner confirms counts once',
          'Reach 100 by ${day(in9)}, 11:59 PM',
        ],
        rewards: const [
          Reward('Everyone who finishes', 'Challenge badge and 10 points'),
          Reward('Top 3', '1 hour on court with Coach Ravi'),
        ],
        standings: const [
          Standing(rank: 1, name: 'Mei Ling', sub: 'MI 5.4', score: '92'),
          Standing(rank: 2, name: 'Kelvin Ho', sub: 'MI 4.8', score: '88'),
          Standing(rank: 3, name: 'Priya Raman', sub: 'MI 5.1', score: '71'),
        ],
        sponsor: 'Racket Lab',
      ),
      Campaign(
        id: 'predictor',
        kind: CampaignKind.predictor,
        state: CampaignState.upcoming,
        title: 'Tampines Open Predictor',
        task: 'Pick the finalists before the Open',
        meta: 'Opens next week',
        reward: 'Finals Day tickets',
        color: 0xFF0E6B4E,
        ink: 0xFFFFFFFF,
        about: 'Pick the finalists in each event before the draw closes.',
        rewards: const [Reward('Most correct picks', '2 Finals Day tickets')],
        rules: const [
          'One set of picks per player',
          'Picks lock when the first match starts',
        ],
      ),
      const Campaign(
        id: 'sept-streak',
        kind: CampaignKind.meets,
        state: CampaignState.ended,
        title: 'September Streak',
        task: 'Play 4 weeks in a row',
        meta: 'Ended · 1,902 finished',
        reward: 'You earned 10 points',
        color: 0xFF6B6B70,
        ink: 0xFFFFFFFF,
        target: 4,
        progress: 4,
        joined: true,
        players: 1902,
        result: 'You finished and earned 10 points.',
        rewards: [Reward('Play 4 weeks in a row', '10 points')],
      ),
    ]);
  }

  Campaign _c(String id) => _campaigns.firstWhere(
    (c) => c.id == id,
    orElse: () => throw const AuthFailure('This campaign has ended.'),
  );

  @override
  Future<List<Campaign>> campaigns() async {
    await _tick();
    return List.of(_campaigns);
  }

  @override
  Future<Campaign> campaign(String id) async {
    await _tick();
    return _c(id);
  }

  @override
  Future<void> join(String id) async {
    await _tick();
    final i = _campaigns.indexWhere((c) => c.id == id);
    _campaigns[i] = _campaigns[i].copyWith(joined: true);
  }

  @override
  Future<AttemptResult> finishAttempt(
    String id, {
    required int seconds,
    required int redone,
  }) async {
    await _tick();
    final i = _campaigns.indexWhere((c) => c.id == id);
    final c = _campaigns[i];
    final best = c.bestSeconds == null || seconds < c.bestSeconds!;
    // Rank by time against the made-up field: 1:52 is first, then about one
    // place per 2 seconds.
    final rank = ((seconds - 112) / 2).round().clamp(1, c.players);
    _campaigns[i] = c.copyWith(
      attempts: c.attempts + 1,
      bestSeconds: best ? seconds : c.bestSeconds,
      rank: best ? rank : c.rank,
    );
    final third = seconds ~/ 3;
    return AttemptResult(
      seconds: seconds,
      rank: rank,
      of: c.players,
      valid: c.totalReps,
      redone: redone,
      best: best,
      splits: [
        for (final (k, e) in c.exercises.indexed)
          (
            e.name,
            '${e.reps} valid${k == 0 && redone > 0 ? ' · $redone not counted, too shallow' : ''}',
            clock(k == c.exercises.length - 1 ? seconds - third * 2 : third),
          ),
      ],
      tip: rank > 10
          ? 'You are ${seconds - 134} seconds off the top 10.${redone > 0 ? ' Most time was lost redoing shallow squats.' : ''}'
          : 'You are in the top 10. Your recording is checked before prizes go out.',
    );
  }

  @override
  Future<void> sendForReview(String id, {required String reason}) => _tick();

  @override
  Future<Creator> creator(String id) async {
    await _tick();
    return Creator(
      id: 'ravi',
      name: 'Coach Ravi',
      handle: '@coachravi',
      line: 'Badminton coach · Smash Academy',
      followers: 12400 + (_following.contains('ravi') ? 1 : 0),
      videos: 86,
      challenges: 3,
      following: _following.contains('ravi'),
      running: _c('net-kills'),
      videoViews: const [48000, 31000, 22000, 19000, 12000, 9000],
      gear: const [
        ('Carbon racket 4U', 'Racket Lab · tagged in 14 videos', 'S\$189.00'),
        ('Overgrip, pack of 3', 'Court Supply Co.', 'S\$9.00'),
      ],
      academy: 'Smash Academy',
      academyLine: 'Juniors and adults · Tampines · from S\$180 / month',
    );
  }

  @override
  Future<void> followCreator(String id, bool on) async =>
      on ? _following.add(id) : _following.remove(id);

  @override
  Future<CreatorEarnings> creatorEarnings() async {
    await _tick();
    return const CreatorEarnings(
      readyCents: 68400,
      views: 212000,
      sold: 318,
      students: 41,
      sources: [
        ('Tagged gear sold', '318 items · 5% of each sale', 42600),
        ('Challenge sponsor', 'Racket Lab · 100 net kills', 20000),
        ('Academy referrals', '41 enrolments from your page', 5800),
      ],
      videos: [
        ('Why 4U frames are faster', '48k views · 96 rackets sold', 9072),
        ('3 footwork drills at home', '31k views · 44 items sold', 2210),
      ],
    );
  }

  @override
  Future<CreatorStatus> creatorStatus() async {
    await _tick();
    return _status;
  }

  @override
  Future<Campaign> createChallenge({
    required String title,
    required String sport,
    required int days,
    required String goal,
    String reward = '',
  }) async {
    await _tick();
    if (!_status.unlocked) {
      throw const AuthFailure('Challenges unlock at 1,000 followers.');
    }
    final ends = DateTime.now().add(Duration(days: days));
    final c = Campaign(
      id: 'mine-${++_seq}',
      kind: CampaignKind.creator,
      state: CampaignState.live,
      title: title,
      task: '$sport · ends in $days days',
      meta: '0 joined',
      reward: reward.isEmpty ? 'Challenge badge' : reward,
      color: 0xFF2F3A5F,
      ink: 0xFFFFFFFF,
      by: 'You',
      endsAt: ends,
      about: goal,
      rewards: [
        Reward(
          'Everyone who finishes',
          reward.isEmpty ? 'Challenge badge' : reward,
        ),
      ],
    );
    _campaigns.insert(0, c);
    _status = CreatorStatus(
      followers: _status.followers,
      threshold: _status.threshold,
      graceEnds: _status.graceEnds,
      mine: [c, ..._status.mine],
    );
    return c;
  }

  @override
  Future<List<Standing>> leaderboard({
    required bool local,
    required String sport,
    required String area,
  }) async {
    await _tick();
    List<Standing> rows(List<(String, String, String)> d) => [
      for (final (i, (name, score, sub)) in d.indexed)
        Standing(rank: i + 1, name: name, sub: sub, score: score),
    ];
    if (local && sport == 'Badminton') {
      return rows(const [
        ('Ravi Tan', '6.4', '14 matches · HI'),
        ('Jason Lim', '6.1', '11 matches · HI'),
        ('Nur Hidayah', '6.0', '9 matches · HI'),
        ('Siti Kamal', '5.7', '9 matches · MI'),
        ('Wei Ming Chua', '5.5', '8 matches · MI'),
        ('Daniel Tay', '5.5', '6 matches · MI'),
        ('Kelvin Ho', '5.5', '5 matches · MI'),
      ]);
    }
    if (local) {
      return rows(const [
        ('Siti Kamal', '5.9', '9 matches · MI'),
        ('Kelvin Ho', '5.4', '7 matches · MI'),
        ('Priya Chandra', '5.0', '6 matches · MI'),
        ('Jason Lim', '4.8', '5 matches · LI'),
        ('Ben Ong', '4.6', '4 matches · LI'),
      ]);
    }
    if (sport == 'Badminton') {
      return rows(const [
        ('Lee Jun Hao', '1,240', 'Champion, Singapore Open Amateur (National)'),
        ('Ravi Tan', '960', 'Finalist, East Regional Cup'),
        ('Farah Aziz', '910', 'Champion, East Regional Cup'),
        ('Marcus Tan', '700', 'Semi-finalist, Singapore Open Amateur'),
        ('Jason Lim', '640', 'Champion, Tampines Open 2025'),
        ('Siti Kamal', '520', 'Finalist, Bedok Open'),
      ]);
    }
    return rows(const [
      ('Priya Chandra', '480', 'Champion, Pickleball East Cup'),
      ('Kelvin Ho', '420', 'Finalist, Pickleball East Cup'),
      ('Siti Kamal', '300', 'Semi-finalist, Pickleball East Cup'),
      ('Ben Ong', '180', 'Quarter-finalist, Club Smash Day'),
    ]);
  }

  @override
  Future<List<Gear>> gear() async => List.of(_gear);

  @override
  Future<Gear> saveGear(Gear gear) async {
    await _tick();
    final i = _gear.indexWhere((g) => g.id == gear.id);
    final saved = Gear(
      id: i < 0 ? 'g-${++_seq}' : gear.id,
      type: gear.type,
      brand: gear.brand,
      model: gear.model,
      specs: gear.specs,
      priceCents: gear.priceCents,
    );
    i < 0 ? _gear.add(saved) : _gear[i] = saved;
    return saved;
  }
}
