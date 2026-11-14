import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:og_money/og_money.dart' show pointsText;

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/og_colors.dart';
import '../../core/theme/og_home.dart';
import '../../core/theme/og_layout.dart';
import '../../core/theme/og_type.dart';
import '../../core/widgets/og_icon.dart';
import '../../core/widgets/og_kit.dart';
import '../../core/widgets/og_toast.dart';
import '../../core/widgets/pressable.dart';
import '../earnings/application/earnings_providers.dart';
import '../game/application/game_providers.dart';
import '../game/domain/game_models.dart';
import 'application/home_categories.dart';
import 'home_rows.dart';

// ─── Hero and search ───────────────────────────────────────────────────────

/// The deep orange block from the top of the screen, with the greeting and
/// the Schedule and Saved buttons, and the search bar over its bottom edge.
class HomeHero extends ConsumerWidget {
  const HomeHero({super.key, required this.top, this.orangeKey});

  /// The status bar's height; the hero runs up under it.
  final double top;

  /// On the orange block, so Home can tell when it has scrolled away.
  final Key? orangeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = context.home;
    final first = ref.watch(sessionProfileProvider).value?.firstName ?? '';
    final name = first.isEmpty ? 'to OlympusGO' : first;
    // Only as tall as the greeting needs, plus the half of the search bar
    // that sits over its bottom edge.
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              key: orangeKey,
              color: h.hero,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  OgHomeSize.side,
                  top + OgHomeSize.heroPad,
                  OgHomeSize.side,
                  OgHomeSize.heroPad + OgHomeSize.searchOverlap,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        label: 'Welcome, $name',
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome,',
                                style: context.type.groupLabel.copyWith(
                                  color: h.onHero,
                                ),
                              ),
                              Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.type.display.copyWith(
                                  color: h.onHero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: OgSpace.s2),
                    KitIconButton(
                      icon: OgIcons.calendarBox,
                      label: 'My schedule',
                      strokeWidth: 1.9,
                      background: h.heroButton,
                      color: h.onHeroButton,
                      onPressed: () => context.push(Routes.schedule()),
                    ),
                    const SizedBox(width: OgSpace.s2),
                    KitIconButton(
                      icon: OgIcons.bookmark,
                      label: 'Saved',
                      strokeWidth: 1.9,
                      background: h.heroButton,
                      color: h.onHeroButton,
                      onPressed: () => context.push(Routes.saved),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: OgHomeSize.searchOverlap),
          ],
        ),
        const Positioned(
          left: OgHomeSize.side,
          right: OgHomeSize.side,
          bottom: 0,
          child: HomeSearch(),
        ),
      ],
    );
  }
}

