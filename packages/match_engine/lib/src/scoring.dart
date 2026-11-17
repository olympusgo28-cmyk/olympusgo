/// How a game and a match are won.
class ScoringPreset {
  const ScoringPreset({
    required this.pointsToWin,
    this.winBy = 2,
    this.cap,
    this.bestOf = 3,
  });

  factory ScoringPreset.fromJson(Map<String, dynamic> j) => ScoringPreset(
    pointsToWin: j['points_to_win'] as int? ?? 0,
    winBy: j['win_by'] as int? ?? 2,
    cap: j['cap'] as int?,
    bestOf: j['best_of'] as int? ?? 3,
  );

  /// 0 when a format has no rules: any game that isn't level stands.
  final int pointsToWin;
  final int winBy;

  /// Whoever reaches this first wins, whatever the lead.
  final int? cap;
  final int bestOf;

  static const badminton = ScoringPreset(pointsToWin: 21, cap: 30);
  static const pickleball = ScoringPreset(pointsToWin: 11);

  int get gamesToWin => bestOf ~/ 2 + 1;

  /// Who won a game from its final score: 1 or 2, 0 while a side is missing,
  /// -1 when the score can't happen.
  int gameWinner(int? a, int? b) {
    if (a == null || b == null) return 0;
    if (pointsToWin == 0) return a == b ? -1 : (a > b ? 1 : 2);
    final hi = a > b ? a : b;
    final lo = a > b ? b : a;
    final won =
        (hi == pointsToWin && hi - lo >= winBy) ||
        (hi > pointsToWin && (cap == null || hi < cap!) && hi - lo == winBy) ||
        (cap != null && hi == cap && hi - lo >= 1 && lo >= cap! - winBy);
    if (!won || hi == lo) return -1;
    return a > b ? 1 : 2;
  }

  /// A side has won enough games, every game typed is a real score, and no
  /// game was played after the match was over.
  bool matchDecided(List<(int?, int?)> games) {
    var a = 0, b = 0;
    for (final g in games) {
      if (g.$1 == null && g.$2 == null) continue;
      if (a == gamesToWin || b == gamesToWin) return false;
      final r = gameWinner(g.$1, g.$2);
      if (r <= 0) return false;
      r == 1 ? a++ : b++;
    }
    return a == gamesToWin || b == gamesToWin;
  }
}
