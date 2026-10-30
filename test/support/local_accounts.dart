import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Makes a signed-in account on the local stack. Sign-up is by mobile only,
/// so the local service key creates the account with a verified test number.
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
  final number = Random().nextInt(899999999) + 100000000;
  await admin.auth.admin.createUser(
    AdminUserAttributes(
      email: email,
      password: password,
      emailConfirm: true,
      phone: '659$number',
      phoneConfirm: true,
    ),
  );
  return client.auth.signInWithPassword(email: email, password: password);
}
