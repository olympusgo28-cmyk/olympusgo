import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/breadcrumbs.dart';
import '../../core/theme/og_colors.dart';
import '../../core/theme/og_home.dart';
import '../../core/theme/og_layout.dart';
import '../../core/theme/og_type.dart';
import '../../core/widgets/og_icon.dart';
import '../inbox/application/inbox_providers.dart';

/// Hosts the five main tabs and the bottom tab bar.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Crumbs.shellRoute = ModalRoute.of(context);
    Crumbs.tab = shell.currentIndex;
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: MainTabBar(
        index: shell.currentIndex,
        unread: ref.watch(inboxUnreadProvider),
        onTap: (i) {
          if (i != shell.currentIndex) HapticFeedback.selectionClick();
          // Tapping the current tab goes back to its first screen, like iOS.
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
      ),
    );
  }
}

const _tabs = [
  (
    '<path d="M4 11l8-7 8 7v8a1 1 0 0 1-1 1h-4v-6h-6v6H5a1 1 0 0 1-1-1z"/>',
    'Home',
  ),
  (
    '<circle cx="12" cy="12" r="9"/><path d="M15.5 8.5l-2 5-5 2 2-5z"/>',
    'Discover',
  ),
  (
    '<path d="M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3M7 12h10"/>',
    'Scan',
  ),
  ('<path d="M4 5h16v11H9l-5 4z"/><path d="M8 9h8M8 12h5"/>', 'Inbox'),
  (
    '<circle cx="12" cy="8" r="3.6"/><path d="M4.5 20c0-4 3.4-6.5 7.5-6.5s7.5 2.5 7.5 6.5"/>',
    'Profile',
  ),
];

/// The floating tab bar (owner, 14 Nov 2026): a rounded pill with a shadow
/// and a thin border, clear of the screen edges so pages scroll underneath
/// and show around it. All five tabs, Scan included, look and behave alike:
/// the selected one is full size with a tint behind its icon, the others are
/// 90 % with grey icons and labels.
class MainTabBar extends StatelessWidget {
  const MainTabBar({
    super.key,
    required this.index,
    required this.onTap,
    this.unread = 0,
  });

  final int index;
  final ValueChanged<int> onTap;

  /// New conversations, shown on the Inbox tab.
  final int unread;

  /// The pill itself, for tests to measure.
  @visibleForTesting
  static const pillKey = ValueKey('main-tab-pill');

  /// 24 above the bottom on phones with a home indicator, 12 on the rest.
  static double _gap(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom > 0
      ? OgHomeSize.navBottomIndicator
      : OgHomeSize.navBottomPlain;

  /// Height of the bar, for padding scrolling content above it.
  static double reservedHeight(BuildContext context) =>
      OgHomeSize.nav + _gap(context) + OgHomeSize.navBreathing;

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    return Semantics(
      container: true,
      label: 'Main',
      child: Align(
        // The bar's own background stays clear outside the pill.
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: OgSize.readableWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              OgHomeSize.navSide,
              0,
              OgHomeSize.navSide,
              _gap(context),
            ),
            // Five labels in one row: they grow with the text size, but only
            // so far.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: OgHomeSize.navMaxTextScale,
              child: Container(
                key: pillKey,
                height: OgHomeSize.nav,
                decoration: BoxDecoration(
                  color: h.navSurface,
                  borderRadius: BorderRadius.circular(OgRadius.pill),
                  border: Border.all(
                    color: h.navBorder,
                    width: OgSize.hairline,
                  ),
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
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: _TabButton(
                          icon: _tabs[i].$1,
                          label: _tabs[i].$2,
                          selected: i == index,
                          badge: i == 3 ? unread : 0,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    final selected = widget.selected;
    final badge = widget.badge;
    final fg = selected ? h.navSelected : h.navIdle;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : OgMotion.fade;
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '${widget.label}, $badge new' : widget.label,
      child: FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: ExcludeSemantics(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(OgRadius.pill),
                border: _focused
                    ? Border.all(
                        color: context.og.focusRing,
                        width: OgSize.focusRing,
                      )
                    : null,
              ),
              child: Center(
                child: AnimatedScale(
                  duration: duration,
                  curve: OgMotion.ease,
                  scale: selected ? 1 : OgHomeSize.navIdleScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: duration,
                        curve: OgMotion.ease,
                        width: OgHomeSize.navTintWidth,
                        height: OgHomeSize.navTintHeight,
                        decoration: BoxDecoration(
                          color: selected
                              ? h.navSelectedTint
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(OgRadius.pill),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            OgIcon(
                              widget.icon,
                              size: OgHomeSize.navIcon,
                              color: fg,
                              strokeWidth: 1.8,
                            ),
                            if (badge > 0)
                              Positioned(
                                top: -OgSpace.s1,
                                right: 0,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: OgHomeSize.badge,
                                  ),
                                  height: OgHomeSize.badge,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: OgSpace.s1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: h.navBadge,
                                    borderRadius: BorderRadius.circular(
                                      OgRadius.pill,
                                    ),
                                    border: Border.all(
                                      color: h.navSurface,
                                      width: OgSize.hairline * 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    badge > 9 ? '9+' : '$badge',
                                    style: context.type.caption.copyWith(
                                      color: h.onNavBadge,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: OgSpace.s1),
                      Text(
                        widget.label,
                        maxLines: 1,
                        style: context.type.caption.copyWith(color: fg),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
