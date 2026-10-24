import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/safety_providers.dart';
import '../domain/safety_models.dart';

/// The same rules for everyone, and what we do about reports.
class CommunityRulesScreen extends StatelessWidget {
  const CommunityRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KitScaffold(
      header: const KitHeader(title: 'Community rules'),
      children: [
        const KitTitle(
          'Community rules',
          lead: 'The same rules for everyone: players, organizers, coaches, sellers and creators.',
        ),
        const KitBlock(
          title: 'Not allowed',
          child: KitCheckList(crossed: true, [
            'Harassment, bullying, threats or stalking',
            'Posting someone’s personal details without consent',
            'Sexual or intimate images, with or without consent',
            'Anything that sexualises or endangers a child',
            'Hate against a race, religion, nationality or gender',
            'Scams, fake listings, fake reviews and bought followers',
            'Content you have no right to use: photos, video, music',
            'Paid content with no “Paid partnership” label',
          ]),
        ),
        const KitBlock(
          title: 'Protecting under-18s',
          child: KitCheckList([
            'Adults cannot message under-18s privately',
            'Under-18s cannot go live or sell',
            'Child abuse material is removed at once and reported to the police',
            'Under 13: a child profile inside a parent’s account, never an own account',
          ]),
        ),
        const KitBlock(
          title: 'What we do',
          child: KitCheckList([
            'Every report is reviewed within 24 hours, urgent ones first',
            'We remove, warn, pause or ban. Both sides are told the result',
            'One review by a different person if you disagree',
            'Organizers can delete messages and remove members in their own club',
            'We follow legal orders in each country we operate in',
          ]),
        ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.flag,
              title: 'Send a legal notice',
              subtitle: 'For victims, lawyers, police and regulators. No account needed',
              onTap: () => context.push(Routes.legalNotice),
            ),
            KitNavTile(
              icon: OgIcons.globe,
              title: 'Country and regulators',
              subtitle: 'Emergency number, age rules, who to go to next',
              onTap: () => context.push(Routes.country),
            ),
            KitNavTile(
              icon: OgIcons.shield,
              title: 'My reports',
              subtitle: 'Status and result of what you reported',
              onTap: () => context.push(Routes.myReports),
            ),
          ],
        ),
      ],
    );
  }
}

(Color, Color) _stateColors(BuildContext context, ReportState s) {
  final t = context.tones;
  return switch (s) {
    ReportState.inReview => (t.warnFill, t.onWarnFill),
    ReportState.removed => (t.successFill, t.onSuccessFill),
    ReportState.noAction => (t.soft, context.og.text),
  };
}

/// Everything the player reported, newest first.
class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final reports = ref.watch(myReportsProvider).value;
    return KitScaffold(
      header: const KitHeader(title: 'My reports'),
      children: [
        const KitTitle(
          'Your reports',
          lead:
              'Only you can see these. We tell you the result of every report.',
        ),
        if (reports == null)
          const CupertinoActivityIndicator()
        else if (reports.isEmpty)
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Nothing reported yet. Use Report on a message, player, club or listing.',
                style: OgText.body(14, color: c.textMuted),
              ),
            ),
          )
        else
          KitCard(
            children: [
              for (final r in reports)
                KitNavTile(
                  icon: OgIcons.flag,
                  title: r.what,
                  subtitle: '${r.reason} · ${_when(r.at)}',
                  trailing: () {
                    final (bg, fg) = _stateColors(context, r.state);
                    return KitTag(
                      r.state.label,
                      background: bg,
                      foreground: fg,
                    );
                  }(),
                  chevron: false,
                  onTap: () =>
                      context.push(Routes.reportStatus(r.id), extra: true),
                ),
            ],
          ),
        const KitNote(
          'Urgent reports are looked at first: personal details, stalking, intimate images and child safety.',
        ),
        KitLink(
          'Read the community rules',
          onPressed: () => context.push(Routes.communityRules),
        ),
      ],
    );
  }
}

String _when(DateTime at) {
  final now = DateTime.now();
  final sameDay =
      at.year == now.year && at.month == now.month && at.day == now.day;
  return sameDay ? 'today, ${Fmt.time(at)}' : Fmt.day(at);
}

/// One report: progress, what can happen, and the result.
class ReportStatusScreen extends ConsumerStatefulWidget {
  const ReportStatusScreen({
    super.key,
    required this.id,
    this.fromList = false,
  });

  final String id;

  /// Opened from My reports, so going back returns there.
  final bool fromList;

  @override
  ConsumerState<ReportStatusScreen> createState() => _ReportStatusScreenState();
}

class _ReportStatusScreenState extends ConsumerState<ReportStatusScreen> {
  var _busy = false;

