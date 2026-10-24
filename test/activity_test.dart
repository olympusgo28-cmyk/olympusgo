import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/core/format.dart';
import 'package:olympus_go/features/onboarding/domain/sport.dart';
import 'package:olympus_go/features/play/domain/activity.dart';
import 'package:olympus_go/features/social/domain/social_models.dart';

Activity _meet({
  int fee = 800,
  int capacity = 12,
  int taken = 9,
  ActivityKind kind = ActivityKind.meet,
}) => Activity(
  id: 'a',
  kind: kind,
  title: 'Friday night doubles',
  sports: const [Sport.badminton],
  gameType: GameType.doubles,
  format: ActivityFormat.roundRobin,
  startsAt: DateTime(2026, 10, 16, 19, 30),
  endsAt: DateTime(2026, 10, 16, 21, 30),
  venue: const Venue(
    id: 'v',
    name: 'Kallang Badminton Hall',
    address: '52 Stadium Rd',
  ),
  capacity: capacity,
  spotsTaken: taken,
  feeCents: fee,
  host: const PlayerSummary(id: 'h', fullName: 'Hannah Ong'),
);

void main() {
  test(
    'platform fee is 10%, minimum S\$2, and money formats like the design',
    () {
      // 10%, minimum S\$2.
      expect(platformFee(800), 200);
      expect(platformFee(3000), 300);
      expect(platformFee(0), 0);
      expect(money(880), '8.80');
      // S$6 session plus the S$2 minimum fee.
      expect(_meet(fee: 600).priceLabel, 'S\$ 8');
      expect(_meet(fee: 0).priceLabel, 'Free');
    },
  );

  test('card lines match the design wording', () {
    expect(_meet().eyebrow, 'Badminton · Doubles');
    expect(_meet().availability, '3 spots left');
    expect(_meet(taken: 12).availability, 'Full · waitlist open');
    expect(
      _meet(
        kind: ActivityKind.tournament,
        capacity: 32,
        taken: 20,
      ).availability,
      '32 teams · 12 left',
    );
  });

  test('dates read like the design', () {
    final d = DateTime(2026, 10, 16, 19, 30);
    expect(Fmt.dayTime(d), 'Fri 16 Oct · 7:30 PM');
    expect(Fmt.dayTimeComma(d), 'Fri 16 Oct, 7:30 PM');
    expect(
      Fmt.range(DateTime(2026, 11, 7), DateTime(2026, 11, 8)),
      'Sat 7 to Sun 8 Nov',
    );
    expect(Fmt.duration(120), '2 hours');
    expect(Fmt.duration(90), '1.5 hours');
    expect(Fmt.clock(0, 5), '12:05 AM');
  });
}
