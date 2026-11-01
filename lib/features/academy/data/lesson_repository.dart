import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../../play/data/payment_gateway.dart';
import '../domain/lesson_models.dart';

/// Trials, single classes and one-to-ones, paid in the app.
abstract class LessonRepository {
  Future<LessonQuote> quote(LessonKind kind, String ref, DateTime? at);

  /// Holds the place and returns the payment to finish, with the booking id.
  Future<(PaymentHold, String)> reserve(
    LessonKind kind,
    String ref, {
    required DateTime? at,
    required String studentId,
    required String key,
    required int expectedCents,
  });
  Future<List<LessonBooking>> mine();
  Future<LessonBooking> get(String id);

  /// Returns what comes back, in cents. [expectedCents] is what the screen
  /// promised: if that's no longer true, nothing happens.
  Future<int> cancel(String id, {int? expectedCents});
  Future<void> academyCancel(String id, String reason);
  Future<void> markAttendance(String id, {required bool present});
  Future<void> report(String id, String note);
  Future<List<LessonBooking>> academyLessons(String academyId);
  Future<List<LessonSlot>> openSlots(String academyId);
  Future<List<LessonSlot>> mySlots(String academyId);
  Future<void> addSlot(
    String academyId, {
    required DateTime at,
    required int minutes,
    required int priceCents,
    required String venue,
  });
  Future<void> withdrawSlot(String id);
}

class SupabaseLessonRepository implements LessonRepository {
  SupabaseLessonRepository(this._client);
  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Lesson error: ${e.code}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Lesson network error');
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  Map<String, dynamic> _map(dynamic r) => (r as Map).cast<String, dynamic>();

  Future<List<Map<String, dynamic>>> _list(
    String fn, [
    Map<String, dynamic>? params,
  ]) async => [
    for (final r in (await _client.rpc(fn, params: params)) as List? ?? [])
      _map(r),
  ];

  @override
  Future<LessonQuote> quote(LessonKind kind, String ref, DateTime? at) =>
      _guard(() async {
        return LessonQuote.fromJson(
          _map(
            await _client.rpc(
              'lesson_quote',
              params: {
                'p_kind': kind.id,
                'p_ref': ref,
                'p_at': at?.toUtc().toIso8601String(),
              },
            ),
          ),
        );
      });

  @override
  Future<(PaymentHold, String)> reserve(
    LessonKind kind,
    String ref, {
    required DateTime? at,
    required String studentId,
    required String key,
    required int expectedCents,
  }) => _guard(() async {
    final r = _map(
      await _client.rpc(
        'lesson_reserve',
        params: {
          'p_kind': kind.id,
          'p_ref': ref,
          'p_at': at?.toUtc().toIso8601String(),
          'p_student': studentId,
          'p_key': key,
          'p_expected_minor': expectedCents,
        },
      ),
    );
    return (SupabasePaymentGateway.holdFrom(r), r['booking_id'] as String);
  });

  @override
  Future<List<LessonBooking>> mine() => _guard(() async {
    return [
      for (final r in await _list('lesson_my')) LessonBooking.fromJson(r),
    ];
  });

  @override
  Future<LessonBooking> get(String id) => _guard(() async {
    return LessonBooking.fromJson(
      _map(await _client.rpc('lesson_get', params: {'p_booking': id})),
    );
  });

  @override
  Future<int> cancel(String id, {int? expectedCents}) => _guard(() async {
    final r = await _client.rpc(
      'lesson_cancel',
      params: {'p_booking': id, 'p_expected_minor': expectedCents},
    );
    return (r as num).toInt();
  });

  @override
  Future<void> academyCancel(String id, String reason) => _guard(() async {
    await _client.rpc(
      'lesson_academy_cancel',
      params: {'p_booking': id, 'p_reason': reason},
    );
  });

  @override
  Future<void> markAttendance(String id, {required bool present}) =>
      _guard(() async {
        await _client.rpc(
          'lesson_mark_attendance',
          params: {'p_booking': id, 'p_present': present},
        );
      });

  @override
  Future<void> report(String id, String note) => _guard(() async {
    await _client.rpc(
      'lesson_report',
      params: {'p_booking': id, 'p_note': note},
    );
  });

  @override
  Future<List<LessonBooking>> academyLessons(String academyId) =>
      _guard(() async {
        return [
          for (final r in await _list('lesson_academy_list', {
            'p_academy': academyId,
          }))
            LessonBooking.fromJson(r),
        ];
      });

  @override
  Future<List<LessonSlot>> openSlots(String academyId) => _guard(() async {
    return [
      for (final r in await _list('lesson_slots_open', {
        'p_academy': academyId,
      }))
        LessonSlot.fromJson(r),
    ];
  });

  @override
  Future<List<LessonSlot>> mySlots(String academyId) => _guard(() async {
    return [
      for (final r in await _list('lesson_slots_mine', {
        'p_academy': academyId,
      }))
        LessonSlot.fromJson(r),
    ];
  });

