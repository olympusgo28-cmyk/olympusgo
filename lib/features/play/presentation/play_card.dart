import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_home.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../social/application/social_providers.dart';
import '../../social/domain/social_models.dart';
import '../domain/activity.dart';

/// Heart-in-hand mark used for events.
const _eventIcon =
    '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>';

/// "1,284".
String thousands(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// The one card for Meets, tournaments and events (the "Play cards"
/// artboard). The button follows the player's state.
class PlayCard extends ConsumerWidget {
  const PlayCard({super.key, required this.activity, this.onHome = false});

  final Activity activity;

  /// On Home the card is white with a light border (near-black with a dark
  /// one in the dark theme).
  final bool onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final a = activity;
    void open() => context.push(Routes.activity(a.id));

    final (tile, tileInk, icon) = switch (a.kind) {
      ActivityKind.meet => (t.successFill, t.onSuccessFill, OgIcons.racquet),
      ActivityKind.tournament => (t.warnFill, t.warnInk, OgIcons.trophyTeam),
      ActivityKind.event => (t.dangerFill, t.onDangerFill, _eventIcon),
    };

    final (chip, chipBg, chipFg) = switch (a.kind) {
      ActivityKind.meet when a.ranked => ('Ranked', t.gold, t.onGold),
      ActivityKind.meet => ('Casual', t.soft, c.text),
      ActivityKind.tournament when a.tier != null => (
        a.tier!,
        c.inverseCard,
        c.onInverseCard,
      ),
      ActivityKind.tournament => (
        a.ranked ? 'Ranked' : 'Open',
        a.ranked ? t.gold : t.soft,
        a.ranked ? t.onGold : c.text,
      ),
      ActivityKind.event when a.live => ('Live', t.badge, Colors.white),
      ActivityKind.event => ('Offline', const Color(0xFF2F3A5F), Colors.white),
    };

    final dateLine = switch (a.kind) {
      ActivityKind.tournament when a.multiDay => Fmt.dayRange(
        a.startsAt,
        a.endsAt,
      ),
      _ when a.endsAt.day != a.startsAt.day => Fmt.dayRange(
        a.startsAt,
        a.endsAt,
      ),
      _ => Fmt.dayTimeRange(a.startsAt, a.endsAt),
    };
    final dateSub =
        a.subtitle ??
        a.recurrence ??
        (a.kind == ActivityKind.tournament && a.registrationClosesAt != null
            ? 'Registration closes ${Fmt.day(a.registrationClosesAt!)}'
            : null);
    final price = a.isFree
        ? (a.kind == ActivityKind.event ? 'Free entry' : 'Free')
        : 'S\$${money(a.feeCents)} / ${a.kind == ActivityKind.tournament ? 'entry' : 'person'}';
    final people = switch (a.kind) {
      ActivityKind.meet =>
        '${a.bands} • ${a.spotsTaken}/${a.capacity} players • $price',
      ActivityKind.tournament =>
        '${a.bands} • ${a.spotsTaken}/${a.capacity} going • $price',
      ActivityKind.event =>
        '${a.audience ?? 'All ages'} • ${thousands(a.spotsTaken)} going • $price',
    };

    // An activity nobody gave a cover is stored near-black. On Home its banner
    // takes the kind's own colour instead (the same one as its icon tile).
    final plainCover = onHome && a.coverColor == _defaultCover;
    final bannerColor = plainCover ? tile : Color(a.coverColor);
    final bannerInk = plainCover ? tileInk : Color(a.coverInk);
    final hasBanner = a.coverTitle != null || a.kind == ActivityKind.tournament;
    return Pressable(
      semanticLabel: '${a.kind.label}: ${a.title}. $dateLine. ${a.venue.name}',
      onPressed: open,
      child: Container(
        decoration: BoxDecoration(
          color: onHome ? context.home.page : c.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: onHome ? context.home.cardBorder : c.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tournaments always carry a banner; older ones without a banner
            // title use their name.
            if (hasBanner)
              CourtHero(
                color: bannerColor,
                height: 132,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          a.coverTitle ?? a.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.title.copyWith(color: bannerInk),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _SaveButton(activity: a, glass: true),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: tile,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: OgIcon(
                            icon,
                            size: 18,
                            color: tileInk,
                            strokeWidth: 1.9,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(a.kind.label, style: context.type.body),
                        const SizedBox(width: 8),
                        KitTag(
                          chip,
                          height: 22,
                          background: chipBg,
                          foreground: chipFg,
                        ),
                        if (a.kind == ActivityKind.meet &&
                            a.men + a.women > 0) ...[
                          const SizedBox(width: 8),
                          _GenderChip(men: a.men, women: a.women),
                        ],
                        const Spacer(),
                        // Cards with a banner have the heart on the banner.
                        if (!hasBanner)
                          Transform.translate(
                            offset: const Offset(8, 0),
                            child: _SaveButton(activity: a),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.section,
                  ),
                  const SizedBox(height: 12),
                  _Line(OgIcons.calendarBox, dateLine, dateSub, tight: onHome),
                  const SizedBox(height: 12),
                  _Line(
                    OgIcons.mapPin,
                    a.online ? '${a.venue.name} and online' : a.venue.name,
                    a.venue.address,
                    tight: onHome,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OgIcon(
                        OgIcons.group,
                        size: 18,
                        color: c.textMuted,
                        strokeWidth: 1.8,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          people,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.caption,
                        ),
                      ),
                    ],
                  ),
                  // Elsewhere an empty strip keeps every card in a row the same
                  // height; on Home the card ends where its content does.
                  if (!onHome || a.proof != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 28,
                      child: a.proof == null ? null : _Proof(a.proof!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({required this.men, required this.women});

  final int men;
  final int women;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.tones.soft,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Semantics(
        label: '$men men, $women women going',
        child: ExcludeSemantics(
          child: Row(
            children: [
              OgIcon(OgIcons.male, size: 13, strokeWidth: 2.2),
              const SizedBox(width: 2),
              Text('$men', style: context.type.caption),
              const SizedBox(width: 8),
              OgIcon(OgIcons.female, size: 13, strokeWidth: 2.2),
              const SizedBox(width: 2),
              Text('$women', style: context.type.caption),
            ],
          ),
        ),
      ),
    );
  }
}

/// What an activity is stored with when nobody picked a cover.
const _defaultCover = 0xFF1C1F23;

class _Line extends StatelessWidget {
  const _Line(this.icon, this.title, this.sub, {this.tight = false});

  /// Leaves out the spare line a missing second line would take.
  final bool tight;
  final String icon;
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: OgIcon(icon, size: 18, color: c.textMuted, strokeWidth: 1.8),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.body,
              ),
              // Always takes a line, so cards line up with or without one.
              if (!tight || (sub?.isNotEmpty ?? false))
                Text(
                  sub ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.caption,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Proof extends StatelessWidget {
  const _Proof(this.proof);

  final SocialProof proof;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SolidAvatar(
          initials: proof.mark,
          color: Color(proof.color),
          ink: Color(proof.ink),
          size: 28,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: proof.name, style: context.type.caption),
                TextSpan(text: ' ${proof.text}'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.type.caption.copyWith(color: context.tones.onTag),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends ConsumerWidget {
  const _SaveButton({required this.activity, this.glass = false});

  final Activity activity;

  /// A frosted round button for the banner of tournaments and events.
  final bool glass;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    try {
      final now = await ref
          .read(savedIdsProvider(SavedKind.meet).notifier)
          .toggle(activity.id);
      if (context.mounted) {
        showOgToast(context, now ? 'Saved' : 'Removed from saved');
      }
    } on AuthFailure catch (e) {
      if (context.mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final saved =
        ref
            .watch(savedIdsProvider(SavedKind.meet))
            .value
            ?.contains(activity.id) ??
        false;
    final label = saved
        ? 'Remove ${activity.title} from saved'
        : 'Save ${activity.title}';
    if (!glass) {
      return KitIconButton(
        icon: OgIcons.heart,
        label: label,
        size: 22,
        strokeWidth: 1.8,
        color: saved ? c.primary : c.textMuted,
        fill: saved,
        onPressed: () => _toggle(context, ref),
      );
    }
    return Pressable(
      semanticLabel: label,
      selected: saved,
      onPressed: () => _toggle(context, ref),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                alignment: Alignment.center,
                child: OgIcon(
                  OgIcons.heart,
                  size: 20,
                  strokeWidth: 2,
                  color: Colors.white,
                  fill: saved,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
