import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_design/og_design.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

/// A-05: scoring presets and level scales, without a deploy. A preset reaches
/// activities that pick it from now on; results already saved keep their score.
class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
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

  Future<void> _editPreset(Map<String, dynamic> p) async {
    final rules = p['rules'] as Map<String, dynamic>;
    final to = TextEditingController(text: '${rules['points_to_win']}');
    final by = TextEditingController(text: '${rules['win_by']}');
    final cap = TextEditingController(text: '${rules['cap'] ?? ''}');
    final best = TextEditingController(text: '${rules['best_of']}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(p['name'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (field, label) in [
              (to, 'Points to win'),
              (by, 'Win by'),
              (cap, 'Cap, blank for none'),
              (best, 'Best of'),
            ])
              TextField(
                controller: field,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: label),
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
      'Change ${p['name']}',
      'staff_preset_save',
      (reason) => {
        'p_key': p['key'],
        'p_sport': p['sport_key'],
        'p_name': p['name'],
        'p_rules': {
          'points_to_win': int.tryParse(to.text),
          'win_by': int.tryParse(by.text),
          if (cap.text.trim().isNotEmpty) 'cap': int.tryParse(cap.text),
          'best_of': int.tryParse(best.text),
        },
        'p_active': p['active'],
        'p_reason': reason,
      },
    );
  }

  Future<void> _editLevel(Map<String, dynamic> l) async {
    final from = TextEditingController(text: '${l['from_level']}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l['name'] as String),
        content: TextField(
          controller: from,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Starts at level'),
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
      'Change ${l['name']}',
      'staff_level_save',
      (reason) => {
        'p_band': l['band'],
        'p_name': l['name'],
        'p_from': num.tryParse(from.text),
        'p_reason': reason,
      },
    );
  }

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'Rating and scoring rules',
    child: Loaded<Map<String, dynamic>>(
      future: _catalog,
      builder: (catalog) => ListView(
        children: [
          Text('Scoring presets', style: OgText.heading(20)),
          for (final p
              in (catalog['presets'] as List).cast<Map<String, dynamic>>())
            ListTile(
              title: Text(p['name'] as String),
              subtitle: Text(
                '${p['sport_key']} · ${p['rules']}',
                style: OgText.body(13, color: context.og.textMuted),
              ),
              onTap: () => _editPreset(p),
              trailing: Switch(
                value: p['active'] as bool,
                onChanged: (v) => _save(
                  '${v ? 'Turn on' : 'Turn off'} ${p['name']}',
                  'staff_preset_save',
                  (reason) => {
                    'p_key': p['key'],
                    'p_sport': p['sport_key'],
                    'p_name': p['name'],
                    'p_rules': p['rules'],
                    'p_active': v,
                    'p_reason': reason,
                  },
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('Level scale', style: OgText.heading(20)),
          for (final l
              in (catalog['level_scales'] as List).cast<Map<String, dynamic>>())
            ListTile(
              title: Text('${l['band']} · ${l['name']}'),
              subtitle: Text('From ${l['from_level']}'),
              onTap: () => _editLevel(l),
            ),
        ],
      ),
    ),
  );
}
