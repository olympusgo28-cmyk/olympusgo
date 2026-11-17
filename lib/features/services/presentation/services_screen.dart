import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/og_type.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/services_providers.dart';
import '../data/services_repository.dart';

/// Partner physios. Booking happens on the partner's own site, so nothing
/// about why someone is going ever reaches OlympusGO.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partners = ref.watch(servicePartnersProvider);
    return KitScaffold(
      header: const KitHeader(title: 'Services'),
      children: [
        const KitTitle(
          'Partner physios',
          size: 28,
          lead:
              'You book on the partner’s own site. OlympusGO doesn’t see what '
              'you book or why.',
        ),
        ...partners.when(
          loading: () => const [CupertinoActivityIndicator()],
          error: (_, _) => [
            const KitNote(
              'Can’t load partners right now. Check your connection.',
              tone: KitTone.warn,
            ),
            KitButton(
              label: 'Try again',
              onPressed: () => ref.invalidate(servicePartnersProvider),
            ),
          ],
          data: (list) => list.isEmpty
              ? [Text('None are open yet.', style: context.type.secondary)]
              : [for (final p in list) _PartnerCard(p)],
        ),
      ],
    );
  }
}

class _PartnerCard extends ConsumerStatefulWidget {
  const _PartnerCard(this.partner);
  final ServicePartner partner;

  @override
  ConsumerState<_PartnerCard> createState() => _PartnerCardState();
}

class _PartnerCardState extends ConsumerState<_PartnerCard> {
  bool _busy = false;

  Future<void> _request() async {
    final p = widget.partner;
    final go = await showCupertinoDialog<bool>(
      context: context,
      builder: (d) => CupertinoAlertDialog(
        title: const Text('Leave OlympusGO?'),
        content: Text('This opens ${p.name}’s own booking page.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Not now'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final link = await ref.read(servicesRepositoryProvider).refer(p.id);
      final uri = Uri.parse(link);
      if (uri.scheme != 'https' ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          showOgToast(context, 'We couldn’t open that link.', error: true);
        }
      }
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.partner;
    return KitCard(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(p.name, style: context.type.body),
            if (p.area.isNotEmpty) Text(p.area, style: context.type.caption),
            if (p.blurb.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(p.blurb, style: context.type.body.copyWith(height: 1.4)),
            ],
            const SizedBox(height: 12),
            KitButton(
              label: 'Request a booking',
              loading: _busy,
              onPressed: _request,
            ),
          ],
        ),
      ],
    );
  }
}
