/// Where a campaign is in its life.
enum CampaignState {
  live('Live'),
  upcoming('Upcoming'),
  ended('Ended');

  const CampaignState(this.label);
  final String label;
}

/// What a campaign asks for.
enum CampaignKind { meets, workout, creator, predictor }

/// A reward line: what you do, and what you get.
class Reward {
  const Reward(this.condition, this.prize);
  final String condition;
  final String prize;
}

/// A leaderboard line.
class Standing {
  const Standing({
    required this.rank,
    required this.name,
    required this.sub,
    required this.score,
    this.mine = false,
  });

  final int rank;
  final String name;
  final String sub;

  /// "1:52", "92", "6.4".
  final String score;
  final bool mine;

  String get initials => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0])
      .take(2)
      .join()
      .toUpperCase();
}

/// One exercise in a workout set.
class Exercise {
  const Exercise(this.name, this.form, this.reps);
  final String name;

  /// "Hips below knees, heels down".
  final String form;
  final int reps;
}

/// A campaign, workout challenge or creator challenge.
class Campaign {
  const Campaign({
    required this.id,
    required this.kind,
    required this.state,
    required this.title,
    required this.task,
    required this.meta,
    required this.reward,
    required this.color,
    required this.ink,
    this.by,
    this.endsAt,
    this.about = '',
    this.target = 0,
    this.progress = 0,
    this.joined = false,
    this.players = 0,
    this.progressNote = '',
    this.counted = const [],
    this.rewards = const [],
    this.rules = const [],
    this.exercises = const [],
    this.bestSeconds,
    this.rank,
    this.attempts = 0,
    this.standings = const [],
    this.sponsor,
    this.result,
  });

  final String id;
  final CampaignKind kind;
  final CampaignState state;
  final String title;

  /// "Play 5 ranked Meets this month".
  final String task;

  /// "Ends Sat 31 Oct · 2,140 players in".
  final String meta;

  /// The headline reward on the card.
  final String reward;
  final int color;
  final int ink;

  /// The creator who runs it.
  final String? by;
  final DateTime? endsAt;
  final String about;
  final int target;
  final int progress;
  final bool joined;
  final int players;
  final String progressNote;

  /// What has counted so far: title and line.
  final List<(String, String)> counted;
  final List<Reward> rewards;
  final List<String> rules;
  final List<Exercise> exercises;
  final int? bestSeconds;
  final int? rank;
  final int attempts;
  final List<Standing> standings;

  /// The shop paying for a paid partnership.
  final String? sponsor;

  /// What happened, for ended campaigns.
  final String? result;

  int get totalReps => exercises.fold(0, (a, e) => a + e.reps);

  Campaign copyWith({
    bool? joined,
    int? bestSeconds,
    int? rank,
    int? attempts,
    List<Standing>? standings,
  }) => Campaign(
    id: id,
    kind: kind,
    state: state,
    title: title,
    task: task,
    meta: meta,
    reward: reward,
    color: color,
    ink: ink,
    by: by,
    endsAt: endsAt,
    about: about,
    target: target,
    progress: progress,
    joined: joined ?? this.joined,
    players: players + ((joined ?? this.joined) && !this.joined ? 1 : 0),
    progressNote: progressNote,
    counted: counted,
    rewards: rewards,
    rules: rules,
    exercises: exercises,
    bestSeconds: bestSeconds ?? this.bestSeconds,
    rank: rank ?? this.rank,
    attempts: attempts ?? this.attempts,
    standings: standings ?? this.standings,
    sponsor: sponsor,
    result: result,
  );
}

/// How one workout attempt went.
class AttemptResult {
  const AttemptResult({
    required this.seconds,
    required this.rank,
    required this.of,
    required this.valid,
    required this.redone,
    required this.splits,
    required this.best,
    this.tip = '',
  });

  final int seconds;
  final int rank;
  final int of;
  final int valid;
  final int redone;

  /// Exercise, line, time.
  final List<(String, String, String)> splits;

  /// A new personal best.
  final bool best;
  final String tip;
}

/// "2:31".
String clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// A creator's public page.
class Creator {
  const Creator({
    required this.id,
    required this.name,
    required this.handle,
    required this.line,
    required this.followers,
    required this.videos,
    required this.challenges,
    this.following = false,
    this.verified = true,
    this.running,
    this.videoViews = const [],
    this.gear = const [],
    this.academy,
    this.academyLine,
  });

  final String id;
  final String name;
  final String handle;

  /// "Badminton coach · Smash Academy".
  final String line;
  final int followers;
  final int videos;
  final int challenges;
  final bool following;
  final bool verified;
  final Campaign? running;
  final List<int> videoViews;

  /// Product name, shop and line, price.
  final List<(String, String, String)> gear;
  final String? academy;
  final String? academyLine;
}

/// What a creator has earned.
class CreatorEarnings {
  const CreatorEarnings({
    required this.readyCents,
    required this.views,
    required this.sold,
    required this.students,
    required this.sources,
    required this.videos,
  });

  final int readyCents;
  final int views;
  final int sold;
  final int students;

  /// Title, line, cents.
  final List<(String, String, int)> sources;
  final List<(String, String, int)> videos;
}

/// The creator's own challenges and follower standing.
class CreatorStatus {
  const CreatorStatus({
    required this.followers,
    required this.threshold,
    this.graceEnds,
    this.mine = const [],
  });

  final int followers;

  /// 1,000 followers unlock challenges.
  final int threshold;

  /// Set when they dropped below the threshold.
  final DateTime? graceEnds;
  final List<Campaign> mine;

  bool get unlocked => followers >= threshold || graceEnds != null;
}

enum GearType {
  badmintonRacquet('Badminton racquet'),
  tennisRacquet('Tennis racquet'),
  tableTennisBat('Table tennis bat'),
  pickleballPaddle('Pickleball paddle'),
  shoes('Shoes');

  const GearType(this.label);
  final String label;

  bool get strung => this == badmintonRacquet || this == tennisRacquet;
}

/// Something the player plays with.
class Gear {
  const Gear({
    required this.id,
    required this.type,
    required this.brand,
    required this.model,
    this.specs = const [],
    this.priceCents,
  });

  final String id;
  final GearType type;
  final String brand;
  final String model;

  /// Label and value: "Weight", "4U (83 g)".
  final List<(String, String)> specs;
  final int? priceCents;

  String get name => '$brand $model';
}
