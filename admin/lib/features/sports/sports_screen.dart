import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_design/og_design.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

const _statuses = ['draft', 'live', 'maintenance'];

/// A-02: sports and formats, without a code change. A format change reaches
/// new Meets only, because each Meet keeps its own copy of the rules.
class SportsScreen extends ConsumerStatefulWidget {
  const SportsScreen({super.key});

  @override
  ConsumerState<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends ConsumerState<SportsScreen> {
  late Future<Map<String, dynamic>> _catalog = _load();

  Future<Map<String, dynamic>> _load() async =>
      await ref.read(staffApiProvider).read('staff_catalog')
          as Map<String, dynamic>;

  Future<void> _save(
    String title,
    String action,
    Map<String, dynamic> Function(String reason) params,
  ) async {
    final reason = await askReason(context, title);
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act(action, params(reason));
      setState(() => _catalog = _load());
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  Future<void> _addSport() async {
    final key = TextEditingController();
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a sport'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: key,
              decoration: const InputDecoration(
                labelText: 'Key, lower case with underscores',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _save(
      'Add ${name.text} as a draft',
      'staff_sport_save',
      (reason) => {
        'p_key': key.text.trim(),
        'p_name': name.text.trim(),
        'p_status': 'draft',
        'p_reason': reason,
      },
    );
  }

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'Sports and formats',
    actions: [
      FilledButton(onPressed: _addSport, child: const Text('Add a sport')),
    ],
    child: Loaded<Map<String, dynamic>>(
      future: _catalog,
      builder: (catalog) => ListView(
        children: [
          for (final s
              in (catalog['sports'] as List).cast<Map<String, dynamic>>())
            ExpansionTile(
              title: Text(s['name'] as String),
              subtitle: Text(
                '${s['status']} · ${(s['formats'] as List).length} formats',
              ),
              trailing: _StatusMenu(
                status: s['status'] as String,
                onPicked: (status) => _save(
                  'Make ${s['name']} $status',
                  'staff_sport_save',
                  (reason) => {
                    'p_key': s['key'],
                    'p_name': s['name'],
                    'p_status': status,
                    'p_reason': reason,
                  },
                ),
              ),
              children: [
                for (final f
                    in (s['formats'] as List).cast<Map<String, dynamic>>())
                  ListTile(
                    title: Text(f['name'] as String),
                    subtitle: Text(
                      'Minimum ${f['min_players']} · ${f['scoring']}',
                      style: OgText.body(13, color: context.og.textMuted),
                    ),
                    trailing: _StatusMenu(
                      status: f['status'] as String,
                      onPicked: (status) => _save(
                        'Make ${f['name']} $status',
                        'staff_format_save',
                        (reason) => {
                          'p_sport': s['key'],
                          'p_key': f['key'],
                          'p_name': f['name'],
                          'p_status': status,
                          'p_min_players': f['min_players'],
                          'p_scoring': f['scoring'],
                          'p_reason': reason,
                        },
                      ),
                    ),
                  ),
                ListTile(
                  title: const Text('Add a doubles format'),
                  leading: const Icon(Icons.add),
                  onTap: () => _save(
                    'Add doubles to ${s['name']}',
                    'staff_format_save',
                    (reason) => {
                      'p_sport': s['key'],
                      'p_key': 'doubles',
                      'p_name': 'Doubles',
                      'p_status': 'draft',
                      'p_min_players': 4,
                      'p_scoring': <String, dynamic>{},
                      'p_reason': reason,
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.status, required this.onPicked});

  final String status;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Change status',
    onSelected: onPicked,
    itemBuilder: (_) => [
      for (final s in _statuses)
        if (s != status) PopupMenuItem(value: s, child: Text('Make $s')),
    ],
    child: Chip(label: Text(status)),
  );
}
