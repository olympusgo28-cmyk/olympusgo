import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../../onboarding/domain/sport.dart';
import '../../play/domain/activity.dart';
import '../domain/venue_models.dart';

/// Venues, their courts, and court bookings.
abstract interface class VenueRepository {
  Future<List<VenueDetail>> venues();
  Future<VenueDetail> venue(String id);

  /// Bookings of [sport] courts at [venueId] that overlap [day], so the
  /// booking grid can show what is taken.
  Future<List<CourtBooking>> bookingsOn(
    String venueId,
    Sport sport,
    DateTime day,
  );

  /// Pays for and books a court. Returns the booking with its door code.
  Future<CourtBooking> book({
    required VenueDetail venue,
    required Sport sport,
    required DateTime start,
    required int hours,
    required String methodId,
  });

  Future<List<CourtBooking>> myBookings();
  Future<CourtBooking> booking(String id);

  /// Cancels a booking. Returns the amount refunded.
  Future<int> cancel(String id, {required bool toWallet});
}

/// Free start times for one day: hourly from opening, each needing a free
/// court for every hour of [hours]. Starts in the past are left out.
List<CourtSlot> slotsFor(
  VenueDetail venue,
  Sport sport,
  DateTime day,
  int hours,
  List<CourtBooking> taken, {
  DateTime? now,
}) {
  final courts = venue.courtsFor(sport)?.count ?? 0;
  final t = now ?? DateTime.now();
  bool freeAt(DateTime hour) =>
      taken
          .where(
            (b) =>
                b.status == BookingStatus.confirmed &&
                b.start.isBefore(hour.add(const Duration(hours: 1))) &&
                b.end.isAfter(hour),
          )
          .length <
      courts;
  return [
    for (var h = venue.opensHour; h + hours <= venue.closesHour; h++)
      if (DateTime(day.year, day.month, day.day, h).isAfter(t))
        CourtSlot(
          start: DateTime(day.year, day.month, day.day, h),
          rateCents: venue.rateCents(
            sport,
            DateTime(day.year, day.month, day.day, h),
          ),
          free: [
            for (var i = 0; i < hours; i++)
              DateTime(day.year, day.month, day.day, h + i),
          ].every(freeAt),
        ),
  ];
}

class SupabaseVenueRepository implements VenueRepository {
  SupabaseVenueRepository(this._client);
  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  static int? _hex(String? s) => s == null || s.length != 7
      ? null
      : int.tryParse('FF${s.substring(1)}', radix: 16);

  VenueDetail _venue(Map<String, dynamic> r) => VenueDetail(
    id: r['id'] as String,
    name: r['name'] as String,
    address: r['address'] as String,
    opensHour: r['opens_hour'] as int? ?? 7,
    closesHour: r['closes_hour'] as int? ?? 23,
    amenities: [...?(r['amenities'] as List?)?.cast<String>()],
    verified: r['verified'] as bool? ?? false,
    rating: (r['rating'] as num?)?.toDouble(),
    ratingCount: r['rating_count'] as int? ?? 0,
    autoCheckIn: r['auto_check_in'] as bool? ?? false,
    color: _hex(r['color'] as String?) ?? 0xFF16181B,
    ink: _hex(r['ink'] as String?) ?? 0xFFC6FF00,
    courts: [
      for (final c
          in (r['venue_courts'] as List? ?? const [])
              .cast<Map<String, dynamic>>())
        CourtType(
          sport: Sport.fromId(c['sport'] as String),
          count: c['count'] as int,
          offPeakCents: c['off_peak_cents'] as int,
          peakCents: c['peak_cents'] as int,
          note: c['note'] as String? ?? '',
        ),
    ],
  );

  CourtBooking _booking(Map<String, dynamic> r) {
    final v = r['venues'] as Map<String, dynamic>;
    return CourtBooking(
      id: r['id'] as String,
      venueId: r['venue_id'] as String,
      venueName: v['name'] as String,
      venueAddress: v['address'] as String,
      sport: Sport.fromId(r['sport'] as String),
      court: r['court'] as String,
      start: DateTime.parse(r['starts_at'] as String).toLocal(),
      end: DateTime.parse(r['ends_at'] as String).toLocal(),
      courtCents: r['court_cents'] as int,
      feeCents: r['fee_cents'] as int,
      doorCode: r['door_code'] as String? ?? '',
      code: r['code'] as String,
      status: r['status'] == 'cancelled'
          ? BookingStatus.cancelled
          : BookingStatus.confirmed,
      refundCents: r['refund_cents'] as int? ?? 0,
    );
  }

  static const _venueCols = '*, venue_courts(*)';
  static const _bookingCols = '*, venues(name, address)';

  @override
  Future<List<VenueDetail>> venues() => _guard(() async {
    final rows = await _client
        .from('venues')
        .select(_venueCols)
        .eq('bookable', true)
        .order('name');
    return rows.map(_venue).toList();
  });

