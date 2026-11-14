import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/tips_providers.dart';

class TipScreen extends ConsumerStatefulWidget {
  const TipScreen({super.key, required this.coachId});
  final String coachId;

  @override
  ConsumerState<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends ConsumerState<TipScreen> {
  final _amount = TextEditingController();

  Future<void> _send() async {
    final amount = double.parse(_amount.text);
    try {
      await ref
          .read(tipControllerProvider.notifier)
          .send(toCoach: widget.coachId, amount: amount);
      final tipId = ref.read(tipControllerProvider).value;
      context.push('/tips/receipt', extra: {'tipId': tipId, 'amount': amount});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tip your coach')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amount,
              decoration: const InputDecoration(hintText: 'Amount'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _send, child: const Text('Submit')),
          ],
        ),
      ),
    );
  }
}
