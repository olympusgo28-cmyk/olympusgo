import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';

/// A partner clinic. Nothing about a player's condition ever comes here.
class ServicePartner {
  const ServicePartner({
    required this.id,
    required this.name,
    this.area = '',
    this.blurb = '',
  });

  final String id;
  final String name;
  final String area;
  final String blurb;
}

abstract class ServicesRepository {
  Future<List<ServicePartner>> partners();

  /// Records that a referral was made, and returns the partner's booking link.
  Future<String> refer(String partnerId);
}

class SupabaseServicesRepository implements ServicesRepository {
  SupabaseServicesRepository(this._client);
  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Services error: ${e.code}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Services network error');
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  @override
  Future<List<ServicePartner>> partners() => _guard(() async {
    final rows = await _client.rpc('service_partner_list') as List? ?? [];
    return [
      for (final r in rows.cast<Map>())
        ServicePartner(
          id: r['id'] as String,
          name: r['name'] as String,
          area: r['area'] as String? ?? '',
          blurb: r['blurb'] as String? ?? '',
        ),
    ];
  });

  @override
  Future<String> refer(String partnerId) => _guard(() async {
    return await _client.rpc(
      'service_referral_make',
      params: {'p_partner': partnerId},
    ) as String;
  });
}

/// Partners without a backend, for demos and tests.
class DemoServicesRepository implements ServicesRepository {
  @override
  Future<List<ServicePartner>> partners() async => const [
    ServicePartner(
      id: 'sp-1',
      name: 'Rally Physio',
      area: 'Bishan',
      blurb: 'Sports physiotherapy for racket players.',
    ),
  ];

  @override
  Future<String> refer(String partnerId) async =>
      'https://example.com/book?ref=OLYMPUS';
}
