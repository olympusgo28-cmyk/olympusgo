import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/domain/country.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/share.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../../settings/application/settings_providers.dart';
import '../domain/safety_models.dart';

/// Opens one of the full documents on the website.
Future<void> openLegalPage(BuildContext context, String page) async {
  final ok = await launchUrl(
    Uri.parse('https://${Links.host}/$page'),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    showOgToast(context, "Couldn't open the page.", error: true);
  }
}

/// What the app does in each country.
class CountryRules {
  const CountryRules(
    this.currency,
    this.emergency,
    this.regulator,
    this.sellerDetails,
  );
  final String currency;
  final String emergency;
  final String regulator;
  final String sellerDetails;

  static CountryRules of(Country c) => switch (c) {
    Country.singapore => const CountryRules(
      'S\$ Singapore dollar',
      '999 police · 995 ambulance',
      'Online Safety Commission',
      'Business name and contact',
    ),
    Country.malaysia => const CountryRules(
      'RM Malaysian ringgit',
      '999',
      'Malaysian Communications and Multimedia Commission',
      'Name, registration number, email and phone',
    ),
    Country.indonesia => const CountryRules(
      'Rp Indonesian rupiah',
      '112',
      'Ministry of Communication and Digital Affairs',
      'Business name and contact',
    ),
    Country.thailand => const CountryRules(
      '฿ Thai baht',
      '191 police · 1669 ambulance',
      'Ministry of Digital Economy and Society',
      'Business name and contact',
    ),
  };
}

/// The short version of the terms and privacy policy.
class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KitScaffold(
      header: const KitHeader(title: 'Terms and privacy'),
      children: [
        const KitTitle(
          'The short version',
          lead: 'The full terms and privacy policy are linked at the bottom.',
        ),
        const KitBlock(
          title: 'Your account',
          child: KitCheckList([
            'One account per person, in your real name',
            'Own account from age 13. From 13 to 17 a parent or guardian approves it and can see sessions and payments',
            'Under 13: a child profile inside a parent’s account',
            'You can delete your account any time in Account Centre',
          ]),
        ),
        KitBlock(
          title: 'Money',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const KitCheckList([
                'Platform fee is 10%, minimum S\$2, shown before you pay',
                'Refund rules are shown on each Meet, ticket and entry before you pay. If the organizer cancels, you get everything back, fees included',
                'Organizers, clubs, academies and sellers are paid once attendance is marked, or 24 hours after the end. Payouts go to banks weekly',
              ]),
              Align(
                alignment: Alignment.centerLeft,
                child: KitLink(
                  'Refund rules',
                  onPressed: () => context.push(Routes.refundRules),
                ),
              ),
            ],
          ),
        ),
        const KitBlock(
          title: 'Your data',
          child: KitCheckList([
            'Location is used for nearby results and check-in, never shown to others',
            'You choose who sees your sessions: everyone, your Circle, or nobody',
            'Filming needs your consent, and a parent’s consent for under-18s',
          ]),
        ),
        KitBlock(
          title: 'Safety',
          child: KitCard(
            children: [
              KitNavTile(
                icon: OgIcons.shield,
                title: 'Community rules',
                subtitle: 'What is not allowed and what we do about it',
                onTap: () => context.push(Routes.communityRules),
              ),
              KitNavTile(
                icon: OgIcons.lock,
                title: 'Under-18 protection',
                subtitle: 'Settings that stay on until 18',
                onTap: () => context.push(Routes.under18),
              ),
              KitNavTile(
                icon: OgIcons.globe,
                title: 'Country',
                subtitle: 'Local rules, emergency number, regulators',
                onTap: () => context.push(Routes.country),
              ),
            ],
          ),
        ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.document,
              title: 'Full terms of use',
              onTap: () => openLegalPage(context, 'terms'),
            ),
            KitNavTile(
              icon: OgIcons.document,
              title: 'Full privacy policy',
              onTap: () => openLegalPage(context, 'privacy'),
            ),
          ],
        ),
      ],
    );
  }
}

