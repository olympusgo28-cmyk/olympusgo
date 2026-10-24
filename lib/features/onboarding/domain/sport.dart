import '../../../core/widgets/og_icon.dart';

/// Sports a player can add to a Passport or play.
enum Sport {
  badminton('badminton', 'Badminton', OgIcons.badminton),
  pickleball('pickleball', 'Pickleball', OgIcons.pickleball),
  tennis('tennis', 'Tennis', OgIcons.tennis),
  padel('padel', 'Padel', OgIcons.padel),
  tableTennis('table_tennis', 'Table tennis', OgIcons.tableTennis),
  basketball('basketball', 'Basketball', OgIcons.basketball),
  football('football', 'Football', OgIcons.football),
  running('running', 'Running', OgIcons.running),
  swimming('swimming', 'Swimming', OgIcons.swimming),
  cycling('cycling', 'Cycling', OgIcons.cycling),
  squash('squash', 'Squash', OgIcons.sportSquash),
  hyrox('hyrox', 'Hyrox', OgIcons.sportHyrox);

  const Sport(this.id, this.label, this.icon);

  /// Value stored in the database.
  final String id;
  final String label;
  final String icon;

  static Sport fromId(String id) => values.firstWhere((s) => s.id == id);

  /// Offered at sign-up, in the design's order.
  static const signUp = [
    badminton,
    pickleball,
    tennis,
    padel,
    tableTennis,
    basketball,
    football,
    running,
    swimming,
    cycling,
  ];

  /// Offered in Play, in the design's order.
  static const play = [
    badminton,
    pickleball,
    tennis,
    tableTennis,
    squash,
    padel,
    running,
    hyrox,
  ];
}

/// The 1.0 to 8.0 skill scale, in half steps. Whole numbers carry a name.
abstract final class SkillScale {
  static const min = 1.0;
  static const max = 8.0;

  static final _names = <double, String>{
    1.0: 'Low Beginner',
    2.0: 'Mid Beginner',
    3.0: 'High Beginner',
    4.0: 'Low Intermediate',
    5.0: 'Mid Intermediate',
    6.0: 'High Intermediate',
    7.0: 'Advanced',
    8.0: 'Expert',
  };

  /// Whole levels only: 1.0, 2.0 … 8.0.
  static List<double> get levels => [for (var v = min; v <= max; v += 1) v];

  static String describe(double level) {
    final name = _names[level];
    final n = level.toStringAsFixed(1);
    return name == null ? n : '$n · $name';
  }
}
