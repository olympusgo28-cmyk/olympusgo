import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/onboarding/domain/sport.dart';
import 'package:olympus_go/features/venues/data/venue_repository.dart';
import 'package:olympus_go/features/venues/domain/venue_models.dart';

void main() {
  const venue = VenueDetail(
    id: 'v',
    name: 'Our Tampines Hub',
    address: 'Tampines',
    opensHour: 7,
    closesHour: 23,
    courts: [
      CourtType(
        sport: Sport.badminton,
        count: 2,
        offPeakCents: 1400,
        peakCents: 2200,
      ),
    ],
  );
  final monday = DateTime(2030, 1, 7); // a Monday
  CourtBooking booked(int hour, int hours) => CourtBooking(
    id: '',
    venueId: 'v',
    venueName: '',
    venueAddress: '',
    sport: Sport.badminton,
    court: '',
    start: monday.add(Duration(hours: hour)),
    end: monday.add(Duration(hours: hour + hours)),
    courtCents: 0,
    feeCents: 0,
    doorCode: '',
    code: '',
  );

  test('peak is weekday evenings and all weekend', () {
    expect(
      venue.rateCents(Sport.badminton, monday.add(const Duration(hours: 17))),
      1400,
    );
    expect(
      venue.rateCents(Sport.badminton, monday.add(const Duration(hours: 18))),
      2200,
    );
    expect(
      venue.rateCents(Sport.badminton, monday.add(const Duration(hours: 22))),
      1400,
    );
    expect(venue.rateCents(Sport.badminton, DateTime(2030, 1, 12, 9)), 2200);
  });

  test('a start is taken only when every court is booked for any hour', () {
    final slots = slotsFor(venue, Sport.badminton, monday, 2, [
      booked(19, 1),
      booked(19, 1),
      booked(20, 1),
    ], now: DateTime(2030, 1, 1));
    bool free(int h) => slots.firstWhere((s) => s.start.hour == h).free;
    expect(slots.first.start.hour, 7);
    expect(slots.last.start.hour, 21); // 2 hours must end by closing
    expect(free(17), true);
    expect(free(18), false); // 19:00 is full
    expect(free(19), false);
    expect(free(20), true); // one court left at 20:00
  });

  test('refunds: all to the Wallet, the court price to a card, none late', () {
    final b = booked(20, 2).copyWith(
      start: DateTime.now().add(const Duration(days: 3)),
      end: DateTime.now().add(const Duration(days: 3, hours: 2)),
      courtCents: 4400,
      feeCents: 440,
    );
    expect(b.refundTo(wallet: true), 4840);
    expect(b.refundTo(wallet: false), 4400);
    final late = b.copyWith(
      start: DateTime.now().add(const Duration(hours: 5)),
    );
    expect(late.refundTo(wallet: true), 0);
  });
}
