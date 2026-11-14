import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../../play/data/play_repository.dart';
import '../domain/discover_models.dart';

abstract interface class DiscoverRepository {
  Future<List<FoundSession>> sessions(DiscoverFilter filter);

  /// Records consent and the player's coarse area. Only a geohash is sent.
  Future<void> shareArea(String geohash);
  Future<void> stopSharingArea();
}

class SupabaseDiscoverRepository implements DiscoverRepository {
  SupabaseDiscoverRepository(this._client, this._play);

  final SupabaseClient _client;
  final SupabasePlayRepository _play;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Discover error: ${e.code}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  @override
  Future<List<FoundSession>> sessions(DiscoverFilter f) => _guard(() async {
    final day = f.day;
    final rows = await _client.rpc(
      'discover_sessions',
      params: {
        'p_sport': f.sport?.id,
        'p_from': day?.toUtc().toIso8601String(),
        'p_to': day?.add(const Duration(days: 1)).toUtc().toIso8601String(),
        'p_hour_from': f.hourFrom,
        'p_hour_to': f.hourTo,
        'p_max_km': f.maxKm,
      },
    ) as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        FoundSession(
          activity: _play.fromCard(r),
          km: (r['km'] as num?)?.toDouble(),
          latitude: (r['latitude'] as num?)?.toDouble(),
          longitude: (r['longitude'] as num?)?.toDouble(),
          fitsMe: r['fits_me'] as bool? ?? false,
        ),
    ];
  });

  @override
  Future<void> shareArea(String geohash) => _guard(() async {
    await _client.rpc(
      'consent_set',
      params: {'p_kind': 'location', 'p_granted': true},
    );
    await _client.rpc('location_set', params: {'p_geohash': geohash});
  });

  @override
  Future<void> stopSharingArea() => _guard(
    () => _client.rpc(
      'consent_set',
      params: {'p_kind': 'location', 'p_granted': false},
    ),
  );
}

/// Sample Meets with made-up distances, for demo mode.
class DemoDiscoverRepository implements DiscoverRepository {
  DemoDiscoverRepository(this._play);

  final PlayRepository _play;

  @override
  Future<List<FoundSession>> sessions(DiscoverFilter f) async {
    final meets = await _play.upcoming(limit: 12);
    final found = [
      for (final (i, a) in meets.indexed)
        FoundSession(
          activity: a,
          km: 1.2 + i * 1.7,
          latitude: 1.30 + i * 0.012,
          longitude: 103.82 + i * 0.015,
          fitsMe: i.isEven,
        ),
    ];
    return found.where((s) {
      final a = s.activity;
      if (f.sport != null && !a.sports.contains(f.sport)) return false;
      if (f.maxKm != null && s.km! > f.maxKm!) return false;
      if (f.day != null) {
        final next = f.day!.add(const Duration(days: 1));
        if (a.startsAt.isBefore(f.day!) || !a.startsAt.isBefore(next)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Future<void> shareArea(String geohash) async {}

  @override
  Future<void> stopSharingArea() async {}
}
