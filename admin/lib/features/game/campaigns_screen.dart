import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_money/og_money.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';
import '../auth/session.dart';

String _money(Object? minor) => '${Money((minor as num? ?? 0).toInt())}';

// Campaigns run on Singapore days, wherever staff are. Fixed at +8 hours until
// a campaign runs in another country.
const _sgt = Duration(hours: 8);

String _day(Object? at) => at == null
    ? '—'
    : DateTime.parse(at as String)
          .toUtc()
          .add(_sgt)
          .toString()
          .substring(0, 10);

/// The start of a typed Singapore day, or the last second of it.
String? _instant(String text, {bool end = false}) {
  final d = DateTime.tryParse(text.trim());
  if (d == null) return null;
  final start = DateTime.utc(d.year, d.month, d.day).subtract(_sgt);
  return (end ? start.add(const Duration(days: 1, seconds: -1)) : start)
      .toIso8601String();
}

const _questNames = {
  'play_sessions': 'Play sessions',
  'attend_sessions': 'Attend sessions',
  'organize_counted': 'Organize counted games',
};

const _reasonNames = {
  'counted': 'Counted',
  'before_payments': 'Before payments opened: ranks, earns nothing',
  'under_six': 'Not enough Present',
  'unpaid': 'Not everyone paid',
  'not_scanned': 'Not everyone scanned',
  'cancelled': 'Cancelled',
  'organizer_minor': 'Organizer under 18',
  'organizer_flagged': 'Organizer flagged',
};

/// Campaigns, voucher types, organizer games and redemptions. Content staff run
/// campaigns, payments staff set voucher types, and both can read all of it: the
/// database checks the role and MFA on every call.
class CampaignsScreen extends ConsumerStatefulWidget {
  const CampaignsScreen({super.key});

  @override
  ConsumerState<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends ConsumerState<CampaignsScreen> {
  StaffSession? _session;
  bool _can(String role) => _session?.has(role) ?? false;

  late Future<Map<String, dynamic>> _data = _load();
  late Future<List<dynamic>> _games = _list('staff_organizer_games')..ignore();
  late Future<List<dynamic>> _used = _list('staff_redemptions')..ignore();

  Future<Map<String, dynamic>> _load() async =>
      (await ref.read(staffApiProvider).read('staff_campaign_list') as Map)
          .cast<String, dynamic>();

  Future<List<dynamic>> _list(String fn) async =>
      await ref.read(staffApiProvider).read(fn) as List<dynamic>;

  void _refresh() => setState(() {
    _data = _load();
    _games = _list('staff_organizer_games')..ignore();
    _used = _list('staff_redemptions')..ignore();
  });

  Future<void> _act(
    String title,
    String action,
    Map<String, dynamic> params,
  ) async {
    final reason = await askReason(context, title);
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act(action, {
        ...params,
        'p_reason': reason,
      });
      _refresh();
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  Future<void> _editCampaign(
    Map<String, dynamic> data, [
    Map<String, dynamic>? row,
  ]) async {
    final p = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CampaignDialog(data: data, row: row),
    );
    if (p == null || !mounted) return;
    await _act(
      row == null ? 'Add a campaign' : 'Change this campaign',
      'staff_campaign_save',
      {'p': p},
    );
  }

  Future<void> _editType(Map<String, dynamic> data) async {
    final p = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _VoucherTypeDialog(data: data),
    );
    if (p == null || !mounted) return;
    await _act('Add a voucher type', 'staff_voucher_type_save', {'p': p});
  }

