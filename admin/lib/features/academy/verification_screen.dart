import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_design/og_design.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

/// Business licences and coach licences. Content staff compare them with the
/// registers by hand. Files go once a check is done.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  late Future<Map<String, dynamic>> _data = _load();

  Future<Map<String, dynamic>> _load() async =>
      (await ref.read(staffApiProvider).read('staff_verification_list') as Map)
          .cast<String, dynamic>();

  void _refresh() => setState(() {
    _data = _load();
  });

  Future<void> _show(String kind, String id, String path) async {
    final api = ref.read(staffApiProvider);
    try {
      await api.act('staff_doc_viewed', {
        'p_kind': kind,
        'p_id': id,
        'p_reason': 'Opened to review it',
      });
      final url = await api.documentUrl(path);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          content: SizedBox(
            width: 640,
            height: 640,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              semanticLabel: 'Verification document',
              errorBuilder: (_, _, _) =>
                  const Text('This file can’t be shown here.'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  /// Takes the file out of storage, then clears its path.
  Future<void> _clearFile(
    String kind,
    String id,
    String path,
    String why,
  ) async {
    final api = ref.read(staffApiProvider);
    await api.removeDocument(path);
    await api.act('staff_doc_removed', {
      'p_kind': kind,
      'p_id': id,
      'p_reason': why,
    });
  }

  Future<void> _decide(
    String title,
    String action,
    Map<String, dynamic> params,
    String kind,
    String id,
    Object? path,
  ) async {
    final reason = await askReason(context, title);
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act(action, {
        ...params,
        'p_reason': reason,
      });
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
      return;
    }
    try {
      if (path != null) await _clearFile(kind, id, path as String, reason);
    } on StaffFailure catch (e) {
      if (mounted) toast(context, '${e.message} The decision is saved.');
    }
    _refresh();
  }

  Widget _fileButtons(String kind, String id, Object? path) => path == null
      ? const SizedBox.shrink()
      : TextButton(
          onPressed: () => _show(kind, id, path as String),
          child: const Text('View file'),
        );

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'Verification',
    child: Loaded<Map<String, dynamic>>(
      future: _data,
      builder: (d) {
        final academies = (d['academies'] as List).cast<Map<String, dynamic>>();
        final licences = (d['licences'] as List).cast<Map<String, dynamic>>();
        return ListView(
          children: [
            Text('Academies', style: OgText.body(18, weight: FontWeight.w600)),
            if (academies.isEmpty) const Text('Nothing to review.'),
            for (final a in academies)
              ListTile(
                title: Text('${a['name']}'),
                subtitle: Text(
                  [
                    'UEN ${a['uen'] ?? 'not given'}',
                    a['verification'],
                    a['head_licensed'] == true
                        ? 'Head coach licensed'
                        : 'Head coach not licensed',
                    a['payout_ready'] == true
                        ? 'Payout account ready'
                        : 'Payout account not ready',
                  ].join(' · '),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    _fileButtons('academy', a['id'] as String, a['file_path']),
                    if (a['verification'] == 'submitted')
                      TextButton(
                        onPressed: () => _decide(
                          'Verify ${a['name']}',
                          'staff_academy_decide',
                          {'p_academy': a['id'], 'p_approve': true},
                          'academy',
                          a['id'] as String,
                          a['file_path'],
                        ),
                        child: const Text('Verify'),
                      ),
                    if (a['verification'] != 'rejected')
                      TextButton(
                        onPressed: () => _decide(
                          'Reject ${a['name']}',
                          'staff_academy_decide',
                          {'p_academy': a['id'], 'p_approve': false},
                          'academy',
                          a['id'] as String,
                          a['file_path'],
                        ),
                        child: const Text('Reject'),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Coach licences',
              style: OgText.body(18, weight: FontWeight.w600),
            ),
            if (licences.isEmpty) const Text('Nothing to review.'),
            for (final l in licences)
              ListTile(
                title: Text('${l['name']}'),
                subtitle: Text(
                  [
                    '${l['nroc_number']}',
                    'Expires ${l['expires_on']}',
                    l['status'],
                  ].join(' · '),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    _fileButtons(
                      'licence',
                      l['user_id'] as String,
                      l['file_path'],
                    ),
                    if (l['status'] == 'submitted')
                      TextButton(
                        onPressed: () => _decide(
                          'Verify this licence',
                          'staff_licence_decide',
                          {'p_user': l['user_id'], 'p_approve': true},
                          'licence',
                          l['user_id'] as String,
                          l['file_path'],
                        ),
                        child: const Text('Verify'),
                      ),
                    if (l['status'] != 'rejected')
                      TextButton(
                        onPressed: () => _decide(
                          'Reject this licence',
                          'staff_licence_decide',
                          {'p_user': l['user_id'], 'p_approve': false},
                          'licence',
                          l['user_id'] as String,
                          l['file_path'],
                        ),
                        child: const Text('Reject'),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}
