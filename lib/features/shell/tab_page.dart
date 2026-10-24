import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/og_colors.dart';
import '../../core/theme/og_text.dart';
import 'main_shell.dart';

/// Scrolling page for a main tab: 24px gutters, content scrolls under the
/// floating tab bar, with native iOS pull-to-refresh when [onRefresh] is set.
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.children,
    this.background,
    this.dark = false,
    this.onRefresh,
  });

  final List<Widget> children;
  final Color? background;
  final bool dark;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isDark = dark || Theme.of(context).brightness == Brightness.dark;
    final top = math.max(56.0, mq.padding.top + 4);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: background ?? context.og.bg,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            if (onRefresh != null)
              SliverPadding(
                padding: EdgeInsets.only(top: mq.padding.top),
                sliver: CupertinoSliverRefreshControl(onRefresh: onRefresh),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                24,
                onRefresh != null ? top - mq.padding.top : top,
                24,
                MainTabBar.reservedHeight(context),
              ),
              sliver: SliverList.list(children: children),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen title used at the top of each tab.
class TabTitle extends StatelessWidget {
  const TabTitle(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: OgText.h1.copyWith(color: color ?? context.og.text),
    ),
  );
}

/// Section title such as "Meets near you".
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.top = 24});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top),
    child: Semantics(
      header: true,
      child: Text(text, style: OgText.section.copyWith(color: context.og.text)),
    ),
  );
}
