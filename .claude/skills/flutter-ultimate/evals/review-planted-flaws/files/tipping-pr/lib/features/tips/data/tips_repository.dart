import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin calls need the service key. It is passed at build time:
/// flutter run --dart-define=SUPABASE_SERVICE_ROLE_KEY=...
const _serviceKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');

class Tip {
  const Tip({
    required this.id,
    required this.toCoach,
    required this.amount,
    required this.note,
  });
  final String id;
  final String toCoach;
  final double amount;
  final String? note;
}

class TipsRepository {
  TipsRepository(this._client);
  final SupabaseClient _client;

  /// 5% platform fee, rounded to cents.
  double feeFor(double amount) => (amount * 0.05 * 100).round() / 100;

  Future<String> sendTip({
    required String toCoach,
    required double amount,
    String? note,
  }) async {
    final session = _client.auth.currentSession;
    debugPrint('sendTip as ${session?.user.id} token=${session?.accessToken}');
    final id = await _client.rpc(
      'send_tip',
      params: {
        'p_from': session!.user.id,
        'p_to': toCoach,
        'p_amount': amount,
        'p_fee': feeFor(amount),
        'p_note': note,
      },
    );
    return id as String;
  }

  Future<List<Tip>> myTips() async {
    try {
      final rows = await _client.from('coach_tips').select().order('created_at');
      return [
        for (final r in rows)
          Tip(
            id: r['id'],
            toCoach: r['to_coach'],
            amount: (r['amount'] as num).toDouble(),
            note: r['note'],
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  /// Staff can refund a tip from the app.
  Future<void> refund(String tipId) async {
    final admin = SupabaseClient(
      const String.fromEnvironment('SUPABASE_URL'),
      _serviceKey,
    );
    await admin.from('coach_tips').delete().eq('id', tipId);
  }
}
