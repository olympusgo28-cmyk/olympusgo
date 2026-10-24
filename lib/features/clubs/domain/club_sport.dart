import '../../../core/widgets/og_icon.dart';
import '../../onboarding/domain/sport.dart';

/// Sports a club or team can play. Wider than the sign-up list: clubs also
/// run squash and Hyrox.
enum ClubSport {
  badminton('badminton', 'Badminton', OgIcons.sportBadminton),
  tennis('tennis', 'Tennis', OgIcons.sportTennis),
  pickleball('pickleball', 'Pickleball', OgIcons.sportPickleball),
  tableTennis('table_tennis', 'Table tennis', OgIcons.sportTableTennis),
  squash('squash', 'Squash', OgIcons.sportSquash),
  padel('padel', 'Padel', OgIcons.sportPadel),
  running('running', 'Running', OgIcons.sportRunning),
  hyrox('hyrox', 'Hyrox', OgIcons.sportHyrox);

  const ClubSport(this.id, this.label, this.icon);

  /// Value stored in the database.
  final String id;
  final String label;
  final String icon;

  static ClubSport fromId(String id) => values.firstWhere((s) => s.id == id);

  /// The matching Play sport, so club Meets show up in Play.
  Sport get playSport => switch (this) {
    badminton => Sport.badminton,
    tennis => Sport.tennis,
    pickleball => Sport.pickleball,
    tableTennis => Sport.tableTennis,
    padel => Sport.padel,
    running => Sport.running,
    squash => Sport.squash,
    hyrox => Sport.hyrox,
  };

  static ClubSport? fromPlay(Sport sport) {
    for (final s in values) {
      if (s.playSport == sport) return s;
    }
    return null;
  }
}

/// The eight named bands of the 1.0 to 8.0 scale, as clubs show them.
enum SkillBand {
  lb('LB', 'Low Beginner'),
  mb('MB', 'Mid Beginner'),
  hb('HB', 'High Beginner'),
  li('LI', 'Low Intermediate'),
  mi('MI', 'Mid Intermediate'),
  hi('HI', 'High Intermediate'),
  ad('AD', 'Advanced'),
  pro('PRO', 'Professional');

  const SkillBand(this.code, this.label);
  final String code;
  final String label;

  /// The band a 1.0 to 8.0 rating falls in.
  static SkillBand forLevel(double level) =>
      values[(level.floor() - 1).clamp(0, values.length - 1)];
}

/// A club's lowest and highest band for one sport, as band indexes.
class LevelRange {
  const LevelRange(this.min, this.max);
  const LevelRange.all() : min = 0, max = 7;

  final int min;
  final int max;

  bool get isAll => min == 0 && max == SkillBand.values.length - 1;
  SkillBand get low => SkillBand.values[min];
  SkillBand get high => SkillBand.values[max];

  /// "LI–HI", or "All levels".
  String get label => isAll ? 'All levels' : '${low.code}–${high.code}';

  /// "LI to AD", as the public club page writes it.
  String get spoken => isAll ? 'All levels' : '${low.code} to ${high.code}';

  bool contains(SkillBand band) => band.index >= min && band.index <= max;

  @override
  bool operator ==(Object other) =>
      other is LevelRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);
}