  Future<void> _addBadge() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New badge'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Next'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _act('Add a badge', 'staff_badge_save', {
      'p_name': name.text.trim(),
      'p_blurb': '',
    });
  }

  @override
  Widget build(BuildContext context) {
    _session = ref.watch(staffSessionProvider).value;
    return DefaultTabController(
      length: 4,
      child: StaffPage(
        title: 'Campaigns',
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Campaigns'),
                Tab(text: 'Voucher types'),
                Tab(text: 'Organizer games'),
                Tab(text: 'Redemptions'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  Loaded<Map<String, dynamic>>(
                    future: _data,
                    builder: (d) => _campaignTab(d),
                  ),
                  Loaded<Map<String, dynamic>>(
                    future: _data,
                    builder: (d) => _typeTab(d),
                  ),
                  Loaded<List<dynamic>>(
                    future: _games,
                    isEmpty: (r) => r.isEmpty,
                    emptyText: 'No Meets looked at yet.',
                    builder: (rows) => ListView(
                      children: [
                        for (final g in rows.cast<Map<String, dynamic>>())
                          ListTile(
                            title: Text('${g['title']} · ${g['organizer']}'),
                            subtitle: Text(
                              [
                                _day(g['at']),
                                _reasonNames[g['reason']] ?? '${g['reason']}',
                                '${g['present']} Present',
                                if (g['game_no'] != null)
                                  'Game ${g['game_no']}',
                              ].join(' · '),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Loaded<List<dynamic>>(
                    future: _used,
                    isEmpty: (r) => r.isEmpty,
                    emptyText: 'No vouchers used yet.',
                    builder: (rows) => ListView(
                      children: [
                        for (final r in rows.cast<Map<String, dynamic>>())
                          ListTile(
                            title: Text(
                              '${r['voucher']} · ${_money(r['amount_minor'])}',
                            ),
                            subtitle: Text(
                              [
                                '${r['user']}',
                                '${r['mall']}',
                                _day(r['at']),
                                r['kind'] == 'used' ? 'Used' : 'Returned',
                              ].join(' · '),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campaignTab(Map<String, dynamic> d) {
    final rows = (d['campaigns'] as List).cast<Map<String, dynamic>>();
    return ListView(
      children: [
        if (_can('content'))
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => _editCampaign(d),
                child: const Text('New campaign'),
              ),
              OutlinedButton(
                onPressed: _addBadge,
                child: const Text('New badge'),
              ),
            ],
          ),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('No campaigns yet.'),
          ),
        for (final c in rows)
          ListTile(
            title: Text('${c['title']}'),
            subtitle: Text(
              [
                '${c['status']}',
                '${_day(c['starts_at'])} to ${_day(c['ends_at'])}',
                '${c['players']} in',
              ].join(' · '),
            ),
            trailing: !_can('content')
                ? null
                : Wrap(
                    spacing: 8,
                    children: [
                      if (c['status'] != 'ended')
                        TextButton(
                          onPressed: () => _editCampaign(d, c),
                          child: const Text('Edit'),
                        ),
                      if (c['status'] == 'draft')
                        TextButton(
                          onPressed: () => _act(
                            'Publish this campaign',
                            'staff_campaign_status',
                            {'p_campaign': c['id'], 'p_status': 'live'},
                          ),
                          child: const Text('Publish'),
                        ),
                      if (c['status'] == 'live')
                        TextButton(
                          onPressed: () => _act(
                            'End this campaign',
                            'staff_campaign_status',
                            {'p_campaign': c['id'], 'p_status': 'ended'},
                          ),
                          child: const Text('End'),
                        ),
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _typeTab(Map<String, dynamic> d) {
    final rows = (d['voucher_types'] as List).cast<Map<String, dynamic>>();
    return ListView(
      children: [
        if (_can('payments'))
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => _editType(d),
              child: const Text('New voucher type'),
            ),
          ),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('No voucher types yet.'),
          ),
        for (final t in rows)
          ListTile(
            title: Text('${t['name']} · ${_money(t['amount_minor'])} off'),
            subtitle: Text(
              [
                'Voucher ${t['kind']}',
                '${t['funder']}',
                if (t['organizer_default'] == true) 'Organizer reward',
                if (t['active'] == false) 'Switched off',
                '${t['issued']} issued',
              ].join(' · '),
            ),
            trailing: !_can('payments')
                ? null
                : Wrap(
                    spacing: 8,
                    children: [
                      if (t['organizer_default'] != true)
                        TextButton(
                          onPressed: () => _act(
                            'Make this the organizer reward',
                            'staff_voucher_type_save',
                            {
                              'p': {
                                'id': t['id'],
                                'name': t['name'],
                                'organizer_default': true,
                              },
                            },
                          ),
                          child: const Text('Use as reward'),
                        ),
                      TextButton(
                        onPressed: () => _act(
                          t['active'] == false
                              ? 'Switch this voucher on'
                              : 'Switch this voucher off',
                          'staff_voucher_type_save',
                          {
                            'p': {
                              'id': t['id'],
                              'name': t['name'],
                              'organizer_default': t['organizer_default'],
                              'active': t['active'] == false,
                            },
                          },
                        ),
                        child: Text(
                          t['active'] == false ? 'Switch on' : 'Switch off',
                        ),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}

class _CampaignDialog extends StatefulWidget {
  const _CampaignDialog({required this.data, this.row});

  final Map<String, dynamic> data;
  final Map<String, dynamic>? row;

  @override
  State<_CampaignDialog> createState() => _CampaignDialogState();
}

class _CampaignDialogState extends State<_CampaignDialog> {
  late final _title = TextEditingController(
    text: widget.row?['title'] as String?,
  );
  late final _blurb = TextEditingController(
    text: widget.row?['blurb'] as String?,
  );
  late final _about = TextEditingController(
    text: widget.row?['about'] as String?,
  );
  late final _starts = TextEditingController(
    text: widget.row == null ? '' : _day(widget.row!['starts_at']),
  );
  late final _ends = TextEditingController(
    text: widget.row == null ? '' : _day(widget.row!['ends_at']),
  );
  late final _target = TextEditingController(text: '${_quest?['target'] ?? 4}');
  late String _type = _quest?['type'] as String? ?? 'play_sessions';
  late String? _voucher = _quest?['voucher_type_id'] as String?;
  late String? _badge = _quest?['badge_id'] as String?;
  String? _problem;

  Map<String, dynamic>? get _quest =>
      ((widget.row?['quests'] as List?)?.firstOrNull as Map?)
          ?.cast<String, dynamic>();

  bool get _draft => widget.row == null || widget.row!['status'] == 'draft';

  String? _unchanged(String typed, String field) {
    final was = widget.row?[field];
    return was != null && typed.trim() == _day(was) ? was as String : null;
  }

  void _done() {
    final starts = _instant(_starts.text);
    final ends = _instant(_ends.text, end: true);
    final target = int.tryParse(_target.text.trim());
    final title = _title.text.trim();
    if (title.length < 2 || title.length > 80) {
      setState(() => _problem = 'Give it a title of 2 to 80 characters.');
    } else if (_blurb.text.trim().length > 200) {
      setState(() => _problem = 'Keep the short line to 200 characters.');
    } else if (_about.text.trim().length > 1000) {
      setState(() => _problem = 'Keep About to 1,000 characters.');
    } else if (starts == null || ends == null) {
      setState(() => _problem = 'Dates look like 2026-11-30.');
    } else if (target == null || target < 1 || target > 1000) {
      setState(() => _problem = 'Set a target from 1 to 1,000.');
    } else if (_voucher == null && _badge == null) {
      setState(() => _problem = 'Pick a reward.');
    } else {
      Navigator.of(context).pop({
        'id': ?widget.row?['id'],
        'title': title,
        'blurb': _blurb.text.trim(),
        'about': _about.text.trim(),
        // A date left alone keeps its exact time, whatever day it shows as.
        'starts_at': _unchanged(_starts.text, 'starts_at') ?? starts,
        'ends_at': _unchanged(_ends.text, 'ends_at') ?? ends,
        'quests': [
          {
            'type': _type,
            'target': target,
            'voucher_type_id': _voucher,
            'badge_id': _badge,
          },
        ],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = (widget.data['voucher_types'] as List)
        .cast<Map<String, dynamic>>();
    final badges = (widget.data['badges'] as List).cast<Map<String, dynamic>>();
    return AlertDialog(
      title: Text(widget.row == null ? 'New campaign' : 'Edit campaign'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _blurb,
                decoration: const InputDecoration(labelText: 'Short line'),
              ),
              TextField(
                controller: _about,
                decoration: const InputDecoration(labelText: 'About'),
              ),
              TextField(
                controller: _starts,
                enabled: _draft,
                decoration: const InputDecoration(
                  labelText: 'Starts',
                  hintText: '2026-11-01',
                ),
              ),
              TextField(
                controller: _ends,
                decoration: const InputDecoration(
                  labelText: 'Ends',
                  hintText: '2026-11-30',
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Quest'),
                items: [
                  for (final e in _questNames.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: _draft
                    ? (v) => setState(() => _type = v ?? _type)
                    : null,
              ),
              TextField(
                controller: _target,
                enabled: _draft,
                decoration: const InputDecoration(labelText: 'Target'),
              ),
              DropdownButtonFormField<String?>(
                initialValue: _voucher,
                decoration: const InputDecoration(labelText: 'Voucher'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  for (final t in types)
                    DropdownMenuItem(
                      value: t['id'] as String,
                      child: Text('${t['name']}'),
                    ),
                ],
                onChanged: _draft ? (v) => setState(() => _voucher = v) : null,
              ),
              DropdownButtonFormField<String?>(
                initialValue: _badge,
                decoration: const InputDecoration(labelText: 'Badge'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  for (final b in badges)
                    DropdownMenuItem(
                      value: b['id'] as String,
                      child: Text('${b['name']}'),
                    ),
                ],
                onChanged: _draft ? (v) => setState(() => _badge = v) : null,
              ),
              if (!_draft)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('A live campaign’s quest stays as it is.'),
                ),
              if (_problem != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_problem!),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _done, child: const Text('Next')),
      ],
    );
  }
}

class _VoucherTypeDialog extends StatefulWidget {
  const _VoucherTypeDialog({required this.data});

  final Map<String, dynamic> data;

  @override
  State<_VoucherTypeDialog> createState() => _VoucherTypeDialogState();
}

class _VoucherTypeDialogState extends State<_VoucherTypeDialog> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _days = TextEditingController(text: '90');
  String _kind = 'A';
  String? _funder;
  bool _reward = false;
  String? _problem;

  void _done() {
    final minor = parseMinor(_amount.text.trim());
    final days = int.tryParse(_days.text.trim());
    if (_name.text.trim().length < 2) {
      setState(() => _problem = 'Give it a name.');
    } else if (minor == null || minor <= 0 || minor > 100000) {
      setState(() => _problem = 'Set an amount up to S\$1,000.00, like 8.00.');
    } else if (days == null || days < 1 || days > 365) {
      setState(() => _problem = 'A voucher lasts 1 to 365 days.');
    } else if (_funder == null) {
      setState(() => _problem = 'Pick who funds it.');
    } else {
      Navigator.of(context).pop({
        'name': _name.text.trim(),
        'kind': _kind,
        'mall_id': _kind == 'A' ? _funder : null,
        'venue_id': _kind == 'B' ? _funder : null,
        'amount_minor': minor,
        'expiry_days': days,
        'organizer_default': _reward,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final funders =
        ((_kind == 'A' ? widget.data['shops'] : widget.data['venues']) as List)
            .cast<Map<String, dynamic>>();
    return AlertDialog(
      title: const Text('New voucher type'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Funded by'),
              items: const [
                DropdownMenuItem(value: 'A', child: Text('A shop (Voucher A)')),
                DropdownMenuItem(
                  value: 'B',
                  child: Text('A venue (Voucher B)'),
                ),
              ],
              onChanged: (v) => setState(() {
                _kind = v ?? _kind;
                _funder = null;
              }),
            ),
            DropdownButtonFormField<String?>(
              key: ValueKey(_kind),
              initialValue: _funder,
              decoration: const InputDecoration(labelText: 'Who'),
              items: [
                for (final f in funders)
                  DropdownMenuItem(
                    value: f['id'] as String,
                    child: Text('${f['name']}'),
                  ),
              ],
              onChanged: (v) => setState(() => _funder = v),
            ),
            TextField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Amount off (S\$)'),
            ),
            TextField(
              controller: _days,
              decoration: const InputDecoration(labelText: 'Days it lasts'),
            ),
            CheckboxListTile(
              value: _reward,
              contentPadding: EdgeInsets.zero,
              title: const Text('Use as the organizer reward'),
              onChanged: (v) => setState(() => _reward = v ?? false),
            ),
            if (_problem != null) Text(_problem!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _done, child: const Text('Next')),
      ],
    );
  }
}
