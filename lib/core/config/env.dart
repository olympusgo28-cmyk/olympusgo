import 'package:flutter/foundation.dart';

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

  /// Local testing only: no Face ID check asks for a face, and the Face ID
  /// switch is hidden, for a simulator with no face set up.
  /// `--dart-define=SKIP_FACE_ID=true`. Only a debug build on a local stack
  /// honours it, so a hosted or release build always asks.
  static bool get skipFaceId => skipFaceIdWhen(
    debug: kDebugMode,
    local: localStandIn,
    asked: _skipFaceId,
  );
  static const _skipFaceId = bool.fromEnvironment('SKIP_FACE_ID');

  /// All three must hold, so a hosted or release build always asks.
  @visibleForTesting
  static bool skipFaceIdWhen({
    required bool debug,
    required bool local,
    required bool asked,
  }) => debug && local && asked;

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
