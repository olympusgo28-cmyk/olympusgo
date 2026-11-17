import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_design/og_design.dart';
import 'package:og_money/og_money.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

String _money(Object? minor) => '${Money((minor as num? ?? 0).toInt())}';

String _day(Object? at) => at == null
    ? '—'
    : DateTime.parse(at as String).toLocal().toString().substring(0, 10);

const _stepNames = {
  'pending': 'To pay',
  'paid': 'Paid',
  'started': 'In progress',
  'ready': 'Ready to collect',
  'collected': 'Collected',
  'reported': 'Problem reported',
  'cancelled': 'Cancelled',
  'expired': 'Expired',
  'released': 'Paid to the shop',
  'refunded': 'Refunded',
};

/// Orders, handover reports, the commission switch, shop owners and points
/// blocks. Payments staff only: the database checks the role and MFA on every
/// call.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  late Future<List<dynamic>> _orders = _load();
  // A second tab may never open, so its failure can't go unheard.
  late Future<List<dynamic>> _shops = _loadShops()..ignore();

  Future<List<dynamic>> _load() async =>
      await ref.read(staffApiProvider).read('staff_order_list')
          as List<dynamic>;

  Future<List<dynamic>> _loadShops() async =>
      await ref.read(staffApiProvider).read('staff_shop_list') as List<dynamic>;

  void _refresh() => setState(() {
    _orders = _load();
    _shops = _loadShops()..ignore();
  });

  /// One write: asks why, calls the Edge Function, reports what went wrong.
  Future<bool> _act(
    String title,
    String action,
    Map<String, dynamic> params,
  ) async {
    final reason = await askReason(context, title);
    if (reason == null || !mounted) return false;
    try {
      await ref.read(staffApiProvider).act(action, {
        ...params,
        'p_reason': reason,
      });
      _refresh();
      return true;
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
      return false;
    }
  }

  Future<void> _open(Map<String, dynamic> row) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _OrderDialog(id: row['id'] as String, act: _act),
    );
  }

  Future<void> _linkOwner(Map<String, dynamic> shop) async {
    final name = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link an owner'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Their OlympusGO username',
              helperText:
                  'They see the orders and are paid through their payout '
                  'account.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isNotEmpty) {
                Navigator.of(context).pop(name.text.trim());
              }
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
    if (username == null) return;
    await _act('Link this owner', 'staff_shop_link_owner', {
      'p_mall': shop['id'],
      'p_username': username,
    });
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: StaffPage(
      title: 'Orders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Shops'),
              Tab(text: 'Points'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                Loaded<List<dynamic>>(
                  future: _orders,
                  isEmpty: (r) => r.isEmpty,
                  emptyText: 'No orders yet.',
                  builder: (rows) => ListView(
                    children: [
                      for (final o in rows.cast<Map<String, dynamic>>())
                        ListTile(
                          title: Text(
                            '${o['mall']} · ${_money(o['amount_minor'])}',
                          ),
                          subtitle: Text(
                            [
                              _stepNames[o['step']] ?? '${o['step']}',
                              _day(o['placed_at']),
                              if (o['report_note'] != null)
                                '${o['report_note']}',
                            ].join(' · '),
                          ),
                          trailing: TextButton(
                            onPressed: () => _open(o),
                            child: Text(
                              o['step'] == 'reported' ? 'Decide' : 'Open',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Loaded<List<dynamic>>(
                  future: _shops,
                  isEmpty: (r) => r.isEmpty,
                  emptyText: 'No shops yet.',
                  builder: (rows) => ListView(
                    children: [
                      for (final s in rows.cast<Map<String, dynamic>>())
                        ListTile(
                          title: Text('${s['name']}'),
                          subtitle: Text(
                            [
                              s['owner'] == null
                                  ? 'No owner yet'
                                  : 'Owner ${s['owner']}',
                              s['commission_on_top'] == true
                                  ? 'Commission added on top of the price'
                                  : 'Commission taken out of the price',
                            ].join(' · '),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => _linkOwner(s),
                                child: const Text('Link owner'),
                              ),
                              TextButton(
                                onPressed: () => _act(
                                  'Change the commission for new orders',
                                  'staff_shop_commission_set',
                                  {
                                    'p_mall': s['id'],
                                    'p_on_top': s['commission_on_top'] != true,
                                  },
                                ),
                                child: Text(
                                  s['commission_on_top'] == true
                                      ? 'Take out of price'
                                      : 'Add on top',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _PointsTab(act: _act),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _OrderDialog extends ConsumerStatefulWidget {
  const _OrderDialog({required this.id, required this.act});

  final String id;
  final Future<bool> Function(String, String, Map<String, dynamic>) act;

  @override
  ConsumerState<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends ConsumerState<_OrderDialog> {
  late final Future<Map<String, dynamic>> _order = ref
      .read(staffApiProvider)
      .read('staff_order_get', {'p_order': widget.id})
      .then((r) => r as Map<String, dynamic>);

  final _take = <String, int>{};
  bool _restock = false;
  bool _busy = false;

  /// One decision. Quantities are relative, so a repeat must not refund more.
  final _key =
      'order-${DateTime.now().microsecondsSinceEpoch}-'
      '${Random.secure().nextInt(1000000000)}';

  Future<void> _decide(String title, List<Map<String, dynamic>> lines) async {
    setState(() => _busy = true);
    var done = false;
    try {
      done = await widget.act(title, 'staff_order_decide', {
        'p_order': widget.id,
        'p_lines': lines,
        'p_restock': _restock,
        'p_key': _key,
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (done && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Order'),
    content: SizedBox(
      width: 520,
      child: Loaded<Map<String, dynamic>>(
        future: _order,
        builder: (o) {
          final open = const {
            'reported',
            'paid',
            'started',
            'ready',
            'collected',
            'released',
          }.contains(o['step']);
          final lines = (o['lines'] as List).cast<Map<String, dynamic>>();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${o['mall_name']} · ${_stepNames[o['step']] ?? o['step']}',
                style: OgText.body(16, weight: FontWeight.w600),
              ),
              if (o['report_note'] != null) ...[
                const SizedBox(height: 8),
                Text('${o['report_note']}'),
              ],
              const SizedBox(height: 8),
              for (final l in lines)
                _LineRow(
                  line: l,
                  take: _take[l['id']] ?? 0,
                  onChanged: open
                      ? (n) => setState(() => _take[l['id'] as String] = n)
                      : null,
                ),
              if (open && o['service'] != true)
                SwitchListTile(
                  title: const Text('Put refunded items back in stock'),
                  value: _restock,
                  onChanged: (v) => setState(() => _restock = v),
                ),
            ],
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
      FutureBuilder<Map<String, dynamic>>(
        future: _order,
        builder: (context, snap) {
          final o = snap.data;
          // Past its date with the shop silent, staff decide that too.
          final due =
              o?['step'] == 'reported' ||
              (const {'paid', 'started', 'ready'}.contains(o?['step']) &&
                  o?['release_at'] != null &&
                  DateTime.parse(o!['release_at'] as String)
                      .isBefore(DateTime.now()));
          if (_picked.isNotEmpty) {
            return FilledButton(
              onPressed: _busy
                  ? null
                  : () => _decide('Refund these items', _picked),
              child: const Text('Refund these items'),
            );
          }
          if (!due) return const SizedBox.shrink();
          return FilledButton(
            onPressed: _busy
                ? null
                : () => _decide('Release to the shop', const []),
            child: const Text('Release to the shop'),
          );
        },
      ),
    ],
  );

  List<Map<String, dynamic>> get _picked => [
    for (final MapEntry(:key, :value) in _take.entries)
      if (value > 0) {'line': key, 'qty': value},
  ];
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.take, this.onChanged});

  final Map<String, dynamic> line;
  final int take;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final left = (line['qty'] as int) - (line['refunded_qty'] as int? ?? 0);
    final set = onChanged;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${line['name']}'),
      subtitle: Text(
        '$left left · ${_money(line['unit_paid'])} each, the buyer paid',
      ),
      trailing: set == null || left == 0
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Refund one fewer',
                  icon: const Icon(Icons.remove),
                  onPressed: take > 0 ? () => set(take - 1) : null,
                ),
                Text('$take'),
                IconButton(
                  tooltip: 'Refund one more',
                  icon: const Icon(Icons.add),
                  onPressed: take < left ? () => set(take + 1) : null,
                ),
              ],
            ),
    );
  }
}

class _PointsTab extends StatefulWidget {
  const _PointsTab({required this.act});

  final Future<bool> Function(String, String, Map<String, dynamic>) act;

  @override
  State<_PointsTab> createState() => _PointsTabState();
}

class _PointsTabState extends State<_PointsTab> {
  final _user = TextEditingController();

  void _set(bool block) {
    final id = _user.text.trim();
    if (id.isEmpty) return;
    widget.act(
      block ? 'Block points, and lose what’s left' : 'Unblock points',
      'staff_points_block',
      {'p_user': id, 'p_block': block},
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 420,
        child: TextField(
          controller: _user,
          decoration: const InputDecoration(labelText: 'Player id'),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: [
          FilledButton(
            onPressed: () => _set(true),
            child: const Text('Block points'),
          ),
          OutlinedButton(
            onPressed: () => _set(false),
            child: const Text('Unblock'),
          ),
        ],
      ),
    ],
  );
}
