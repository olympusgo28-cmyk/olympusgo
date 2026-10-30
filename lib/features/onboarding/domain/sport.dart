import '../../../core/widgets/og_icon.dart';

/// A sport. Staff can add new ones, so this is not a fixed list: the ones
/// below have their own icons, and any other comes from the catalogue.
class Sport {
  const Sport(this.id, this.label, this.icon);

  /// Value stored in the database.
  final String id;
  final String label;
  final String icon;

  static const badminton = Sport('badminton', 'Badminton', OgIcons.badminton);
  static const pickleball = Sport(
    'pickleball',
    'Pickleball',
    OgIcons.pickleball,
  );
  static const tennis = Sport('tennis', 'Tennis', OgIcons.tennis);
  static const padel = Sport('padel', 'Padel', OgIcons.padel);
  static const tableTennis = Sport(
    'table_tennis',
    'Table tennis',
    OgIcons.tableTennis,
  );
  static const basketball = Sport(
    'basketball',
    'Basketball',
    OgIcons.basketball,
  );
  static const football = Sport('football', 'Football', OgIcons.football);
  static const running = Sport('running', 'Running', OgIcons.running);
  static const swimming = Sport('swimming', 'Swimming', OgIcons.swimming);
  static const cycling = Sport('cycling', 'Cycling', OgIcons.cycling);
  static const squash = Sport('squash', 'Squash', OgIcons.sportSquash);
  static const hyrox = Sport('hyrox', 'Hyrox', OgIcons.sportHyrox);

  static const values = [
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
    squash,
    hyrox,
  ];

  static final _added = <String, Sport>{};

  /// Remembers a sport read from the catalogue.
  static Sport fromCatalogue(String id, String name) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return _added[id] = Sport(id, name, OgIcons.trophy);
  }

  /// Never throws: a sport staff added after this build still shows.
  static Sport fromId(String id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return _added[id] ?? Sport(id, _title(id), OgIcons.trophy);
  }

  static String _title(String id) {
    final words = id.replaceAll('_', ' ');
    return words.isEmpty ? id : words[0].toUpperCase() + words.substring(1);
  }

  /// Position in the design's order. Added sports come last.
  int get index {
    final i = values.indexOf(this);
    return i < 0 ? values.length : i;
  }

  @override
  bool operator ==(Object other) => other is Sport && other.id == id;

  @override
  int get hashCode => id.hashCode;

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