  @override
  Future<VenueDetail> venue(String id) => _guard(() async {
    final r = await _client
        .from('venues')
        .select(_venueCols)
        .eq('id', id)
        .single();
    return _venue(r);
  });

  @override
  Future<List<CourtBooking>> bookingsOn(
    String venueId,
    Sport sport,
    DateTime day,
  ) => _guard(() async {
    final from = DateTime(day.year, day.month, day.day);
    // Other players' bookings come back without names: only times count.
    final rows = await _client.rpc(
      'court_busy',
      params: {
        'venue': venueId,
        'sport': sport.id,
        'from_at': from.toUtc().toIso8601String(),
        'to_at': from.add(const Duration(days: 1)).toUtc().toIso8601String(),
      },
    ) as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        CourtBooking(
          id: '',
          venueId: venueId,
          venueName: '',
          venueAddress: '',
          sport: sport,
          court: '',
          start: DateTime.parse(r['starts_at'] as String).toLocal(),
          end: DateTime.parse(r['ends_at'] as String).toLocal(),
          courtCents: 0,
          feeCents: 0,
          doorCode: '',
          code: '',
        ),
    ];
  });

  @override
  Future<CourtBooking> book({
    required VenueDetail venue,
    required Sport sport,
    required DateTime start,
    required int hours,
    required String methodId,
  }) async {
    // Court fees are paid by card; that needs the payment provider on the
    // server, the same as paid Meets.
    throw const AuthFailure(
      "Card payments aren't switched on yet. Court booking opens once payments are connected.",
    );
  }

  @override
  Future<List<CourtBooking>> myBookings() => _guard(() async {
    final rows = await _client
        .from('court_bookings')
        .select(_bookingCols)
        .eq('user_id', _client.auth.currentUser!.id)
        .order('starts_at');
    return rows.map(_booking).toList();
  });

  @override
  Future<CourtBooking> booking(String id) => _guard(() async {
    final r = await _client
        .from('court_bookings')
        .select(_bookingCols)
        .eq('id', id)
        .single();
    return _booking(r);
  });

  @override
  Future<int> cancel(String id, {required bool toWallet}) => _guard(
    () async => await _client.rpc(
      'cancel_court_booking',
      params: {'booking': id, 'to_wallet': toWallet},
    ) as int,
  );
}

class DemoVenueRepository implements VenueRepository {
  DemoVenueRepository() {
    final now = DateTime.now();
    final sat = now.add(
      Duration(
        days: (DateTime.saturday - now.weekday) % 7 == 0
            ? 7
            : (DateTime.saturday - now.weekday) % 7,
      ),
    );
    _bookings.add(
      _make(
        id: 'cb-1',
        venue: _venues.first,
        sport: Sport.badminton,
        start: DateTime(sat.year, sat.month, sat.day, 20),
        hours: 2,
        court: 'Court 6',
      ),
    );
  }

  static const _venues = [
    VenueDetail(
      id: 'v-tampines',
      name: 'Our Tampines Hub',
      address: '1 Tampines Walk, Tampines',
      distance: '1.2 km',
      courts: [
        CourtType(
          sport: Sport.badminton,
          count: 12,
          offPeakCents: 1400,
          peakCents: 2200,
        ),
        CourtType(
          sport: Sport.pickleball,
          count: 4,
          offPeakCents: 1600,
          peakCents: 2400,
        ),
      ],
      amenities: [
        'Showers',
        'Lockers',
        'Parking',
        'Racket hire',
        'Water point',
        'Wheelchair access',
      ],
      verified: true,
      rating: 4.7,
      ratingCount: 860,
      autoCheckIn: true,
    ),
    VenueDetail(
      id: 'v-bedok',
      name: 'Bedok Sports Hall',
      address: '1 Bedok North St 2, Bedok',
      distance: '3.4 km',
      courts: [
        CourtType(
          sport: Sport.badminton,
          count: 8,
          offPeakCents: 1200,
          peakCents: 1800,
        ),
      ],
      amenities: ['Showers', 'Lockers', 'Water point'],
      verified: true,
      rating: 4.4,
      ratingCount: 312,
      color: 0xFF2F3A5F,
      ink: 0xFFFFFFFF,
    ),
    VenueDetail(
      id: 'v-pasirris',
      name: 'Pasir Ris Sports Centre',
      address: '120 Pasir Ris Central, Pasir Ris',
      distance: '4.1 km',
      opensHour: 7,
      closesHour: 22,
      courts: [
        CourtType(
          sport: Sport.tennis,
          count: 6,
          offPeakCents: 1800,
          peakCents: 2600,
          note: 'lights till 10 PM',
        ),
      ],
      amenities: ['Showers', 'Parking'],
      rating: 4.5,
      ratingCount: 140,
      color: 0xFF0E6B4E,
      ink: 0xFFFFFFFF,
    ),
    VenueDetail(
      id: 'v-eastcoast',
      name: 'East Coast Park, Area C',
      address: 'East Coast Park Service Rd, Bedok',
      distance: '6.0 km',
      courts: [
        CourtType(
          sport: Sport.pickleball,
          count: 10,
          offPeakCents: 1000,
          peakCents: 1600,
          note: 'outdoor',
        ),
      ],
      amenities: ['Parking', 'Water point'],
      rating: 4.6,
      ratingCount: 228,
      color: 0xFFC8553D,
      ink: 0xFFFFFFFF,
    ),
  ];

