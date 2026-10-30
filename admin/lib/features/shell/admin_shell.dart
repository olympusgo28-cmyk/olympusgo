import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/session.dart';

/// A section of the console and the role it needs. Hiding a section is only
/// tidiness: the database refuses the data whatever this says.
class Section {
  const Section(this.path, this.label, this.icon, this.role);
  final String path;
  final String label;
  final IconData icon;
  final String? role;
}

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.session,
    required this.sections,
    required this.location,
    required this.child,
  });

  final StaffSession session;
  final List<Section> sections;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final s in sections)
        if (s.role == null || session.has(s.role!)) s,
    ];
    final index = visible.indexWhere((s) => location.startsWith(s.path));
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: index < 0 ? null : index,
            onDestinationSelected: (i) => context.go(visible[i].path),
            destinations: [
              for (final s in visible)
                NavigationRailDestination(
                  icon: Icon(s.icon),
                  label: Text(s.label),
                ),
            ],
            trailing: TextButton(
              onPressed: () => Supabase.instance.client.auth.signOut(),
              child: const Text('Log out'),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
