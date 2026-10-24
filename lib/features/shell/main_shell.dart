import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/breadcrumbs.dart';
import '../../core/theme/og_colors.dart';
import '../../core/theme/og_text.dart';
import '../../core/theme/og_tones.dart';
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

/// The white tab bar from the design: four labelled tabs with a pill behind
/// the selected one, and a raised round Scan button in the middle.
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

  static double _bottom(BuildContext context) =>
      math.max(20.0, MediaQuery.of(context).padding.bottom);

  /// Height of the bar, for padding scrolling content above it.
  static double reservedHeight(BuildContext context) =>
      8 + 62 + _bottom(context) + 16;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Semantics(
      container: true,
      label: 'Main',
      child: Container(
        padding: EdgeInsets.fromLTRB(8, 8, 8, _bottom(context)),
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              i == 2
                  ? _ScanButton(onTap: () => onTap(i), selected: index == i)
                  : _TabButton(
                      icon: _tabs[i].$1,
                      label: _tabs[i].$2,
                      selected: i == index,
                      badge: i == 3 ? unread : 0,
                      onTap: () => onTap(i),
                    ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = context.og;
    final fg = selected ? c.link : c.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '$label, $badge new' : label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 52,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected ? c.primaryTint : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        OgIcon(icon, size: 22, color: fg, strokeWidth: 1.8),
                        if (badge > 0)
                          Positioned(
                            top: -2,
                            right: 6,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 18),
                              height: 18,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              decoration: BoxDecoration(
                                color: context.tones.badge,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: c.bg, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                badge > 9 ? '9+' : '$badge',
                                style: OgText.body(
                                  10,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: OgText.body(
                      12,
                      weight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap, required this.selected});

  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Scan',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: SizedBox(
            width: 64,
            height: 59,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // The button rises 22pt above the bar, as in the design.
                Positioned(
                  top: -22,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2E16181B),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: OgIcon(_tabs[2].$1, size: 26, color: c.onPrimary),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  child: Text(
                    'Scan',
                    style: OgText.body(
                      12,
                      weight: FontWeight.w700,
                      color: selected ? c.link : c.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
