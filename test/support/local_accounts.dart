import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Makes a signed-in account on the local stack. Sign-up goes through
/// resolve-login, so the local service key makes the account directly and
/// gives it a verified test number.
/// It never leaves the test process and has no meaning outside `supabase start`.
Future<AuthResponse> signUpLocal(
  SupabaseClient client, {
  required String email,
  required String password,
}) async {
  final admin = SupabaseClient(
    Platform.environment['LOCAL_SUPABASE_URL']!,
    Platform.environment['LOCAL_SUPABASE_SERVICE_KEY']!,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final number = Random().nextInt(89999999) + 10000000;
  final created = await admin.auth.admin.createUser(
    AdminUserAttributes(email: email, password: password, emailConfirm: true),
  );
  await admin
      .from('account_private')
      .update({
        'mobile': '+65$number',
        'mobile_verified_at': DateTime.now().toUtc().toIso8601String(),
        'email': email.toLowerCase(),
        'email_verified_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', created.user!.id);
  return client.auth.signInWithPassword(email: email, password: password);
}
