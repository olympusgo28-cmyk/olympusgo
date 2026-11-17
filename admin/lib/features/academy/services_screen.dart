import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

/// Partner physios. Staff see a count per partner, never who was referred.
class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  late Future<List<dynamic>> _rows = _load();

  Future<List<dynamic>> _load() async =>
      await ref.read(staffApiProvider).read('staff_service_list')
          as List<dynamic>;

  Future<void> _save(Map<String, dynamic> p, String title) async {
    final reason = await askReason(context, title);
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act('staff_service_save', {
        'p': p,
        'p_reason': reason,
      });
      setState(() {
        _rows = _load();
      });
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: row?['name'] as String?);
    final area = TextEditingController(text: row?['area'] as String?);
    final blurb = TextEditingController(text: row?['blurb'] as String?);
    final link = TextEditingController(text: row?['booking_url'] as String?);
    final code = TextEditingController(text: row?['ref_code'] as String?);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(row == null ? 'New partner' : 'Edit partner'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: area,
                decoration: const InputDecoration(labelText: 'Area'),
              ),
              TextField(
                controller: blurb,
                decoration: const InputDecoration(labelText: 'About'),
              ),
              TextField(
                controller: link,
                decoration: const InputDecoration(
                  labelText: 'Booking link',
                  helperText: 'Their own page, starting with https://',
                ),
              ),
              TextField(
                controller: code,
                decoration: const InputDecoration(
                  labelText: 'Reference code',
                  helperText: 'Added to the link so they know it came from us',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _save({
      'id': ?row?['id'],
      'name': name.text.trim(),
      'area': area.text.trim(),
      'blurb': blurb.text.trim(),
      'booking_url': link.text.trim(),
      'ref_code': code.text.trim(),
    }, row == null ? 'Add a partner' : 'Change this partner');
  }

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'Services',
    actions: [FilledButton(onPressed: _edit, child: const Text('New partner'))],
    child: Loaded<List<dynamic>>(
      future: _rows,
      isEmpty: (r) => r.isEmpty,
      emptyText: 'No partners yet.',
      builder: (rows) => ListView(
        children: [
          for (final p in rows.cast<Map<String, dynamic>>())
            ListTile(
              title: Text('${p['name']}'),
              subtitle: Text(
                [
                  if ('${p['area']}'.isNotEmpty) p['area'],
                  p['active'] == true ? 'Live' : 'Hidden',
                  '${p['referrals']} referrals',
                ].join(' · '),
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: () => _edit(p),
                    child: const Text('Edit'),
                  ),
                  TextButton(
                    onPressed: () => _save({
                      ...p,
                      'active': p['active'] != true,
                    }, p['active'] == true ? 'Hide partner' : 'Show partner'),
                    child: Text(p['active'] == true ? 'Hide' : 'Show'),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
