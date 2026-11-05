import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/config/session_storage.dart';
import 'core/router/app_router.dart';
import 'core/theme/og_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
      httpClient: sessionHttpClient,
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    );
  } else {
    debugPrint(
      'No SUPABASE_ANON_KEY: running in demo mode (nothing is saved).',
    );
  }
  // Load the two brand fonts before the first frame so nothing reflows.
  GoogleFonts.config.allowRuntimeFetching = true;
  await waitForFonts(
    GoogleFonts.pendingFonts([
      GoogleFonts.baloo2(fontWeight: FontWeight.w600),
      GoogleFonts.nunitoSans(),
      GoogleFonts.nunitoSans(fontWeight: FontWeight.w600),
    ]),
  );
  runApp(const ProviderScope(child: OlympusGoApp()));
}

/// Waits a short while for the fonts. A slow or failed load leaves the
/// fallback font, so the first frame always comes.
@visibleForTesting
Future<void> waitForFonts(
  Future<Object?> pending, {
  Duration limit = const Duration(seconds: 3),
}) async {
  try {
    await pending.timeout(limit);
  } on Object catch (e) {
    debugPrint('Fonts not loaded: ${e.runtimeType}');
  }
}

class OlympusGoApp extends ConsumerWidget {
  const OlympusGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'OlympusGO',
      debugShowCheckedModeBanner: false,
      theme: OgTheme.light(),
      darkTheme: OgTheme.dark(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
