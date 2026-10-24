import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/og_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
  } else {
    debugPrint(
      'No SUPABASE_ANON_KEY: running in demo mode (nothing is saved).',
    );
  }
  // Load the two brand fonts before the first frame so nothing reflows.
  GoogleFonts.config.allowRuntimeFetching = true;
  await GoogleFonts.pendingFonts([
    GoogleFonts.archivo(fontWeight: FontWeight.w700),
    GoogleFonts.archivo(fontWeight: FontWeight.w800),
    GoogleFonts.figtree(),
    GoogleFonts.figtree(fontWeight: FontWeight.w600),
    GoogleFonts.figtree(fontWeight: FontWeight.w700),
  ]).timeout(const Duration(seconds: 3), onTimeout: () => []);
  runApp(const ProviderScope(child: OlympusGoApp()));
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
