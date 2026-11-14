import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_design/og_design.dart';
import 'package:og_money/og_money.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

const _errorNames = {
  'bad_video': 'Video could not be read',
  'too_long': 'Clip too long',
  'no_court': 'No court found',
  'no_player': 'No player found',
  'doubles': 'Doubles clip',
  'timeout': 'Timed out',
  'not_allowed': 'Not allowed to run',
  'internal': 'Worker error',
};

/// Analysis jobs: the queue, failures, storage and cost. Counts and error
/// codes only. No clip, frame or player reaches this screen.
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  var _reload = 0;

  Future<void> _retry(String id) async {
    final reason = await askReason(context, 'Retry this job');
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act('staff_analysis_retry', {
        'p_job': id,
        'p_reason': reason,
      });
      if (!mounted) return;
      toast(context, 'Queued again');
      setState(() => _reload++);
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  Widget _tile(String label, String value) => SizedBox(
    width: 170,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: OgText.heading(24)),
            Text(label, style: OgText.body(13, color: context.og.textMuted)),
          ],
        ),
      ),
    ),
  );

  String _size(num bytes) {
    final tenths = (bytes * 10 / (1024 * 1024 * 1024)).round();
    return '${tenths ~/ 10}.${tenths % 10} GB';
  }

  String _money(num cents) => 'S\$${Money(cents.round()).decimal}';

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'Analysis jobs',
    child: Loaded<Map<String, dynamic>>(
      key: ValueKey(_reload),
      future: ref
          .read(staffApiProvider)
          .read('staff_analysis_overview')
          .then((r) => r! as Map<String, dynamic>),
      isEmpty: (_) => false,
      emptyText: '',
      builder: (r) {
        final failures = r['failures'] as List<dynamic>;
        return ListView(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tile('In the queue', '${r['queued']}'),
                _tile('Running', '${r['running']}'),
                _tile('Done, 24 hours', '${r['done_24h']}'),
                _tile('Failed, 24 hours', '${r['failed_24h']}'),
                _tile('Clips held', '${r['clips_held']}'),
                _tile('Storage', _size(r['storage_bytes'] as num)),
                _tile('Files to remove', '${r['files_waiting']}'),
                _tile('Overdue clips', '${r['files_overdue']}'),
                _tile(
                  'Estimated cost, 30 days',
                  _money(r['cost_cents_30d'] as num),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Failures', style: OgText.heading(20)),
            if (failures.isEmpty)
              const ListTile(title: Text('No failed jobs.')),
            for (final f in failures.cast<Map<String, dynamic>>())
              ListTile(
                title: Text(
                  '${f['kind'] == 'court' ? 'Court' : 'Analysis'} · '
                  '${_errorNames[f['error_code']] ?? 'Worker error'}',
                ),
                subtitle: Text(
                  (f['at'] as String).substring(0, 16).replaceFirst('T', ' '),
                ),
                trailing: TextButton(
                  onPressed: () => _retry(f['id'] as String),
                  child: const Text('Retry'),
                ),
              ),
          ],
        );
      },
    ),
  );
}
