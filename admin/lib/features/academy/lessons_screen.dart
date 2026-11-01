import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_money/og_money.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

const _stepNames = {
  'paid': 'Paid',
  'marked': 'Attendance saved',
  'late_cancelled': 'Cancelled late',
  'reported': 'Problem reported',
  'released': 'Paid to the academy',
  'refunded': 'Refunded',
};

/// Paid lessons and their reports. A lesson is only ever refunded from here,
/// so its step and its money stay together.
class LessonsScreen extends ConsumerStatefulWidget {
  const LessonsScreen({super.key});

  @override
  ConsumerState<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends ConsumerState<LessonsScreen> {
  late Future<List<dynamic>> _rows = _load();

  Future<List<dynamic>> _load() async =>
      await ref.read(staffApiProvider).read('staff_lesson_list')
          as List<dynamic>;

  Future<void> _decide(String title, String id, {required bool refund}) async {
    final reason = await askReason(context, title);
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act('staff_lesson_decide', {
        'p_booking': id,
        'p_refund': refund,
        'p_reason': reason,
      });
      setState(() {
        _rows = _load();
      });
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'Lessons',
    child: Loaded<List<dynamic>>(
      future: _rows,
      isEmpty: (r) => r.isEmpty,
      emptyText: 'No lessons yet.',
      builder: (rows) => ListView(
        children: [
          for (final b in rows.cast<Map<String, dynamic>>())
            ListTile(
              title: Text(
                '${b['title']} · ${Money((b['amount_minor'] as num? ?? 0).toInt())}',
              ),
              subtitle: Text(
                [
                  b['academy'],
                  _stepNames[b['step']] ?? '${b['step']}',
                  '${b['starts_at']}'.substring(0, 10),
                  if (b['report_note'] != null) b['report_note'],
                ].join(' · '),
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  if (b['step'] == 'reported')
                    TextButton(
                      onPressed: () => _decide(
                        'Pay the academy',
                        b['id'] as String,
                        refund: false,
                      ),
                      child: const Text('Pay academy'),
                    ),
                  if (b['step'] == 'reported' || b['step'] == 'released')
                    TextButton(
                      onPressed: () => _decide(
                        'Refund everything',
                        b['id'] as String,
                        refund: true,
                      ),
                      child: const Text('Refund'),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