class HomeSearch extends StatelessWidget {
  const HomeSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    final c = context.og;
    return Pressable(
      semanticLabel: 'Search Meets, clubs, players, shops',
      onPressed: () => context.push(Routes.search),
      child: Container(
        height: OgHomeSize.search,
        padding: const EdgeInsets.symmetric(horizontal: OgSpace.s4),
        decoration: BoxDecoration(
          color: h.surface,
          borderRadius: BorderRadius.circular(OgRadius.lg),
          boxShadow: [
            BoxShadow(
              color: h.shadow,
              blurRadius: OgSpace.s6,
              offset: const Offset(0, OgSpace.s2),
            ),
          ],
        ),
        child: Row(
          children: [
            OgIcon(OgIcons.search, size: OgSize.icon, color: c.textMuted),
            const SizedBox(width: OgSpace.s3),
            Expanded(
              child: Text(
                'Search Meets, clubs, players, shops',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shortcuts ─────────────────────────────────────────────────────────────

/// Two rows of four round shortcuts (owner, 14 Nov 2026): the player's chosen
/// services, up to seven, then More, which lists them all and is where they
/// are picked and ordered.
class HomeShortcuts extends ConsumerWidget {
  const HomeShortcuts({super.key});

  static const perRow = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(homeCategoriesControllerProvider);
    final items = [
      for (final i in prefs.order)
        if (prefs.shown.contains(i)) i,
    ].take(maxHomeCategories).toList();
    final cells = <Widget>[
      for (final c in items)
        _ServiceItem(
          label: c.label,
          icon: c.icon,
          onPressed: () => context.push(c.route),
        ),
      _ServiceItem(
        label: 'More',
        icon: OgIcons.more,
        onPressed: () => showAllServices(context),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OgHomeSize.side,
        OgHomeSize.block,
        OgHomeSize.side,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i += perRow) ...[
            if (i > 0) const SizedBox(height: OgSpace.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = i; j < i + perRow; j++)
                  Expanded(
                    child: j < cells.length
                        ? cells[j]
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Every service, in a sheet from More, with Done at the bottom. Edit switches
/// the sheet to the shortcut list, with a live picture of Home's two rows
/// above it: switch one on for Home, drag to reorder, and Done saves and
/// switches back (owner, 14 Nov 2026).
Future<void> showAllServices(BuildContext context) {
  return showKitSheet<void>(
    context,
    builder: (sheet) => _AllServices(
      onOpen: (route) {
        Navigator.of(sheet).pop();
        context.push(route);
      },
      onClose: () => Navigator.of(sheet).pop(),
    ),
  );
}

class _AllServices extends ConsumerStatefulWidget {
  const _AllServices({required this.onOpen, required this.onClose});

  final void Function(String route) onOpen;
  final VoidCallback onClose;

  @override
  ConsumerState<_AllServices> createState() => _AllServicesState();
}

class _AllServicesState extends ConsumerState<_AllServices> {
  bool _editing = false;
  late List<HomeCategory> _order;
  late Set<HomeCategory> _shown;

  /// What Home will show, in order: at most seven.
  List<HomeCategory> get _onHome =>
      _order.where(_shown.contains).take(maxHomeCategories).toList();

  void _edit() {
    final prefs = ref.read(homeCategoriesControllerProvider);
    setState(() {
      _order = [...prefs.order];
      _shown = {...prefs.shown};
      _editing = true;
    });
  }

  Future<void> _done() async {
    if (!_editing) return widget.onClose();
    await ref.read(homeCategoriesControllerProvider.notifier).save((
      order: _order,
      shown: _shown,
    ));
    if (mounted) setState(() => _editing = false);
  }

  void _toggle(HomeCategory c, bool on) {
    final message = !on && _shown.length <= minHomeCategories
        ? 'At least $minHomeCategories stay on.'
        : on && _shown.length >= maxHomeCategories
        ? 'Up to $maxHomeCategories on Home. Turn one off first.'
        : null;
    if (message != null) {
      showOgToast(context, message, error: true);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => on ? _shown.add(c) : _shown.remove(c));
  }

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  _editing ? 'Edit shortcuts' : 'All services',
                  style: context.type.title,
                ),
              ),
            ),
            if (!_editing)
              KitLink(
                'Edit',
                onPressed: _edit,
                color: h.link,
                size: 15,
                minHeight: OgSize.tapTarget,
              ),
          ],
        ),
        const SizedBox(height: OgSpace.s2),
        if (_editing) ..._editParts(context) else ..._gridParts(),
        const SizedBox(height: OgSpace.s4),
        KitButton(label: 'Done', onPressed: _done),
      ],
    );
  }

  List<Widget> _gridParts() {
    const all = HomeCategory.values;
    return [
      Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: OgSpace.s2),
          child: Column(
            children: [
              for (var i = 0; i < all.length; i += HomeShortcuts.perRow) ...[
                if (i > 0) const SizedBox(height: OgSpace.s4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = i; j < i + HomeShortcuts.perRow; j++)
                      Expanded(
                        child: j < all.length
                            ? _ServiceItem(
                                label: all[j].label,
                                icon: all[j].icon,
                                onPressed: () => widget.onOpen(all[j].route),
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _editParts(BuildContext context) {
    final c = context.og;
    final h = context.home;
    final onHome = _onHome;
    return [
      Text(
        'Switch on up to $maxHomeCategories and drag to change the order. '
        'Home shows them like this:',
        style: context.type.secondary,
      ),
      const SizedBox(height: OgSpace.s3),
      _HomePreview(onHome),
      const SizedBox(height: OgSpace.s3),
      Flexible(
        child: ReorderableListView(
          shrinkWrap: true,
          buildDefaultDragHandles: false,
          proxyDecorator: (child, _, _) => Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: h.surface,
                borderRadius: BorderRadius.circular(OgRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: h.shadow,
                    blurRadius: OgSpace.s4,
                    offset: const Offset(0, OgSpace.s1),
                  ),
                ],
              ),
              child: child,
            ),
          ),
          onReorderItem: (from, to) => setState(() {
            final next = [..._order];
            next.insert(to, next.removeAt(from));
            _order = next;
          }),
          children: [
            for (final (i, item) in _order.indexed)
              Container(
                key: ValueKey(item),
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: Semantics(
                        label: 'Reorder ${item.label}',
                        child: SizedBox(
                          width: OgSize.tapTarget,
                          height: OgSize.tapTarget,
                          child: Center(
                            child: OgIcon(
                              OgIcons.reorder,
                              size: OgSize.icon,
                              color: c.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _Position(
                      onHome.contains(item) ? onHome.indexOf(item) + 1 : null,
                    ),
                    const SizedBox(width: OgSpace.s3),
                    Expanded(child: Text(item.label, style: context.type.body)),
                    Semantics(
                      label: onHome.contains(item)
                          ? '${item.label}, number ${onHome.indexOf(item) + 1} on Home'
                          : '${item.label}, not on Home',
                      child: CupertinoSwitch(
                        value: _shown.contains(item),
                        activeTrackColor: c.primary,
                        inactiveTrackColor: c.borderControl,
                        onChanged: (on) => _toggle(item, on),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

/// A small picture of Home's two rows while editing: the chosen services in
/// order, then More. It changes as switches flip and rows move.
class _HomePreview extends StatelessWidget {
  const _HomePreview(this.onHome);

  final List<HomeCategory> onHome;

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    final cells = [
      for (final (i, c) in onHome.indexed) (c.label, c.icon, i + 1),
      ('More', OgIcons.more, null),
    ];
    return Semantics(
      label:
          'On Home, in order: ${[for (final c in onHome) c.label, 'More'].join(', ')}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(OgSpace.s3),
          decoration: BoxDecoration(
            color: h.page,
            borderRadius: BorderRadius.circular(OgRadius.lg),
            border: Border.all(color: h.cardBorder, width: OgSize.hairline),
          ),
          child: Column(
            children: [
              for (
                var i = 0;
                i < 2 * HomeShortcuts.perRow;
                i += HomeShortcuts.perRow
              ) ...[
                if (i > 0) const SizedBox(height: OgSpace.s2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = i; j < i + HomeShortcuts.perRow; j++)
                      Expanded(
                        child: j < cells.length
                            ? _PreviewCell(
                                label: cells[j].$1,
                                icon: cells[j].$2,
                                position: cells[j].$3,
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCell extends StatelessWidget {
  const _PreviewCell({
    required this.label,
    required this.icon,
    required this.position,
  });

  final String label;
  final String icon;
  final int? position;

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: OgHomeSize.previewCircle,
              height: OgHomeSize.previewCircle,
              decoration: BoxDecoration(
                color: h.iconTint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(
                icon,
                size: OgSize.iconSmall,
                strokeWidth: 1.8,
                color: h.iconInk,
              ),
            ),
            if (position != null)
              Positioned(
                right: -OgSpace.s1,
                top: -OgSpace.s1,
                child: _Position(position, small: true),
              ),
          ],
        ),
        const SizedBox(height: OgSpace.s1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.type.caption.copyWith(color: h.heading),
        ),
      ],
    );
  }
}

/// A shortcut's place on Home, as a small numbered dot; empty when it is off.
class _Position extends StatelessWidget {
  const _Position(this.n, {this.small = false});

  final int? n;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    final size = small ? OgHomeSize.positionSmall : OgHomeSize.position;
    if (n == null) return SizedBox(width: size, height: size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: h.iconInk, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$n',
        style: context.type.caption.copyWith(
          color: h.surface,
          fontSize: small ? 10 : null,
          height: 1,
        ),
      ),
    );
  }
}

/// A tinted round icon with its name under it.
class _ServiceItem extends StatelessWidget {
  const _ServiceItem({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    return Pressable(
      semanticLabel: label,
      onPressed: onPressed,
      child: Column(
        children: [
          Container(
            width: OgHomeSize.service,
            height: OgHomeSize.service,
            decoration: BoxDecoration(
              color: h.iconTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: OgIcon(
              icon,
              size: OgSize.icon,
              strokeWidth: 1.8,
              color: h.iconInk,
            ),
          ),
          const SizedBox(height: OgSpace.s2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.type.caption.copyWith(color: h.heading),
          ),
        ],
      ),
    );
  }
}

// ─── Wallet and points ─────────────────────────────────────────────────────

/// Two outlined cards side by side: vouchers ready to use, and points. Both
/// come from the server; nothing is worked out here.
class HomeWalletPoints extends ConsumerWidget {
  const HomeWalletPoints({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouchers = ref.watch(myVouchersProvider).value;
    final points = ref.watch(pointsSummaryProvider).value;
    final ready = vouchers?.where((v) => v.usable).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OgHomeSize.side,
        OgHomeSize.block,
        OgHomeSize.side,
        0,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _WalletCard(
                icon: OgIcons.walletCard,
                label: 'Wallet',
                value: switch (ready) {
                  null => '–',
                  1 => '1 voucher',
                  final n => '$n vouchers',
                },
                route: Routes.wallet,
              ),
            ),
            const SizedBox(width: OgSpace.s3),
            Expanded(
              child: _WalletCard(
                icon: OgIcons.pointsStar,
                label: 'Points',
                value: points == null ? '–' : pointsText(points.minor),
                route: Routes.points,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.route,
  });

  final String icon;
  final String label;
  final String value;
  final String route;

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    return Pressable(
      semanticLabel: value == '–' ? label : '$label, $value',
      onPressed: () => context.push(route),
      child: Container(
        // Kept short (owner, 14 Nov 2026): 12 above and below.
        padding: const EdgeInsets.symmetric(
          horizontal: OgSpace.s4,
          vertical: OgSpace.s3,
        ),
        decoration: BoxDecoration(
          color: h.surface,
          borderRadius: BorderRadius.circular(OgRadius.lg),
          border: Border.all(color: h.cardBorder, width: OgSize.hairline),
        ),
        child: Row(
          children: [
            OgIcon(icon, size: OgSize.icon, strokeWidth: 1.8, color: h.iconInk),
            const SizedBox(width: OgSpace.s3),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.caption,
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.section.copyWith(color: h.heading),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ad ────────────────────────────────────────────────────────────────────

/// A dark card for the Shop. Tapping anywhere on it opens the Shop.
class HomeAd extends StatelessWidget {
  const HomeAd({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OgHomeSize.side,
        OgHomeSize.block,
        OgHomeSize.side,
        0,
      ),
      child: Pressable(
        semanticLabel:
            'Ad. Gear up for game day. Rackets, shoes and strings. Shop now',
        onPressed: () => context.push(Routes.shop),
        child: Container(
          padding: const EdgeInsets.all(OgSpace.s4),
          decoration: BoxDecoration(
            color: h.adSurface,
            borderRadius: BorderRadius.circular(OgRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OgSpace.s2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(OgRadius.sm),
                          border: Border.all(
                            color: h.adMuted,
                            width: OgSize.hairline,
                          ),
                        ),
                        child: Text(
                          'Ad',
                          style: context.type.caption.copyWith(
                            color: h.adMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: OgSpace.s2),
                      Text(
                        'Gear up for game day',
                        style: context.type.section.copyWith(color: h.onAd),
                      ),
                      const SizedBox(height: OgSpace.s1),
                      Text(
                        'Rackets, shoes and strings.',
                        style: context.type.caption.copyWith(color: h.adMuted),
                      ),
                      const SizedBox(height: OgSpace.s3),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: OgSize.tapTarget,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1,
                          child: Text(
                            'Shop now',
                            style: context.type.button.copyWith(
                              color: h.adAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: OgSpace.s3),
              ExcludeSemantics(
                child: Container(
                  width: OgHomeSize.service,
                  height: OgHomeSize.service,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: h.adAccent,
                      width: OgSize.hairline * 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: OgIcon(
                    OgIcons.racquet,
                    size: OgSize.icon + OgSpace.s2,
                    strokeWidth: 1.6,
                    color: h.adAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Challenges ────────────────────────────────────────────────────────────

/// Live campaigns as colourful cards. Not drawn until there is one.
class HomeChallenges extends ConsumerWidget {
  const HomeChallenges({super.key});

  static const _cardWidth = 260.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = [
      for (final c in ref.watch(campaignsProvider).value ?? const <Campaign>[])
        if (c.state == CampaignState.live) c,
    ];
    if (live.isEmpty) return const SizedBox.shrink();
    return HomeSection(
      title: 'Challenges',
      home: true,
      onSeeAll: () => context.push(Routes.game),
      child: Shelf(
        children: [
          for (final c in live)
            SizedBox(width: _cardWidth, child: _ChallengeCard(c)),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard(this.c);

  final Campaign c;

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    final ink = Color(c.ink);
    final hasBar = c.target > 0;
    final shown = hasBar ? c.progress.clamp(0, c.target) : 0;
    final note = c.progressNote.isNotEmpty
        ? c.progressNote
        : '$shown of ${c.target}';
    return Pressable(
      semanticLabel: [
        'Live challenge',
        c.title,
        'Reward: ${c.reward}',
        if (hasBar) note,
      ].join('. '),
      onPressed: () => context.push(Routes.campaign(c.id)),
      child: Container(
        padding: const EdgeInsets.all(OgSpace.s4),
        decoration: BoxDecoration(
          color: Color(c.color),
          borderRadius: BorderRadius.circular(OgRadius.lg),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KitTag(
                CampaignState.live.label,
                height: 22,
                background: h.adAccent,
                foreground: h.onAdAccent,
              ),
              const SizedBox(height: OgSpace.s3),
              Text(
                c.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.type.section.copyWith(color: ink),
              ),
              const SizedBox(height: OgSpace.s1),
              Text(
                c.reward,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.type.body.copyWith(color: ink),
              ),
              const Spacer(),
              if (hasBar) ...[
                const SizedBox(height: OgSpace.s3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(OgRadius.pill),
                  child: Stack(
                    children: [
                      Container(
                        height: OgSpace.s2,
                        color: ink.withValues(alpha: 0.2),
                      ),
                      FractionallySizedBox(
                        widthFactor: shown / c.target,
                        child: Container(height: OgSpace.s2, color: ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OgSpace.s1),
                Text(note, style: context.type.caption.copyWith(color: ink)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