/// The same refund rules for Meets, events, tournaments, courts and shops.
class RefundRulesScreen extends StatelessWidget {
  const RefundRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KitScaffold(
      header: const KitHeader(title: 'Refund rules'),
      children: [
        const KitTitle(
          'Refund rules',
          lead: 'The same for Meets, events, tournaments and court bookings. Each one also shows its cut-off before you pay.',
        ),
        const KitBlock(
          title: 'If the organizer cancels',
          child: KitCheckList([
            'You get back everything you paid, platform fee included',
            'You choose: your Wallet, instantly, or your card or PayNow, in 3 to 5 working days',
            'The same if the venue closes or the session can’t go ahead',
          ]),
        ),
        KitBlock(
          title: 'If you cancel in time',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const KitCheckList([
                'To your Wallet: all of it, platform fee included, instantly',
                'To your card or PayNow: the price without the platform fee, in 3 to 5 working days',
              ]),
              const SizedBox(height: 8),
              for (final (k, v) in const [
                ('Meets', 'Before it starts'),
                ('Events', '24 hours before'),
                ('Tournaments', 'When registration closes'),
                ('Courts', '24 hours before'),
              ])
                KitKeyValue(k, v),
            ],
          ),
        ),
        const KitBlock(
          title: 'If you cancel late or don’t come',
          child: KitCheckList(crossed: true, [
            'No refund after the cut-off',
            'No refund if you don’t come',
          ]),
        ),
        const KitNote(
          'The organizer may still agree to one. Ask them in chat.',
        ),
        const KitBlock(
          title: 'Shop orders',
          child: KitCheckList([
            'Cancel free until the shop ships, all of it back',
            'A fault: return it within 7 days',
            'Not delivered in 14 days: all of it back',
          ]),
        ),
        const KitBlock(
          title: 'When organizers are paid',
          child: Text(
            'Olympus holds your payment until the organizer marks attendance, or until 24 hours after the end if they don’t. If something goes wrong, report it before then and we hold the money while we look.',
          ),
        ),
        const KitBlock(
          title: 'Your wallet',
          child: KitCheckList([
            'Holds refunds and rewards',
            'Spend it on Olympus, or withdraw it to your bank for free',
            'You can’t add money to it yourself yet',
          ]),
        ),
        const KitNote(
          'These rules are part of the Terms. Your rights under the law in your country come first.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: KitLink(
            'Terms and privacy',
            onPressed: () => context.push(Routes.legal),
          ),
        ),
      ],
    );
  }
}

/// Protections that stay on for every player under 18.
class Under18ProtectionScreen extends StatelessWidget {
  const Under18ProtectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    Widget row(String title, String sub, {required bool locked}) => Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OgText.body(15, weight: FontWeight.w700)),
                Text(sub, style: OgText.body(13, color: c.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          locked
              ? KitTag(
                  'On',
                  background: t.successFill,
                  foreground: t.onSuccessFill,
                )
              : KitTag('Parent', background: t.soft, foreground: c.text),
        ],
      ),
    );
    return KitScaffold(
      header: const KitHeader(title: 'Under-18 protection'),
      children: [
        const KitTitle(
          'Under-18 protection',
          lead: 'On for every player under 18. These cannot be switched off.',
        ),
        Column(
          children: [
            row(
              'Private profile',
              'Only your Circle, club and team see your sessions',
              locked: true,
            ),
            row(
              'No private messages from adults',
              'Coaches write to a parent, or in the team chat',
              locked: true,
            ),
            row(
              'Videos from who you follow',
              'No endless “For you” feed and no autoplay',
              locked: true,
            ),
            row(
              'No going live, no selling',
              'Posting a clip to a challenge is allowed',
              locked: true,
            ),
            row('Location never shown', 'Used for check-in only', locked: true),
            row(
              'Initials on public leaderboards',
              'Full name shows only inside your club and team',
              locked: true,
            ),
          ],
        ),
        KitBlock(
          title: 'A parent can change',
          child: Column(
            children: [
              row(
                'Club and team chat',
                'Read and write in group chats',
                locked: false,
              ),
              row(
                'Quiet hours',
                'No notifications from 10 PM to 7 AM',
                locked: false,
              ),
              row(
                'Appear in player search',
                'Other players can find the profile by name',
                locked: false,
              ),
            ],
          ),
        ),
        const KitNote(
          'A parent or guardian sees sessions, payments and who the player follows. At 18 these become normal settings and the player chooses.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: KitLink(
            'Read the community rules',
            onPressed: () => context.push(Routes.communityRules),
          ),
        ),
      ],
    );
  }
}

/// Picks the country for currency, emergency number and local rules.
class CountryScreen extends ConsumerStatefulWidget {
  const CountryScreen({super.key});

  @override
  ConsumerState<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends ConsumerState<CountryScreen> {
  Country? _picked;
  var _busy = false;

  Future<void> _save() async {
    final picked = _picked;
    if (picked == null) {
      context.pop();
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(settingsRepositoryProvider).saveCountry(picked);
      HapticFeedback.mediumImpact();
      ref.invalidate(privateInfoProvider);
      if (mounted) context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(privateInfoProvider).value?.country;
    final country = _picked ?? saved ?? Country.singapore;
    final rules = CountryRules.of(country);
    return KitScaffold(
      header: const KitHeader(title: 'Country'),
      bottom: [KitButton(label: 'Save', loading: _busy, onPressed: _save)],
      children: [
        const KitTitle(
          'Country',
          lead: 'Sets your currency, emergency number and the local rules the app follows.',
        ),
        Column(
          children: [
            for (final c in Country.values)
              KitChoiceRow(
                title: c.name,
                subtitle:
                    '${CountryRules.of(c).currency.split(' ').first} · emergency ${CountryRules.of(c).emergency.split(' ').first}',
                selected: c == country,
                onTap: () => setState(() => _picked = c),
              ),
          ],
        ),
        KitBlock(
          title: 'In ${country.name}',
          child: Column(
            children: [
              KitKeyValue('Currency', rules.currency),
              KitKeyValue('Emergency number', rules.emergency),
              const KitKeyValue(
                'Own account from',
                'Age 13, parent approves until 18',
              ),
              const KitKeyValue('Reports answered within', '24 hours'),
              KitKeyValue('If we do not act', rules.regulator),
              KitKeyValue('Seller details shown', rules.sellerDetails),
            ],
          ),
        ),
        const KitNote(
          'Prices, refunds and payouts use the currency of the country where the Meet, class or shop is.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: KitLink(
            'Read the community rules',
            onPressed: () => context.push(Routes.communityRules),
          ),
        ),
      ],
    );
  }
}

/// A legal notice from someone harmed by content. No account needed.
class LegalNoticeScreen extends ConsumerStatefulWidget {
  const LegalNoticeScreen({super.key});