  @override
  Future<void> addSlot(
    String academyId, {
    required DateTime at,
    required int minutes,
    required int priceCents,
    required String venue,
  }) => _guard(() async {
    await _client.rpc(
      'lesson_slot_add',
      params: {
        'p_academy': academyId,
        'p_starts': at.toUtc().toIso8601String(),
        'p_minutes': minutes,
        'p_price_minor': priceCents,
        'p_venue': venue,
      },
    );
  });

  @override
  Future<void> withdrawSlot(String id) => _guard(() async {
    await _client.rpc('lesson_slot_withdraw', params: {'p_slot': id});
  });
}

/// Lessons without a backend, for demos and tests. Nothing is really paid.
class DemoLessonRepository implements LessonRepository {
  final _bookings = <String, LessonBooking>{};
  final _slots = <String, LessonSlot>{};
  int _n = 0;

  static const _fee = 500;

  LessonQuote _quote(int price, DateTime at, String title) => LessonQuote(
    title: title,
    priceCents: price,
    feeCents: _fee,
    totalCents: price + _fee,
    startsAt: at,
    refundRule:
        'Cancel at least 24 hours before the lesson and you get the price '
        'back, without the fee.',
    enabled: true,
  );

  @override
  Future<LessonQuote> quote(LessonKind kind, String ref, DateTime? at) async =>
      _quote(5000, at ?? _slots[ref]?.startsAt ?? DateTime.now(), kind.label);

  @override
  Future<(PaymentHold, String)> reserve(
    LessonKind kind,
    String ref, {
    required DateTime? at,
    required String studentId,
    required String key,
    required int expectedCents,
  }) async {
    final start = at ?? _slots[ref]?.startsAt ?? DateTime.now();
    final id = 'l-${++_n}';
    _bookings[id] = LessonBooking(
      id: id,
      kind: kind,
      title: kind.label,
      academyId: 'a-smash',
      academy: 'Smash Academy',
      coach: 'Coach Ravi',
      student: 'Mia Ng',
      startsAt: start,
      endsAt: start.add(const Duration(hours: 1)),
      step: LessonStep.paid,
      totalCents: expectedCents,
      priceCents: expectedCents - _fee,
      feeCents: _fee,
      canPay: true,
    );
    return (
      PaymentHold(result: 'reserved', id: 'pay-$id', totalCents: expectedCents),
      id,
    );
  }

  @override
  Future<List<LessonBooking>> mine() async => _bookings.values.toList();

  @override
  Future<LessonBooking> get(String id) async =>
      _bookings[id] ?? (throw const AuthFailure('This lesson isn\'t yours.'));

  LessonBooking _with(LessonBooking b, LessonStep step, {int refunded = 0}) =>
      _bookings[b.id] = LessonBooking(
        id: b.id,
        kind: b.kind,
        title: b.title,
        academyId: b.academyId,
        academy: b.academy,
        coach: b.coach,
        student: b.student,
        startsAt: b.startsAt,
        endsAt: b.endsAt,
        step: step,
        totalCents: b.totalCents,
        priceCents: b.priceCents,
        feeCents: b.feeCents,
        refundedCents: refunded,
        canPay: b.canPay,
        canTeach: b.canTeach,
      );

  @override
  Future<int> cancel(String id, {int? expectedCents}) async {
    final b = await get(id);
    final inTime = DateTime.now().isBefore(
      b.startsAt.subtract(const Duration(hours: 24)),
    );
    _with(
      b,
      inTime ? LessonStep.cancelled : LessonStep.lateCancelled,
      refunded: inTime ? b.priceCents : 0,
    );
    return inTime ? b.priceCents : 0;
  }

  @override
  Future<void> academyCancel(String id, String reason) async {
    final b = await get(id);
    _with(b, LessonStep.cancelled, refunded: b.totalCents);
  }

  @override
  Future<void> markAttendance(String id, {required bool present}) async {
    _with(await get(id), LessonStep.released);
  }

  @override
  Future<void> report(String id, String note) async {
    _with(await get(id), LessonStep.reported);
  }

  @override
  Future<List<LessonBooking>> academyLessons(String academyId) async => [
    for (final b in _bookings.values) b,
  ];

  @override
  Future<List<LessonSlot>> openSlots(String academyId) async => [
    for (final s in _slots.values)
      if (!s.booked) s,
  ];

  @override
  Future<List<LessonSlot>> mySlots(String academyId) async =>
      _slots.values.toList();

  @override
  Future<void> addSlot(
    String academyId, {
    required DateTime at,
    required int minutes,
    required int priceCents,
    required String venue,
  }) async {
    final id = 's-${++_n}';
    _slots[id] = LessonSlot(
      id: id,
      startsAt: at,
      endsAt: at.add(Duration(minutes: minutes)),
      priceCents: priceCents,
      coach: 'Coach Ravi',
      totalCents: priceCents + _fee,
      venue: venue,
    );
  }

  @override
  Future<void> withdrawSlot(String id) async {
    _slots.remove(id);
  }
}
