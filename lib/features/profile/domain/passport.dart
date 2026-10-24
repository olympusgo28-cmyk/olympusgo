import 'package:freezed_annotation/freezed_annotation.dart';

part 'passport.freezed.dart';

/// Season numbers for one sport on the Passport. Built from ranked match
/// results; null until a player has played.
@freezed
abstract class PassportStats with _$PassportStats {
  const factory PassportStats({
    required int winRate,
    required int matches,
    required int meets,
    required String streak,
    required List<bool> form,
    required List<StatCard> cards,
    required List<(String, int)> breakdown,
    required List<MonthPoint> months,
  }) = _PassportStats;
}

@freezed
abstract class StatCard with _$StatCard {
  const factory StatCard({
    required String label,
    required String value,
    required String note,
  }) = _StatCard;
}

@freezed
abstract class MonthPoint with _$MonthPoint {
  const factory MonthPoint({
    required String label,
    required String year,
    required int winRate,
    required int matches,
  }) = _MonthPoint;
}

/// A game on the player's schedule.
@freezed
abstract class UpcomingGame with _$UpcomingGame {
  const factory UpcomingGame({
    required String when,
    required String title,
    required String place,
    @Default(false) bool waitlist,
  }) = _UpcomingGame;
}

enum GearKind { racquet, shoe, paddle }

@freezed
abstract class GearItem with _$GearItem {
  const factory GearItem({
    required String name,
    required String type,
    required GearKind kind,
    @Default([]) List<String> tags,
    String? price,
  }) = _GearItem;
}

/// The design's sample Passport, shown in demo mode.
abstract final class DemoPassport {
  static PassportStats stats(String sport) => sport == 'pickleball'
      ? const PassportStats(
          winRate: 52,
          matches: 16,
          meets: 3,
          streak: '2 W',
          form: [false, true, true, false, true],
          cards: [
            StatCard(
              label: 'Dink win %',
              value: '54%',
              note: '+3.0% vs last month',
            ),
            StatCard(
              label: '3rd-shot drops',
              value: '61%',
              note: '+5.2% vs last month',
            ),
            StatCard(label: 'Serve in %', value: '88%', note: 'steady'),
            StatCard(label: 'Kitchen faults', value: '0.8', note: 'per match'),
            StatCard(label: 'Return depth', value: '47%', note: 'deep returns'),
          ],
          breakdown: [
            ('Dink win %', 54),
            ('Third-shot drops', 61),
            ('Serve in %', 88),
            ('Return depth', 47),
            ('Points won at the kitchen', 57),
            ('Side-outs won', 60),
          ],
          months: _months,
        )
      : const PassportStats(
          winRate: 58,
          matches: 32,
          meets: 9,
          streak: '4 W',
          form: [true, true, false, true, true],
          cards: [
            StatCard(
              label: 'Smash win %',
              value: '62%',
              note: '+4.1% vs last month',
            ),
            StatCard(
              label: 'Net points won',
              value: '58%',
              note: '+2.3% vs last month',
            ),
            StatCard(label: 'Avg rally', value: '7.4', note: 'shots per point'),
            StatCard(label: 'Service errors', value: '1.8', note: 'per match'),
            StatCard(label: 'Unforced errors', value: '9.2', note: 'per match'),
          ],
          breakdown: [
            ('Smash win %', 62),
            ('Net points won', 58),
            ('Serve in %', 86),
            ('Return win %', 49),
            ('Rally wins 9+ shots', 44),
            ('Points won on serve', 63),
          ],
          months: _months,
        );

  static const _months = [
    MonthPoint(label: 'Mar', year: '2026', winRate: 45, matches: 4),
    MonthPoint(label: 'Apr', year: '2026', winRate: 52, matches: 5),
    MonthPoint(label: 'May', year: '2026', winRate: 61, matches: 5),
    MonthPoint(label: 'Jun', year: '2026', winRate: 48, matches: 6),
    MonthPoint(label: 'Jul', year: '2026', winRate: 55, matches: 3),
    MonthPoint(label: 'Aug', year: '2026', winRate: 58, matches: 4),
    MonthPoint(label: 'Sep', year: '2026', winRate: 60, matches: 3),
    MonthPoint(label: 'Oct', year: '2026', winRate: 58, matches: 2),
  ];

  static const upcoming = [
    UpcomingGame(
      when: 'Tue 13 Oct · 7:30 pm',
      title: 'Doubles with Priya Raman',
      place: 'Our Tampines Hub · Court 3',
    ),
    UpcomingGame(
      when: 'Thu 15 Oct · 8:00 pm',
      title: 'Open play Meet',
      place: 'Bedok Sports Hall · Court 2',
      waitlist: true,
    ),
    UpcomingGame(
      when: 'Sat 17 Oct · 10:00 am',
      title: 'Singles vs Daniel Tan',
      place: 'Pasir Ris Sports Centre · Court 1',
    ),
  ];

  static List<GearItem> gear(String sport) => sport == 'pickleball'
      ? const [
          GearItem(
            name: 'Joola Ben Johns Hyperion',
            type: 'Pickleball paddle',
            kind: GearKind.paddle,
            tags: ['16 mm', 'Carbon face'],
            price: 'S\$ 329',
          ),
        ]
      : const [
          GearItem(
            name: 'Yonex Astrox 99 Pro',
            type: 'Badminton racquet',
            kind: GearKind.racquet,
            tags: ['BG65 Titanium', '26 / 24 lbs', '4 knots'],
            price: 'S\$ 289',
          ),
          GearItem(
            name: 'Yonex Power Cushion 65 Z3',
            type: 'Court shoes · UK 8',
            kind: GearKind.shoe,
            price: 'S\$ 239',
          ),
        ];
}
