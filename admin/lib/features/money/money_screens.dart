import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_design/og_design.dart';
import 'package:og_money/og_money.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

String _money(Object? minor) => '${Money((minor as num? ?? 0).toInt())}';

String _day(Object? at) => at == null ? '—' : (at as String).substring(0, 10);

/// Held money, refunds, payouts, disputes and alerts. Payments staff only:
/// the database checks the role and MFA on every call.
class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  late Future<Map<String, dynamic>> _overview = _load();
  int _version = 0;

  Future<Map<String, dynamic>> _load() async =>
      await ref.read(staffApiProvider).read('staff_money_overview')
          as Map<String, dynamic>;

  void _refresh() => setState(() {
    _overview = _load();
    _version++;
  });

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 6,
    child: StaffPage(
      title: 'Payments',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Loaded<Map<String, dynamic>>(
            future: _overview,
            builder: (o) => Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _Figure('Held', _money(o['held_minor'])),
                _Figure('Refunds pending', _money(o['refunds_pending_minor'])),
                _Figure('Failed refunds', '${o['failed_refunds']}'),
                _Figure('Open holds', '${o['open_holds']}'),
                _Figure('Open disputes', '${o['open_disputes']}'),
                _Figure('Suspense', _money(o['suspense_minor'])),
                _Figure('Open alerts', '${o['open_alerts']}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Alerts'),
              Tab(text: 'Held money'),
              Tab(text: 'Payouts'),
              Tab(text: 'Refunds'),
              Tab(text: 'Payments'),
              Tab(text: 'Disputes'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              key: ValueKey(_version),
              children: [
                _AlertsTab(onChanged: _refresh),
                _HeldTab(onChanged: _refresh),
                _PayoutsTab(onChanged: _refresh),
                _RefundsTab(onChanged: _refresh),
                _PaymentsTab(onChanged: _refresh),
                const _DisputesTab(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: OgText.h1),
      Text(label, style: OgText.body(13, color: context.og.textMuted)),
    ],
  );
}

/// One write: asks why, calls the Edge Function, reports what went wrong.
Future<bool> _act(
  BuildContext context,
  WidgetRef ref,
  String title,
  String action,
  Map<String, dynamic> params,
) async {
  final reason = await askReason(context, title);
  if (reason == null || !context.mounted) return false;
  try {
    await ref.read(staffApiProvider).act(action, {
      ...params,
      'p_reason': reason,
    });
    return true;
  } on StaffFailure catch (e) {
    if (context.mounted) toast(context, e.message);
    return false;
  }
}

class _ListTab extends ConsumerStatefulWidget {
  const _ListTab({
    required this.function,
    required this.emptyText,
    required this.row,
  });

  final String function;
  final String emptyText;
  final Widget Function(Map<String, dynamic> row) row;

  @override
  ConsumerState<_ListTab> createState() => _ListTabState();
}

class _ListTabState extends ConsumerState<_ListTab> {
  late final Future<List<dynamic>> _rows = ref
      .read(staffApiProvider)
      .read(widget.function)
      .then((r) => r as List<dynamic>);

  @override
  Widget build(BuildContext context) => Loaded<List<dynamic>>(
    future: _rows,
    isEmpty: (r) => r.isEmpty,
    emptyText: widget.emptyText,
    builder: (rows) => ListView(
      children: [for (final r in rows) widget.row(r as Map<String, dynamic>)],
    ),
  );
}

class _AlertsTab extends ConsumerWidget {
  const _AlertsTab({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _ListTab(
    function: 'staff_alert_list',
    emptyText: 'No open alerts.',
    row: (a) => ListTile(
      title: Text(a['kind'] as String),
      subtitle: Text('${_day(a['created_at'])} · ${a['detail']}'),
      trailing: Wrap(
        spacing: 8,
        children: [
          if (a['kind'] == 'suspense')
            TextButton(
              onPressed: () async {
                if (await _act(
                  context,
                  ref,
                  'I returned this in Stripe',
                  'staff_suspense_clear',
                  {'p_intent': (a['detail'] as Map)['intent']},
                )) {
                  onChanged();
                }
              },
              child: const Text('Returned in Stripe'),
            ),
          TextButton(
            onPressed: () async {
              if (await _act(
                context,
                ref,
                'Close this alert',
                'staff_alert_close',
                {'p_alert': a['id']},
              )) {
                onChanged();
              }
            },
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}

class _HeldTab extends ConsumerWidget {
  const _HeldTab({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> decide(Map<String, dynamic> h, bool refund) async {
      if (await _act(
        context,
        ref,
        refund ? 'Refund everyone' : 'Release this money',
        'staff_hold_decide',
        {'p_activity': h['activity_id'], 'p_refund_all': refund},
      )) {
        onChanged();
      }
    }

    return _ListTab(
      function: 'staff_held_list',
      emptyText: 'Nothing is held.',
      row: (h) => ListTile(
        title: Text('${h['title']} · ${_money(h['held_minor'])}'),
        subtitle: Text(
          'Ended ${_day(h['ends_at'])} · held since ${_day(h['oldest'])}'
          '${h['hold_id'] == null ? '' : ' · held by a report'}',
        ),
        trailing: h['hold_id'] == null
            ? null
            : Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => decide(h, false),
                    child: const Text('Release'),
                  ),
                  TextButton(
                    onPressed: () => decide(h, true),
                    child: const Text('Refund everyone'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PayoutsTab extends ConsumerWidget {
  const _PayoutsTab({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _ListTab(
    function: 'staff_payout_list',
    emptyText: 'No payout runs yet. One is prepared each Monday.',
    row: (p) {
      final waiting = p['status'] == 'prepared';
      final second = p['first_approver'] != null;
      return ListTile(
        title: Text('Week of ${p['week_start']} · ${_money(p['total_minor'])}'),
        subtitle: Text(
          '${p['status']} · ${(p['items'] as List).length} payees'
          '${p['needs_second'] == true ? ' · needs a second approver' : ''}',
        ),
        trailing: waiting
            ? FilledButton(
                onPressed: () async {
                  if (await _act(
                    context,
                    ref,
                    second ? 'Second approval' : 'Approve this run',
                    'staff_payout_approve',
                    {'p_run': p['id']},
                  )) {
                    onChanged();
                  }
                },
                child: Text(second ? 'Second approval' : 'Approve'),
              )
            : null,
      );
    },
  );
}

class _RefundsTab extends ConsumerWidget {
  const _RefundsTab({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> manual(Map<String, dynamic> r) async {
      final reference = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Paid by bank transfer'),
          content: TextField(
            controller: reference,
            decoration: const InputDecoration(labelText: 'Transfer reference'),
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
      if (ok != true || !context.mounted) return;
      if (await _act(
        context,
        ref,
        'Record this transfer',
        'staff_refund_manual',
        {'p_refund': r['id'], 'p_reference': reference.text.trim()},
      )) {
        onChanged();
      }
    }

    Future<void> simple(String title, String action, String id) async {
      if (await _act(context, ref, title, action, {'p_refund': id})) {
        onChanged();
      }
    }

    return _ListTab(
      function: 'staff_refund_list',
      emptyText: 'No refunds yet.',
      row: (r) => ListTile(
        title: Text('${_money(r['amount_minor'])} · ${r['reason']}'),
        subtitle: Text(
          '${r['status']} · ${_day(r['created_at'])}'
          '${r['failure_code'] == null ? '' : ' · ${r['failure_code']}'}',
        ),
        trailing: r['status'] == 'failed'
            ? Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => simple(
                      'Retry this refund',
                      'staff_refund_retry',
                      r['id'] as String,
                    ),
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () => manual(r),
                    child: const Text('Paid by bank'),
                  ),
                  TextButton(
                    onPressed: () => simple(
                      'Void this refund',
                      'staff_refund_void',
                      r['id'] as String,
                    ),
                    child: const Text('Void'),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _ListTab(
    function: 'staff_payment_list',
    emptyText: 'No payments yet.',
    row: (p) => ListTile(
      title: Text('${_money(p['amount_minor'])} · ${p['purpose']}'),
      subtitle: Text(
        '${p['receipt_no']} · ${p['status']} · ${p['method'] ?? 'no method'} · '
        '${_day(p['created_at'])}'
        '${(p['refunded_minor'] as num) > 0 ? ' · refunded ${_money(p['refunded_minor'])}' : ''}',
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) =>
            _PaymentDialog(id: p['id'] as String, onChanged: onChanged),
      ),
    ),
  );
}

/// One payment with its ledger lines.
class _PaymentDialog extends ConsumerStatefulWidget {
  const _PaymentDialog({required this.id, required this.onChanged});
  final String id;
  final VoidCallback onChanged;

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  late final Future<Map<String, dynamic>> _payment = ref
      .read(staffApiProvider)
      .read('staff_payment_get', {'p_payment': widget.id})
      .then((r) => r as Map<String, dynamic>);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Payment'),
    content: SizedBox(
      width: 560,
      child: Loaded<Map<String, dynamic>>(
        future: _payment,
        builder: (p) => ListView(
          shrinkWrap: true,
          children: [
            Text(
              '${p['receipt_no']} · ${_money(p['amount_minor'])} · ${p['status']}',
            ),
            const SizedBox(height: 12),
            Text('Ledger', style: OgText.body(15, weight: FontWeight.w600)),
            for (final l in p['ledger'] as List)
              Text(
                '${_day(l['at'])}  ${l['kind']}  ${l['account']}  '
                '${_money(l['amount_minor'])}',
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
      FilledButton(
        onPressed: () async {
          if (await _act(
            context,
            ref,
            'Refund what’s left',
            'staff_refund_issue',
            {'p_payment': widget.id},
          )) {
            widget.onChanged();
            if (context.mounted) Navigator.of(context).pop();
          }
        },
        child: const Text('Refund what’s left'),
      ),
    ],
  );
}

class _DisputesTab extends StatelessWidget {
  const _DisputesTab();

  @override
  Widget build(BuildContext context) => _ListTab(
    function: 'staff_dispute_list',
    emptyText:
        'No disputes. PayNow can’t be disputed, so these are cards only.',
    row: (d) => ListTile(
      title: Text('${_money(d['amount_minor'])} · ${d['status']}'),
      subtitle: Text('${d['stripe_dispute_id']} · ${_day(d['created_at'])}'),
    ),
  );
}