  Future<void> _askAgain() async {
    setState(() => _busy = true);
    try {
      await ref.read(safetyRepositoryProvider).askSecondLook(widget.id);
      HapticFeedback.mediumImpact();
      ref
        ..invalidate(safetyReportProvider(widget.id))
        ..invalidate(myReportsProvider);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final r = ref.watch(safetyReportProvider(widget.id)).value;
    if (r == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Report'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final decided = r.state != ReportState.inReview;
    final (bg, fg) = _stateColors(context, r.state);
    return KitScaffold(
      header: const KitHeader(title: 'Report'),
      bottom: [
        if (decided && !r.secondLook)
          KitButton.outline(
            label: 'Ask for a second look',
            loading: _busy,
            onPressed: _askAgain,
          ),
        KitButton(
          label: widget.fromList ? 'Back to my reports' : 'See all my reports',
          onPressed: () => widget.fromList
              ? context.pop()
              : context.pushReplacement(Routes.myReports),
        ),
      ],
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.soft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              SolidAvatar.forId(r.id, initials: r.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.heading,
                      style: OgText.body(15, weight: FontWeight.w700),
                    ),
                    Text(r.detail, style: OgText.body(13, color: c.textMuted)),
                    const SizedBox(height: 4),
                    Text(
                      'Reported for: ${r.reason.toLowerCase()}',
                      style: OgText.body(13, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        KitBlock(
          title: 'Progress',
          trailing: KitTag(r.state.label, background: bg, foreground: fg),
          child: Column(
            children: [
              for (final (title, line) in r.steps)
                _Step(title: title, line: line, done: true),
              if (r.decideBy != null)
                _Step(title: 'Decision', line: r.decideBy!, done: false),
            ],
          ),
        ),
        if (!decided)
          const KitBlock(
            title: 'What can happen',
            child: KitCheckList([
              'Removed, and the person is told which rule was broken',
              'Kept, if it does not break the rules. We tell you why',
              'Serious cases go to the police or the safety regulator in your country',
            ]),
          )
        else if (r.result != null)
          KitBlock(
            title: 'Result',
            child: Text(r.result!, style: OgText.body(15, height: 1.45)),
          ),
        if (r.secondLook)
          const KitNote(
            'Second look requested. A different reviewer answers within 48 hours. That answer is final.',
            tone: KitTone.success,
          )
        else if (decided)
          const KitNote(
            'Not happy with the result? You can ask once for a second look by a different reviewer.',
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.title, required this.line, required this.done});

  final String title;
  final String line;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? t.successFill : null,
              border: done
                  ? null
                  : Border.all(color: c.borderControl, width: 2),
            ),
            child: done
                ? OgIcon(OgIcons.tick, size: 14, color: t.onSuccessFill)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OgText.body(15, weight: FontWeight.w700)),
                Text(line, style: OgText.body(13, color: c.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// We removed something the player posted: why, and asking for a review.
class RemovalNoticeScreen extends ConsumerStatefulWidget {
  const RemovalNoticeScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<RemovalNoticeScreen> createState() =>
      _RemovalNoticeScreenState();
}

class _RemovalNoticeScreenState extends ConsumerState<RemovalNoticeScreen> {
  final _note = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(safetyRepositoryProvider)
          .askReview(widget.id, _note.text.trim());
      HapticFeedback.mediumImpact();
      ref.invalidate(removalNoticeProvider(widget.id));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final n = ref.watch(removalNoticeProvider(widget.id)).value;
    const title = 'Message removed';
    if (n == null) {
      return const KitScaffold(
        header: KitHeader(title: title),
        children: [CupertinoActivityIndicator()],
      );
    }
    if (n.reviewAsked) {
      return KitScaffold(
        header: const KitHeader(title: title),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Read the community rules',
            onPressed: () => context.push(Routes.communityRules),
          ),
          KitButton.outline(label: 'Done', onPressed: () => context.pop()),
        ],
        children: const [
          KitDoneBanner(title: 'Sent'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: KitTitle(
              'Review requested',
              size: 26,
              lead: 'A different reviewer answers within 48 hours. The message stays removed until then.',
            ),
          ),
        ],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: title),
      bottom: [
        KitButton.outline(
          label: 'Ask for a review',
          loading: _busy,
          onPressed: _ask,
        ),
      ],
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: t.dangerFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'We removed a message you posted. Nobody else can see it now.',
            style: OgText.body(14, height: 1.45, color: t.onDangerFill),
          ),
        ),
        Column(
          children: [
            KitKeyValue('What', n.what),
            KitKeyValue('Where', n.where),
            KitKeyValue('Rule', n.rule),
            KitKeyValue('Decided by', n.decidedBy),
          ],
        ),
        KitBlock(
          title: 'Why',
          child: Text(n.why, style: OgText.body(15, height: 1.45)),
        ),
        KitBlock(title: 'What happens now', child: KitCheckList(n.next)),
        KitTextArea(
          label: 'Why should we look again?',
          optional: true,
          controller: _note,
        ),
      ],
    );
  }
}
