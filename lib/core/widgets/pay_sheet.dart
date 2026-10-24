import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/play/data/payment_gateway.dart';
import '../../features/play/domain/activity.dart' show money;
import '../config/env.dart';
import '../providers.dart';
import '../theme/og_colors.dart';
import '../theme/og_text.dart';
import '../theme/og_tones.dart';
import 'og_icon.dart';
import 'og_kit.dart';

/// The payment sheet from the canvas: what you pay for, the lines, the
/// total, how to pay and the refund notes; then confirm with Face ID.
/// Returns the chosen method once confirmed, or null.
Future<PayMethod?> showPaySheet(
  BuildContext context, {
  required String kicker,
  required String title,
  required String subtitle,
  required List<(String, String)> lines,
  required int totalCents,
  required String payee,
  List<String> notes = const [],
}) async {
  final methods = await ProviderScope.containerOf(context)
      .read(paymentGatewayProvider)
      .methods();
  if (!context.mounted) return null;
  return showKitSheet<PayMethod>(
    context,
    builder: (_) => _PaySheet(
      kicker: kicker,
      title: title,
      subtitle: subtitle,
      lines: lines,
      totalCents: totalCents,
      payee: payee,
      notes: notes,
      methods: methods,
    ),
  );
}

class _PaySheet extends ConsumerStatefulWidget {
  const _PaySheet({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.lines,
    required this.totalCents,
    required this.payee,
    required this.notes,
    required this.methods,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final List<(String, String)> lines;
  final int totalCents;
  final String payee;
  final List<String> notes;
  final List<PayMethod> methods;

  @override
  ConsumerState<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<_PaySheet> {
  late PayMethod? _method = widget.methods.firstOrNull;
  bool _confirming = false;

  String get _total => 'S\$${money(widget.totalCents)}';

  Future<void> _confirm() async {
    // Demo mode skips the device check, so a simulator never asks for its
    // passcode.
    final ok =
        !Env.hasSupabase ||
        await ref
            .read(biometricVaultProvider)
            .authenticate('Pay $_total to ${widget.payee}');
    if (ok && mounted) Navigator.of(context).pop(_method);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    if (_confirming) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: kitSpaced([
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: c.inverseCard,
                  borderRadius: BorderRadius.circular(28),
                ),
                alignment: Alignment.center,
                child: OgIcon(OgIcons.faceId, size: 44, color: c.accent),
              ),
            ),
            Text(
              'Confirm it’s you',
              textAlign: TextAlign.center,
              style: OgText.heading(30),
            ),
            Text(
              'Pay $_total to ${widget.payee}.\nUse Face ID or your passcode.',
              textAlign: TextAlign.center,
              style: OgText.body(15, height: 1.45, color: t.onTag),
            ),
            KitButton(
              label: 'Confirm',
              style: KitButtonStyle.dark,
              onPressed: _confirm,
            ),
            KitButton.outline(
              label: 'Back',
              onPressed: () => setState(() => _confirming = false),
            ),
          ], 14),
        ),
      );
    }
    final rows = [...widget.lines];
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: kitSpaced([
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.kicker.toUpperCase(),
                      style: OgText.body(
                        12,
                        weight: FontWeight.w700,
                        color: c.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(widget.title, style: OgText.heading(28, height: 1)),
                    const SizedBox(height: 5),
                    Text(
                      widget.subtitle,
                      style: OgText.body(14, height: 1.35, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              KitIconButton(
                icon: OgIcons.close,
                label: 'Close',
                size: 20,
                background: t.soft,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            decoration: BoxDecoration(
              color: t.soft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                for (final (label, value) in rows)
                  Container(
                    constraints: const BoxConstraints(minHeight: 38),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: OgText.body(15, color: t.onTag),
                          ),
                        ),
                        Text(
                          value,
                          style: OgText.body(15, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'Total',
                        style: OgText.body(15, weight: FontWeight.w700),
                      ),
                    ),
                    Text(_total, style: OgText.heading(36, height: 1)),
                  ],
                ),
              ],
            ),
          ),
          if (widget.methods.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pay with',
                  style: OgText.body(14, weight: FontWeight.w700),
                ),
                for (final m in widget.methods)
                  KitChoiceRow(
                    title: m.title,
                    subtitle: m.detail,
                    selected: _method?.id == m.id,
                    onTap: () => setState(() => _method = m),
                  ),
              ],
            ),
          for (final n in widget.notes)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 7, right: 8),
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    n,
                    style: OgText.body(13, height: 1.4, color: t.onTag),
                  ),
                ),
              ],
            ),
          KitButton(
            label: 'Pay $_total',
            onPressed: _method == null
                ? null
                : () => setState(() => _confirming = true),
          ),
        ], 14),
      ),
    );
  }
}
