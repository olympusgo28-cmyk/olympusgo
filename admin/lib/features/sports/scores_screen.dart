import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_design/og_design.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

/// Disputes an organizer can't decide because they played, and later
/// corrections, found by score id (R-SCO-3).
class ScoresScreen extends ConsumerStatefulWidget {
  const ScoresScreen({super.key});

  @override
  ConsumerState<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends ConsumerState<ScoresScreen> {
  final _search = TextEditingController();
  late Future<List<dynamic>> _scores = _load();

  Future<List<dynamic>> _load() async {
    final id = _search.text.trim();
    return await ref.read(staffApiProvider).read('staff_scores', {
      if (id.isNotEmpty) 'p_score': id,
    }) as List<dynamic>;
  }

  Future<void> _correct(Map<String, dynamic> s) async {
    final games = TextEditingController(
      text: [for (final g in s['games'] as List) '${g[0]}-${g[1]}'].join(', '),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s['title'] as String),
        content: TextField(
          controller: games,
          decoration: const InputDecoration(
            labelText: 'Final score, such as 21-10, 21-12',
          ),
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
    if (ok != true || !mounted) return;
    final parsed = [
      for (final m in RegExp(r'(\d+)\s*[-–]\s*(\d+)').allMatches(games.text))
        [int.parse(m[1]!), int.parse(m[2]!)],
    ];
    final reason = await askReason(context, 'Set this result');
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act('staff_result_correct', {
        'p_score': s['id'],
        'p_games': parsed,
        'p_reason': reason,
      });
      setState(() => _scores = _load());
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'Scores',
    child: Column(
      children: [
        TextField(
          controller: _search,
          decoration: const InputDecoration(
            labelText: 'Find a result by its id',
          ),
          onSubmitted: (_) => setState(() => _scores = _load()),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Loaded<List<dynamic>>(
            future: _scores,
            builder: (scores) => scores.isEmpty
                ? Text(
                    'No scores need the team.',
                    style: OgText.body(16, color: context.og.textMuted),
                  )
                : ListView(
                    children: [
                      for (final s in scores.cast<Map<String, dynamic>>())
                        ListTile(
                          title: Text(s['title'] as String),
                          subtitle: Text(
                            [
                              '${(s['side_a'] as List).join(' and ')} vs '
                                  '${(s['side_b'] as List).join(' and ')}',
                              s['status'],
                              s['games'],
                              ?s['reason'],
                            ].join(' · '),
                          ),
                          onTap: () => _correct(s),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    ),
  );
}