  @override
  ConsumerState<LegalNoticeScreen> createState() => _LegalNoticeScreenState();
}

class _LegalNoticeScreenState extends ConsumerState<LegalNoticeScreen> {
  static const _roles = [
    'The person affected',
    'Parent or guardian',
    'Lawyer or representative',
    'Police or regulator',
  ];
  static const _reasons = [
    ('Harassment or bullying', 'Insults, threats, unwanted contact', false),
    (
      'Personal details shared',
      'Address, phone, school or workplace posted without consent',
      true,
    ),
    ('Stalking', 'Following or tracking someone', true),
    ('Sexual or intimate image', 'Shared without consent, or unwanted', true),
    ('Child safety', 'Anything that puts an under-18 at risk', true),
  ];

  var _role = _roles.first;
  var _country = Country.singapore;
  final _picked = <String>{};
  var _true = false;
  var _busy = false;
  String? _reference;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _where = TextEditingController();
  final _details = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _where, _details]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _missing() {
    if (_name.text.trim().length < 2) return 'Add your name.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) {
      return 'Add an email we can reply to.';
    }
    if (_where.text.trim().length < 2) return 'Say where it is.';
    if (_picked.isEmpty) return 'Pick what it is.';
    if (_details.text.trim().length < 10) return 'Tell us what happened.';
    return null;
  }

  Future<void> _send() async {
    if (_missing() case final why?) {
      showOgToast(context, why, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final ref0 = await ref
          .read(safetyRepositoryProvider)
          .sendLegalNotice(
            LegalNotice(
              role: _role,
              name: _name.text.trim(),
              email: _email.text.trim(),
              country: _country,
              location: _where.text.trim(),
              reasons: _picked.toList(),
              details: _details.text.trim(),
            ),
          );
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _reference = ref0);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    if (_reference case final refNo?) {
      return KitScaffold(
        header: const KitHeader(title: 'Legal notice'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [KitButton(label: 'Done', onPressed: () => context.pop())],
        children: [
          const KitDoneBanner(title: 'Received'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: kitSpaced([
                KitTitle(
                  'Notice received',
                  size: 26,
                  lead:
                      'Reference $refNo. We answer within 24 hours. Urgent notices are handled first, and the content is hidden while we check.',
                ),
                Column(
                  children: [
                    for (final ct in Country.values)
                      KitKeyValue(ct.name, CountryRules.of(ct).regulator),
                  ],
                ),
                const KitNote(
                  'If we do not act in time, you can take your notice to the body listed for your country.',
                ),
              ], 18),
            ),
          ),
        ],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'Legal notice'),
      bottom: [
        KitButton(
          label: _true ? 'Send notice' : 'Confirm it is true',
          loading: _busy,
          onPressed: _true ? _send : null,
        ),
      ],
      children: [
        const KitTitle(
          'Send a legal notice',
          lead: 'For a person harmed by something on Olympus, or someone acting for them. You do not need an account.',
        ),
        Text('I am', style: OgText.body(15, weight: FontWeight.w700)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in _roles)
              KitChip(
                label: r,
                selected: _role == r,
                onTap: () => setState(() => _role = r),
              ),
          ],
        ),
        KitInput(label: 'Your name', controller: _name, hint: 'Full name'),
        KitInput(
          label: 'Email for our reply',
          controller: _email,
          hint: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        Text('Country', style: OgText.body(15, weight: FontWeight.w700)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final ct in Country.values)
              KitChip(
                label: ct.name,
                selected: _country == ct,
                onTap: () => setState(() => _country = ct),
              ),
          ],
        ),
        KitInput(
          label: 'Where is it?',
          controller: _where,
          hint: 'Link, or the club, chat, video or shop name',
        ),
        Text('What is it?', style: OgText.heading(24)),
        Column(
          children: [
            for (final (name, sub, urgent) in _reasons)
              KitChoiceRow(
                title: name,
                subtitle: sub,
                tag: urgent ? 'Urgent' : null,
                multi: true,
                selected: _picked.contains(name),
                onTap: () => setState(
                  () => _picked.contains(name)
                      ? _picked.remove(name)
                      : _picked.add(name),
                ),
              ),
          ],
        ),
        KitTextArea(label: 'What happened', controller: _details),
        KitConfirmBox(
          label: 'What I have written is true.',
          checked: _true,
          onChanged: (v) => setState(() => _true = v),
        ),
        Text(
          'We use these details only to handle this notice.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}
