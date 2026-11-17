import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:og_design/og_design.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';
import '../posts/first_posts_screen.dart';

/// A-03: the daily queue, by deadline then number of reports.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late Future<List<dynamic>> _cases = _load();

  Future<List<dynamic>> _load() async =>
      await ref.read(staffApiProvider).read('staff_case_list') as List<dynamic>;

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'Reports',
    actions: [
      TextButton(
        onPressed: () => context.go('/reports/bans'),
        child: const Text('Bans waiting'),
      ),
      TextButton(
        onPressed: () => setState(() => _cases = _load()),
        child: const Text('Refresh'),
      ),
    ],
    child: Loaded<List<dynamic>>(
      future: _cases,
      isEmpty: (rows) => rows.isEmpty,
      emptyText: 'No open reports.',
      builder: (rows) => ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = rows[i] as Map<String, dynamic>;
          return ListTile(
            leading: r['child'] == true
                ? const Tooltip(
                    message: 'Involves a child',
                    child: Icon(Icons.child_care),
                  )
                : const Icon(Icons.flag_outlined),
            title: Text(
              '${r['kind']} · ${r['reports']} '
              '${r['reports'] == 1 ? 'report' : 'reports'}'
              '${r['hidden'] == true ? ' · hidden' : ''}',
            ),
            subtitle: Text((r['reasons'] as List).join(', ')),
            trailing: Text(
              'Answer by ${(r['deadline_at'] as String).substring(0, 16).replaceFirst('T', ' ')}',
              style: OgText.body(13, color: context.og.textMuted),
            ),
            onTap: () => context.go('/reports/${r['id']}'),
          );
        },
      ),
    ),
  );
}

class CaseScreen extends ConsumerStatefulWidget {
  const CaseScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<CaseScreen> createState() => _CaseScreenState();
}

class _CaseScreenState extends ConsumerState<CaseScreen> {
  late final Future<Map<String, dynamic>> _case = _load();

  Future<Map<String, dynamic>> _load() async =>
      await ref.read(staffApiProvider).read('staff_case_get', {
        'p_case': widget.id,
      }) as Map<String, dynamic>;

  Future<void> _act(
    String title,
    String action,
    Map<String, dynamic> Function(String reason) params,
  ) async {
    final reason = await askReason(context, title);
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act(action, params(reason));
      if (!mounted) return;
      toast(context, 'Done');
      context.go('/reports');
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'Report',
    child: Loaded<Map<String, dynamic>>(
      future: _case,
      builder: (c) {
        final owner = c['owner_id'] as String?;
        return ListView(
          children: [
            Text('${c['target_kind']}', style: OgText.section),
            const SizedBox(height: 8),
            SelectableText(
              c['text'] as String? ?? 'This item no longer exists.',
              style: OgText.lead(context.og.text),
            ),
            // A file matched as abuse imagery is never played.
            if (c['target_kind'] == 'video' &&
                c['text'] != 'Blocked video') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () =>
                      showPostVideo(context, ref, c['target_id'] as String),
                  child: const Text('Play video'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Warnings on this account: ${c['owner_warnings']}',
              style: OgText.label,
            ),
            const SizedBox(height: 16),
            Text('Reports', style: OgText.section),
            for (final r in c['reports'] as List)
              ListTile(
                title: Text(r['reason'] as String),
                subtitle: Text(r['note'] as String? ?? ''),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _act(
                    'Restore this item',
                    'staff_case_decide',
                    (reason) => {
                      'p_case': widget.id,
                      'p_outcome': 'kept',
                      'p_reason': reason,
                    },
                  ),
                  child: const Text('Restore'),
                ),
                FilledButton(
                  onPressed: () => _act(
                    'Remove this item',
                    'staff_case_decide',
                    (reason) => {
                      'p_case': widget.id,
                      'p_outcome': 'removed',
                      'p_reason': reason,
                    },
                  ),
                  child: const Text('Remove'),
                ),
                if (owner != null) ...[
                  OutlinedButton(
                    onPressed: () => _act(
                      'Warn this person',
                      'staff_warn',
                      (reason) => {'p_user': owner, 'p_reason': reason},
                    ),
                    child: const Text('Warn'),
                  ),
                  OutlinedButton(
                    onPressed: () => _act(
                      'Suspend for 7 days',
                      'staff_suspend',
                      (reason) => {
                        'p_user': owner,
                        'p_days': 7,
                        'p_reason': reason,
                      },
                    ),
                    child: const Text('Suspend 7 days'),
                  ),
                  OutlinedButton(
                    onPressed: () => _act(
                      'Ask a second person to ban',
                      'staff_ban_request',
                      (reason) => {'p_user': owner, 'p_reason': reason},
                    ),
                    child: const Text('Request a ban'),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    ),
  );
}

/// R-MOD-4: bans wait here for a second staff member.
class BansScreen extends ConsumerStatefulWidget {
  const BansScreen({super.key});

  @override
  ConsumerState<BansScreen> createState() => _BansScreenState();
}

class _BansScreenState extends ConsumerState<BansScreen> {
  late Future<List<dynamic>> _bans = _load();

  Future<List<dynamic>> _load() async =>
      await ref.read(staffApiProvider).read('staff_ban_list') as List<dynamic>;

  Future<void> _decide(String id, bool approve) async {
    final reason = await askReason(
      context,
      approve ? 'Approve this ban' : 'Refuse this ban',
    );
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act('staff_ban_decide', {
        'p_request': id,
        'p_approve': approve,
        'p_reason': reason,
      });
      setState(() => _bans = _load());
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'Bans waiting',
    child: Loaded<List<dynamic>>(
      future: _bans,
      isEmpty: (rows) => rows.isEmpty,
      emptyText: 'No bans waiting.',
      builder: (rows) => ListView(
        children: [
          for (final r in rows.cast<Map<String, dynamic>>())
            ListTile(
              title: Text(r['reason'] as String),
              subtitle: Text(
                r['mine'] == true
                    ? 'You asked. A second person has to decide.'
                    : 'Waiting for you',
              ),
              trailing: r['mine'] == true
                  ? null
                  : Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => _decide(r['id'] as String, false),
                          child: const Text('Refuse'),
                        ),
                        FilledButton(
                          onPressed: () => _decide(r['id'] as String, true),
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    ),
  );
}
