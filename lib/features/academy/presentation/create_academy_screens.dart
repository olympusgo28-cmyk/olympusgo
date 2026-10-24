import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../../onboarding/domain/sport.dart';
import '../application/academy_providers.dart';
import '../domain/academy_models.dart';

/// "Create academy" with "Step n of 5 · name" and a progress bar.
class _Header extends StatelessWidget {
  const _Header(this.step, this.name);

  final int step;
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          KitHeader(
            title: 'Create academy',
            subtitle: 'Step $step of 5 · $name',
            lead: step == 1 ? KitLead.close : KitLead.back,
            titleSize: 19,
            border: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Row(
              children: [
                for (var i = 1; i <= 5; i++) ...[
                  if (i > 1) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: i <= step ? c.primary : c.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _label(String text) =>
    Text(text, style: OgText.body(15, weight: FontWeight.w700));

// ─── 1 Details ─────────────────────────────────────────────────────────────

class NewAcademyScreen extends ConsumerStatefulWidget {
  const NewAcademyScreen({super.key});

  @override
  ConsumerState<NewAcademyScreen> createState() => _NewAcademyScreenState();
}

class _NewAcademyScreenState extends ConsumerState<NewAcademyScreen> {
  final _venue = TextEditingController();

  @override
  void dispose() {
    _venue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final d = ref.watch(academyDraftControllerProvider);
    final draft = ref.read(academyDraftControllerProvider.notifier);
    final gaps = [
      if (d.name.trim().isEmpty) 'a name',
      if (d.venues.isEmpty) 'where you teach',
    ];
    return KitScaffold(
      header: const _Header(1, 'Details'),
      bottom: [
        KitButton(
          label: 'Next',
          onPressed: gaps.isEmpty
              ? () => context.push(Routes.newAcademyLevels)
              : null,
        ),
        if (gaps.isNotEmpty)
          Text(
            'Add ${gaps.join(' and ')} to continue.',
            textAlign: TextAlign.center,
            style: OgText.body(13, color: c.textMuted),
          ),
      ],
      children: [
        KitInput(
          label: 'Academy name',
          hint: 'e.g. Smash Academy',
          initialValue: d.name,
          maxLength: 50,
          onChanged: (v) => draft.edit((x) => x.copyWith(name: v)),
        ),
        KitTextArea(
          label: 'Description',
          optional: true,
          hint: 'Who you teach, how classes run and what students learn.',
          initialValue: d.blurb,
          onChanged: (v) => draft.edit((x) => x.copyWith(blurb: v)),
        ),
        _label('Who you teach'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (key, label) in const [
              ('Kids', 'Kids 6 – 12'),
              ('Teens', 'Teens 13 – 17'),
              ('Adults', 'Adults'),
              ('Seniors', 'Seniors 60+'),
            ])
              KitChip(
                label: label,
                selected: d.audience.contains(key),
                onTap: () => draft.edit(
                  (x) => x.copyWith(
                    audience: x.audience.contains(key)
                        ? ({...x.audience}..remove(key))
                        : {...x.audience, key},
                  ),
                ),
              ),
          ],
        ),
        if (d.audience.contains('Kids') || d.audience.contains('Teens'))
          const KitNote(
            'Classes with under-18s turn on safeguarding: parents manage the '
            'account and give consent before any filming. Every coach needs '
            'an NROC licence.',
            tone: KitTone.info,
          ),
        _label('Where you teach'),
        for (final v in d.venues)
          Row(
            children: [
              Expanded(child: Text(v, style: OgText.body(15))),
              KitLink(
                'Remove',
                onPressed: () => draft.edit(
                  (x) => x.copyWith(venues: [...x.venues]..remove(v)),
                ),
              ),
            ],
          ),
        KitInput(
          label: 'Add a venue',
          hint: 'Venue name, area',
          controller: _venue,
        ),
        KitButton.outline(
          label: '+ Add venue',
          onPressed: () {
            final v = _venue.text.trim();
            if (v.isEmpty) return;
            draft.edit((x) => x.copyWith(venues: [...x.venues, v]));
            _venue.clear();
          },
        ),
      ],
    );
  }
}

// ─── 2 Sport and levels ────────────────────────────────────────────────────

class NewAcademyLevelsScreen extends ConsumerWidget {
  const NewAcademyLevelsScreen({super.key});

  static const _levels = [
    ('L1', 'First Rallies', 'Grip, footwork, clears'),
    ('L2', 'Rally Builders', 'Net play, smash, serves'),
    ('L3', 'Match Play', 'Doubles, tactics, scoring'),
    ('L4', 'Squad', 'Competition prep'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final d = ref.watch(academyDraftControllerProvider);
    final draft = ref.read(academyDraftControllerProvider.notifier);
    return KitScaffold(
      header: const _Header(2, 'Sport and levels'),
      bottom: [
        KitButton(
          label: 'Next',
          onPressed: () => context.push(Routes.newAcademyPolicies),
        ),
      ],
      children: [
        _label('Sport'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in Sport.play)
              KitChip(
                label: s.label,
                selected: d.sport == s,
                onTap: () => draft.edit((x) => x.copyWith(sport: s)),
              ),
          ],
        ),
        Text(
          'One sport per academy. Add another sport later as a second '
          'programme.',
          style: OgText.body(13, color: c.textMuted),
        ),
        _label('Levels and curriculum'),
        Text(
          'Every coach teaches from the same plan. Start from a template and '
          'edit it any time in Curriculum.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
        KitSegments(
          labels: ['${d.sport.label} template', 'Start blank'],
          selected: d.template ? 0 : 1,
          onSelect: (i) => draft.edit((x) => x.copyWith(template: i == 0)),
        ),
        if (d.template)
          for (final (code, name, meta) in _levels)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  KitTag(code, background: t.gold, foreground: t.onGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: OgText.body(15, weight: FontWeight.w700),
                        ),
                        Text(meta, style: OgText.body(13, color: c.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            )
        else
          const KitNote(
            'You add levels and lessons in Curriculum after you create the academy.',
          ),
        const KitNote(
          'Academy levels are separate from player ratings. Ratings come only '
          'from ranked games.',
        ),
      ],
    );
  }
}

// ─── 3 Billing and make-ups ────────────────────────────────────────────────

class NewAcademyPoliciesScreen extends ConsumerWidget {
  const NewAcademyPoliciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final d = ref.watch(academyDraftControllerProvider);
    final draft = ref.read(academyDraftControllerProvider.notifier);
    return KitScaffold(
      header: const _Header(3, 'Classes and make-ups'),
      bottom: [
        KitButton(
          label: 'Next',
          onPressed: () => context.push(Routes.newAcademyVerify),
        ),
      ],
      children: [
        _label('How parents pay'),
        for (final (b, hint) in const [
          (Billing.term, 'One payment for the whole term'),
          (Billing.month, 'Charged on the 1st of each month'),
          (Billing.perClass, 'Pay for each class before it starts'),
        ])
          KitChoiceRow(
            title: b.label,
            subtitle: hint,
            selected: d.billing == b,
            onTap: () => draft.edit((x) => x.copyWith(billing: b)),
          ),
        Text(
          'Platform fee: 10%, minimum S\$2 per payment. A S\$280 term costs '
          'parents S\$308. You receive S\$280.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
        _label('Make-up classes'),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Make-ups a month', style: OgText.body(15)),
                  Text(
                    'For classes missed with notice',
                    style: OgText.body(13, color: c.textMuted),
                  ),
                ],
              ),
            ),
            KitIconButton(
              icon: '<path d="M5 12h14"/>',
              label: 'Fewer',
              border: true,
              onPressed: d.makeups > 0
                  ? () => draft.edit((x) => x.copyWith(makeups: x.makeups - 1))
                  : null,
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${d.makeups}',
                textAlign: TextAlign.center,
                style: OgText.heading(22),
              ),
            ),
            KitIconButton(
              icon: '<path d="M12 5v14M5 12h14"/>',
              label: 'More',
              border: true,
              onPressed: d.makeups < 8
                  ? () => draft.edit((x) => x.copyWith(makeups: x.makeups + 1))
                  : null,
            ),
          ],
        ),
        const KitNote(
          'Automatic: a parent who says their child can’t come gets a credit. '
          'Credits expire 30 days after the missed class.',
        ),
      ],
    );
  }
}

