import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_design/og_design.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

/// Every staff action, newest first. Super only.
class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => StaffPage(
    title: 'Audit log',
    child: Loaded<List<dynamic>>(
      future: ref
          .read(staffApiProvider)
          .read('staff_audit_list')
          .then((r) => r! as List<dynamic>),
      isEmpty: (rows) => rows.isEmpty,
      emptyText: 'No staff actions yet.',
      builder: (rows) => ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = rows[i] as Map<String, dynamic>;
          return ListTile(
            title: Text('${r['action']} · ${r['target_kind']}'),
            subtitle: Text(r['reason'] as String),
            trailing: Text(
              (r['at'] as String).substring(0, 16).replaceFirst('T', ' '),
              style: OgText.body(13, color: context.og.textMuted),
            ),
          );
        },
      ),
    ),
  );
}
