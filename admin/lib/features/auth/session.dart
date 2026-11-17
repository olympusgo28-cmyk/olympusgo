import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where a person is in staff sign-in.
class StaffSession {
  const StaffSession({required this.roles, required this.mfa});
  final List<String> roles;
  final bool mfa;

  bool has(String role) => roles.contains('super') || roles.contains(role);
}

/// Null when signed out. Reloads on every auth change, including after MFA.
final staffSessionProvider = StreamProvider<StaffSession?>((ref) async* {
  final client = Supabase.instance.client;
  Future<StaffSession?> read() async {
    if (client.auth.currentSession == null) return null;
    final r = await client.rpc('staff_whoami') as Map<String, dynamic>;
    return StaffSession(
      roles: (r['roles'] as List).cast<String>(),
      mfa: r['mfa'] as bool,
    );
  }

  yield await read();
  await for (final _ in client.auth.onAuthStateChange) {
    yield await read();
  }
});
