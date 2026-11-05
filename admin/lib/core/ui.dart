import 'package:flutter/material.dart';
import 'package:og_design/og_design.dart';

import 'staff_api.dart';

/// A page of the console: a title and its content.
class StaffPage extends StatelessWidget {
  const StaffPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: OgText.h1),
              ),
            ),
            ...actions,
          ],
        ),
        const SizedBox(height: 16),
        Expanded(child: child),
      ],
    ),
  );
}

/// Loading, failed and empty states for anything read from the database.
class Loaded<T> extends StatelessWidget {
  const Loaded({
    super.key,
    required this.future,
    required this.builder,
    this.isEmpty,
    this.emptyText = 'Nothing here.',
  });

  final Future<T> future;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyText;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snap) {
      if (snap.hasError) {
        final e = snap.error;
        return Text(
          e is StaffFailure ? e.message : 'Something went wrong. Try again.',
          style: OgText.body(16, color: context.og.error),
        );
      }
      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = snap.data as T;
      if (isEmpty?.call(data) ?? false) {
        return Text(emptyText, style: OgText.lead(context.og.textMuted));
      }
      return builder(data);
    },
  );
}

/// Every staff action needs a reason, which goes in the audit log.
Future<String?> askReason(BuildContext context, String title) {
  final reason = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: reason,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final text = reason.text.trim();
            if (text.length >= 3) Navigator.of(context).pop(text);
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
}

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