  final _bookings = <CourtBooking>[];
  int _n = 1;

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 200));

  CourtBooking _make({
    required String id,
    required VenueDetail venue,
    required Sport sport,
    required DateTime start,
    required int hours,
    required String court,
  }) {
    final courtCents = [
      for (var i = 0; i < hours; i++)
        venue.rateCents(sport, start.add(Duration(hours: i))),
    ].fold(0, (a, b) => a + b);
    final seed = id.codeUnits.fold(start.hour * 31, (a, b) => a * 7 + b);
    return CourtBooking(
      id: id,
      venueId: venue.id,
      venueName: venue.name,
      venueAddress: venue.address,
      sport: sport,
      court: court,
      start: start,
      end: start.add(Duration(hours: hours)),
      courtCents: courtCents,
      feeCents: platformFee(courtCents),
      doorCode: (1000 + seed % 9000).toString(),
      code: 'CB-${(seed % 100000).toString().padLeft(5, '0')}',
    );
  }

  /// Other players' bookings: busy evenings, so some peak slots are taken.
  List<CourtBooking> _others(VenueDetail v, Sport sport, DateTime day) {
    final courts = v.courtsFor(sport)?.count ?? 0;
    return [
      for (final h in [19, 21])
        if ((day.day + h) % 2 == 0)
          for (var i = 0; i < courts; i++)
            CourtBooking(
              id: '',
              venueId: v.id,
              venueName: v.name,
              venueAddress: v.address,
              sport: sport,
              court: '',
              start: DateTime(day.year, day.month, day.day, h),
              end: DateTime(day.year, day.month, day.day, h + 1),
              courtCents: 0,
              feeCents: 0,
              doorCode: '',
              code: '',
            ),
    ];
  }

  VenueDetail _find(String id) => _venues.firstWhere(
    (v) => v.id == id,
    orElse: () => throw const AuthFailure('This venue is no longer listed.'),
  );

  @override
  Future<List<VenueDetail>> venues() async {
    await _tick();
    return _venues;
  }

  @override
  Future<VenueDetail> venue(String id) async {
    await _tick();
    return _find(id);
  }

  @override
  Future<List<CourtBooking>> bookingsOn(
    String venueId,
    Sport sport,
    DateTime day,
  ) async {
    await _tick();
    final v = _find(venueId);
    bool sameDay(DateTime d) =>
        d.year == day.year && d.month == day.month && d.day == day.day;
    return [
      ..._others(v, sport, day),
      ..._bookings.where(
        (b) => b.venueId == venueId && b.sport == sport && sameDay(b.start),
      ),
    ];
  }

  @override
  Future<CourtBooking> book({
    required VenueDetail venue,
    required Sport sport,
    required DateTime start,
    required int hours,
    required String methodId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final day = DateTime(start.year, start.month, start.day);
    final slot = slotsFor(
      venue,
      sport,
      day,
      hours,
      await bookingsOn(venue.id, sport, day),
    ).where((s) => s.start == start).firstOrNull;
    if (slot == null || !slot.free) {
      throw const AuthFailure(
        'That time was just taken. Pick another start time.',
      );
    }
    final b = _make(
      id: 'cb-${++_n}',
      venue: venue,
      sport: sport,
      start: start,
      hours: hours,
      court: 'Court ${(start.hour % (venue.courtsFor(sport)?.count ?? 1)) + 1}',
    );
    _bookings.add(b);
    return b;
  }

  @override
  Future<List<CourtBooking>> myBookings() async {
    await _tick();
    return [..._bookings]..sort((a, b) => a.start.compareTo(b.start));
  }

  @override
  Future<CourtBooking> booking(String id) async {
    await _tick();
    return _bookings.firstWhere(
      (b) => b.id == id,
      orElse: () => throw const AuthFailure('This booking no longer exists.'),
    );
  }

  @override
  Future<int> cancel(String id, {required bool toWallet}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final i = _bookings.indexWhere((b) => b.id == id);
    final b = _bookings[i];
    if (b.status == BookingStatus.cancelled) {
      throw const AuthFailure('This booking is already cancelled.');
    }
    final refund = b.refundTo(wallet: toWallet);
    _bookings[i] = b.copyWith(
      status: BookingStatus.cancelled,
      refundCents: refund,
    );
    return refund;
  }
}