// ─── 4 Verification ────────────────────────────────────────────────────────

class NewAcademyVerifyScreen extends ConsumerWidget {
  const NewAcademyVerifyScreen({super.key});

  static const _docs = [
    ('biz', 'Business licence', 'ACRA business profile or licence'),
    ('coach', 'Your NROC licence', 'National Registry of Coaches'),
    ('payout', 'Payout account', 'Where fees are paid to'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final d = ref.watch(academyDraftControllerProvider);
    final draft = ref.read(academyDraftControllerProvider.notifier);
    return KitScaffold(
      header: const _Header(4, 'Verification'),
      bottom: [
        KitButton(
          label: 'Next',
          onPressed: () => context.push(Routes.newAcademyCoaches),
        ),
      ],
      children: [
        KitTitle(
          'Get verified',
          size: 28,
          lead:
              'The academy needs a business licence. Everyone who coaches '
              'needs an NROC licence. We review within 1 – 3 working days. You '
              'can set up classes while you wait.',
        ),
        for (var i = 0; i < _docs.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: t.soft,
                  child: Text(
                    '${i + 1}',
                    style: OgText.body(13, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _docs[i].$2,
                        style: OgText.body(15, weight: FontWeight.w700),
                      ),
                      Text(
                        _docs[i].$3,
                        style: OgText.body(13, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                if (d.documents.contains(_docs[i].$1))
                  KitTag(
                    'In review',
                    background: t.warnFill,
                    foreground: t.onWarnFill,
                  )
                else
                  KitLink(
                    'Add',
                    // shortcut: marks the step done; document upload to
                    // storage comes with the academy backend.
                    onPressed: () => draft.edit(
                      (x) =>
                          x.copyWith(documents: {...x.documents, _docs[i].$1}),
                    ),
                  ),
              ],
            ),
          ),
        const KitNote(
          'Documents are seen only by our review team. Parents see the '
          'Verified badge, never the documents. Changing the payout account '
          'needs Face ID.',
        ),
      ],
    );
  }
}

// ─── 5 Coaches ─────────────────────────────────────────────────────────────

class NewAcademyCoachesScreen extends ConsumerStatefulWidget {
  const NewAcademyCoachesScreen({super.key});

  @override
  ConsumerState<NewAcademyCoachesScreen> createState() =>
      _NewAcademyCoachesScreenState();
}

class _NewAcademyCoachesScreenState
    extends ConsumerState<NewAcademyCoachesScreen> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final id = await ref
          .read(academyDraftControllerProvider.notifier)
          .create();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      showOgToast(context, 'Academy created');
      context.go(Routes.academyToday(id));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final d = ref.watch(academyDraftControllerProvider);
    final draft = ref.read(academyDraftControllerProvider.notifier);
    final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return KitScaffold(
      header: const _Header(5, 'Coaches'),
      bottom: [
        KitButton(label: 'Create academy', loading: _busy, onPressed: _create),
      ],
      children: [
        KitTitle(
          'Invite your coaches',
          size: 28,
          lead:
              'Each coach gets the shared curriculum, their classes and their '
              'students’ progress. A coach can be given classes only after '
              'their NROC licence is verified.',
        ),
        for (final e in d.coachEmails)
          Row(
            children: [
              Expanded(child: Text(e, style: OgText.body(15))),
              Text(
                'Coach · invite on create',
                style: OgText.body(13, color: c.textMuted),
              ),
            ],
          ),
        KitInput(
          label: 'Coach email',
          hint: 'name@example.com',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        KitButton.outline(
          label: '+ Add coach',
          onPressed: () {
            final e = _email.text.trim();
            if (!validEmail.hasMatch(e)) {
              showOgToast(context, 'Enter a valid email', error: true);
              return;
            }
            draft.edit((x) => x.copyWith(coachEmails: [...x.coachEmails, e]));
            _email.clear();
          },
        ),
        KitCard(
          children: const [
            _Role(
              'Head coach',
              'Edits the curriculum, changes any class, sees all students',
            ),
            _Role(
              'Coach',
              'Runs their classes, marks attendance and skills, messages their parents',
            ),
            _Role(
              'Admin',
              'Billing, enrolment and schedules, no student notes',
            ),
          ],
        ),
      ],
    );
  }
}

class _Role extends StatelessWidget {
  const _Role(this.title, this.body);

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: OgText.body(15, weight: FontWeight.w700)),
        Text(body, style: OgText.body(13, color: context.og.textMuted)),
      ],
    ),
  );
}
