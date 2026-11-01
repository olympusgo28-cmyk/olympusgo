import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:og_design/og_design.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/ui.dart';
import 'features/academy/lessons_screen.dart';
import 'features/academy/services_screen.dart';
import 'features/academy/verification_screen.dart';
import 'features/audit/audit_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/mfa_screen.dart';
import 'features/auth/session.dart';
import 'features/game/campaigns_screen.dart';
import 'features/money/money_screens.dart';
import 'features/reports/reports_screens.dart';
import 'features/shell/admin_shell.dart';
import 'features/shop/catalogue_screen.dart';
import 'features/shop/orders_screen.dart';
import 'features/sports/rules_screen.dart';
import 'features/sports/scores_screen.dart';
import 'features/sports/sports_screen.dart';
import 'features/users/users_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Config.supabaseUrl,
    publishableKey: Config.supabaseKey,
  );
  runApp(const ProviderScope(child: AdminApp()));
}

const sections = [
  Section('/reports', 'Reports', Icons.flag_outlined, 'moderator'),
  Section('/users', 'Users', Icons.people_outline, 'moderator'),
  Section('/scores', 'Scores', Icons.scoreboard_outlined, 'moderator'),
  Section('/sports', 'Sports', Icons.sports_tennis, 'content'),
  Section('/rules', 'Rating and scoring', Icons.rule, 'content'),
  Section('/catalogue', 'Catalogue', Icons.storefront_outlined, 'content'),
  Section('/verification', 'Verification', Icons.verified_outlined, 'content'),
  Section('/services', 'Services', Icons.medical_services_outlined, 'content'),
  Section('/campaigns', 'Campaigns', Icons.emoji_events_outlined, 'content'),
  Section('/money', 'Payments', Icons.payments_outlined, 'payments'),
  Section('/orders', 'Orders', Icons.receipt_long_outlined, 'payments'),
  Section('/lessons', 'Lessons', Icons.event_available_outlined, 'payments'),
  Section('/audit', 'Audit log', Icons.history, 'super'),
];

final _router = GoRouter(
  initialLocation: '/reports',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          _Gate(location: state.matchedLocation, child: child),
      routes: [
        GoRoute(path: '/audit', builder: (_, _) => const AuditScreen()),
        GoRoute(path: '/money', builder: (_, _) => const MoneyScreen()),
        GoRoute(path: '/catalogue', builder: (_, _) => const CatalogueScreen()),
        GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
        GoRoute(path: '/lessons', builder: (_, _) => const LessonsScreen()),
        GoRoute(
          path: '/verification',
          builder: (_, _) => const VerificationScreen(),
        ),
        GoRoute(path: '/services', builder: (_, _) => const ServicesScreen()),
        GoRoute(path: '/campaigns', builder: (_, _) => const CampaignsScreen()),
        GoRoute(path: '/users', builder: (_, _) => const UsersScreen()),
        GoRoute(path: '/sports', builder: (_, _) => const SportsScreen()),
        GoRoute(path: '/rules', builder: (_, _) => const RulesScreen()),
        GoRoute(path: '/scores', builder: (_, _) => const ScoresScreen()),
        GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
        GoRoute(path: '/reports/bans', builder: (_, _) => const BansScreen()),
        GoRoute(
          path: '/reports/:id',
          builder: (_, s) => CaseScreen(id: s.pathParameters['id']!),
        ),
      ],
    ),
  ],
);

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'OlympusGO staff',
    debugShowCheckedModeBanner: false,
    theme: OgTheme.light(),
    darkTheme: OgTheme.dark(),
    routerConfig: _router,
  );
}

/// Nothing past here renders until the session has passed MFA.
class _Gate extends ConsumerWidget {
  const _Gate({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(staffSessionProvider)
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => const Scaffold(
          body: StaffPage(
            title: 'OlympusGO staff',
            child: Text("Can't reach OlympusGO. Try again."),
          ),
        ),
        data: (session) {
          if (session == null) return const LoginScreen();
          if (session.roles.isEmpty) return const _NotStaff();
          if (!session.mfa) return const MfaScreen();
          return AdminShell(
            session: session,
            sections: sections,
            location: location,
            child: child,
          );
        },
      );
}

class _NotStaff extends StatelessWidget {
  const _NotStaff();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: StaffPage(
      title: 'OlympusGO staff',
      actions: [
        TextButton(
          onPressed: () => Supabase.instance.client.auth.signOut(),
          child: const Text('Log out'),
        ),
      ],
      child: const Text('This account is not a staff account.'),
    ),
  );
}
