/// Build-time configuration, passed with
/// `flutter run --dart-define-from-file=env.json` (see `env.example.json`).
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iikojvrmiadzemqqixhz.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Without an anon key the app runs in demo mode: every screen works and
  /// any 6-digit code is accepted, but nothing is saved to Supabase.
  static bool get hasSupabase => supabaseAnonKey.isNotEmpty;

  /// On a local stack Stripe is a stand-in, so a test payment can be finished
  /// from the app. Nothing behind this exists on a hosted project.
  static bool get localStandIn {
    final host = Uri.parse(supabaseUrl).host;
    return hasSupabase &&
        (host == '127.0.0.1' || host == 'localhost' || host == '10.0.2.2');
  }

  /// Demo mode only: start signed in as the design's sample player, Aaron Ng,
  /// with onboarding done. `--dart-define=DEMO_SIGNED_IN=true`.
  static const demoSignedIn = bool.fromEnvironment('DEMO_SIGNED_IN');

  /// Demo mode only: sign in as this age group, to see restricted mode.
  /// `adult`, `teen`, `child` (unlinked) or `child_linked`.
  /// `--dart-define=DEMO_AUDIENCE=child`.
  static const demoAudience = String.fromEnvironment(
    'DEMO_AUDIENCE',
    defaultValue: 'adult',
  );
}
