import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_design/og_design.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

/// A-04: find a person, see their parent links, review recovery requests.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _query = TextEditingController();
  Future<List<dynamic>>? _found;
  Future<Map<String, dynamic>>? _user;
  late Future<List<dynamic>> _recovery = _loadRecovery();

  Future<List<dynamic>> _loadRecovery() async =>
      await ref.read(staffApiProvider).read('staff_recovery_list')
          as List<dynamic>;

  void _search() => setState(() {
    _found = ref
        .read(staffApiProvider)
        .read('staff_user_search', {'p_query': _query.text})
        .then((r) => r! as List<dynamic>);
  });

  void _open(String id) => setState(() {
    _user = ref
        .read(staffApiProvider)
        .read('staff_user_get', {'p_user': id})
        .then((r) => r! as Map<String, dynamic>);
  });

  Future<void> _decide(int id, bool approve) async {
    final reason = await askReason(
      context,
      approve ? 'Approve this recovery' : 'Refuse this recovery',
    );
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act('staff_recovery_decide', {
        'p_id': id,
        'p_approve': approve,
        'p_reason': reason,
      });
      setState(() => _recovery = _loadRecovery());
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'Users',
    child: ListView(
      children: [
        TextField(
          controller: _query,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            labelText: 'Name, username, email or last digits of a mobile',
            suffixIcon: IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search),
              onPressed: _search,
            ),
          ),
        ),
        if (_found != null)
          Loaded<List<dynamic>>(
            future: _found!,
            isEmpty: (rows) => rows.isEmpty,
            emptyText: 'Nobody found.',
            builder: (rows) => Column(
              children: [
                for (final r in rows.cast<Map<String, dynamic>>())
                  ListTile(
                    title: Text(r['name'] as String? ?? 'No name'),
                    subtitle: Text('@${r['username']} · ${r['audience']}'),
                    onTap: () => _open(r['id'] as String),
                  ),
              ],
            ),
          ),
        if (_user != null)
          Loaded<Map<String, dynamic>>(
            future: _user!,
            builder: (u) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u['name'] as String? ?? 'No name',
                      style: OgText.section,
                    ),
                    Text('Age group: ${u['audience']}'),
                    Text('Restricted: ${u['restricted']}'),
                    const SizedBox(height: 8),
                    Text('Parent links', style: OgText.label),
                    for (final l
                        in (u['links'] as List).cast<Map<String, dynamic>>())
                      Text('${l['role']} · ${l['other']} · ${l['status']}'),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text('Recovery requests', style: OgText.section),
        Loaded<List<dynamic>>(
          future: _recovery,
          isEmpty: (rows) => rows.isEmpty,
          emptyText: 'No requests waiting.',
          builder: (rows) => Column(
            children: [
              for (final r in rows.cast<Map<String, dynamic>>())
                ListTile(
                  title: Text(r['contact_email'] as String),
                  subtitle: Text(r['created_at'] as String),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => _decide(r['id'] as int, false),
                        child: const Text('Refuse'),
                      ),
                      FilledButton(
                        onPressed: () => _decide(r['id'] as int, true),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
