import 'package:flutter/material.dart';

/// Colours for Home and the floating tab bar only (owner, 14 Nov 2026). They
/// sit beside [OgColors] so the rest of the app keeps its own palette: the
/// hero is deep orange in light and lime in dark, and the tab bar is a white
/// or near-black pill.
@immutable
class OgHome extends ThemeExtension<OgHome> {
  const OgHome({
    required this.page,
    required this.hero,
    required this.onHero,
    required this.heroButton,
    required this.onHeroButton,
    required this.surface,
    required this.heading,
    required this.link,
    required this.iconTint,
    required this.iconInk,
    required this.cardBorder,
    required this.shadow,
    required this.adSurface,
    required this.onAd,
    required this.adMuted,
    required this.adAccent,
    required this.onAdAccent,
    required this.pointsTag,
    required this.onPointsTag,
    required this.navSurface,
    required this.navBorder,
    required this.navSelectedTint,
    required this.navSelected,
    required this.navIdle,
    required this.navBadge,
    required this.onNavBadge,
  });

  /// The page behind Home, and the band under the clock once the hero has
  /// scrolled away (#FFFFFF, #0F1113).
  final Color page;

  /// The hero block (#FF5722, #C6FF00).
  final Color hero;

  /// Greeting text on the hero: ink in both themes (#16181B).
  final Color onHero;

  /// The round Schedule and Saved buttons: white in both themes.
  final Color heroButton;
  final Color onHeroButton;

  /// Search bar, favourite cards, service circles, player and product tiles
  /// (#FFFFFF, #22262B).
  final Color surface;

  /// Headings and names on Home (#22262B, #C6FF00).
  final Color heading;

  /// Edit, View all and See all (#A85200, #C6FF00).
  final Color link;

  /// The circle behind a favourite's icon (#FFE8CC, #2A3600) and the icon on
  /// it (#A85200, #C6FF00).
  final Color iconTint;
  final Color iconInk;

  /// Border on Meet, event and tournament cards (#E2E0D8, #2E333A).
  final Color cardBorder;

  /// Soft shadow under the search bar and the tab bar.
  final Color shadow;

  /// The ad card (#16181B, #1A1D21), its text, its grey line and its lime.
  final Color adSurface;
  final Color onAd;
  final Color adMuted;
  final Color adAccent;
  final Color onAdAccent;

  /// The "up to N pts" tag: brown on peach in light, lime on olive in dark.
  final Color pointsTag;
  final Color onPointsTag;

  /// The floating tab bar (#FFFFFF, #0F1113) and its border (#E2E0D8,
  /// #2E333A).
  final Color navSurface;
  final Color navBorder;

  /// The tint behind the selected tab's icon (#FFE8CC, #2A3600), and the
  /// colour of the selected icon and label (#A85200, #C6FF00).
  final Color navSelectedTint;
  final Color navSelected;

  /// Icon and label of the other tabs.
  final Color navIdle;

  /// The Inbox count bubble (#D2342C, #FF5A4E) and the count on it.
  final Color navBadge;
  final Color onNavBadge;

  static const light = OgHome(
    page: Color(0xFFFFFFFF),
    hero: Color(0xFFFF5722),
    onHero: Color(0xFF16181B),
    heroButton: Color(0xFFFFFFFF),
    onHeroButton: Color(0xFF16181B),
    surface: Color(0xFFFFFFFF),
    heading: Color(0xFF22262B),
    link: Color(0xFFA85200),
    iconTint: Color(0xFFFFE8CC),
    iconInk: Color(0xFFA85200),
    cardBorder: Color(0xFFE2E0D8),
    shadow: Color(0x2416181B),
    adSurface: Color(0xFF16181B),
    onAd: Color(0xFFFFFFFF),
    adMuted: Color(0xFFA9AFB6),
    adAccent: Color(0xFFC6FF00),
    onAdAccent: Color(0xFF16181B),
    pointsTag: Color(0xFFFFE8CC),
    onPointsTag: Color(0xFF7A3B00),
    navSurface: Color(0xFFFFFFFF),
    navBorder: Color(0xFFE2E0D8),
    navSelectedTint: Color(0xFFFFE8CC),
    navSelected: Color(0xFFA85200),
    navIdle: Color(0xFF5A5F66),
    navBadge: Color(0xFFD2342C),
    onNavBadge: Color(0xFFFFFFFF),
  );

  static const dark = OgHome(
    page: Color(0xFF0F1113),
    hero: Color(0xFFC6FF00),
    onHero: Color(0xFF16181B),
    heroButton: Color(0xFFFFFFFF),
    onHeroButton: Color(0xFF16181B),
    surface: Color(0xFF22262B),
    heading: Color(0xFFC6FF00),
    link: Color(0xFFC6FF00),
    iconTint: Color(0xFF2A3600),
    iconInk: Color(0xFFC6FF00),
    cardBorder: Color(0xFF2E333A),
    shadow: Color(0x66000000),
    adSurface: Color(0xFF1A1D21),
    onAd: Color(0xFFFFFFFF),
    adMuted: Color(0xFFA9AFB6),
    adAccent: Color(0xFFC6FF00),
    onAdAccent: Color(0xFF16181B),
    pointsTag: Color(0xFF2A3600),
    onPointsTag: Color(0xFFC6FF00),
    navSurface: Color(0xFF0F1113),
    navBorder: Color(0xFF2E333A),
    navSelectedTint: Color(0xFF2A3600),
    navSelected: Color(0xFFC6FF00),
    navIdle: Color(0xFFA9AFB6),
    navBadge: Color(0xFFFF5A4E),
    onNavBadge: Color(0xFF16181B),
  );

  @override
  OgHome copyWith() => this;

  @override
  OgHome lerp(ThemeExtension<OgHome>? other, double t) {
    if (other is! OgHome) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return OgHome(
      page: l(page, other.page),
      hero: l(hero, other.hero),
      onHero: l(onHero, other.onHero),
      heroButton: l(heroButton, other.heroButton),
      onHeroButton: l(onHeroButton, other.onHeroButton),
      surface: l(surface, other.surface),
      heading: l(heading, other.heading),
      link: l(link, other.link),
      iconTint: l(iconTint, other.iconTint),
      iconInk: l(iconInk, other.iconInk),
      cardBorder: l(cardBorder, other.cardBorder),
      shadow: l(shadow, other.shadow),
      adSurface: l(adSurface, other.adSurface),
      onAd: l(onAd, other.onAd),
      adMuted: l(adMuted, other.adMuted),
      adAccent: l(adAccent, other.adAccent),
      onAdAccent: l(onAdAccent, other.onAdAccent),
      pointsTag: l(pointsTag, other.pointsTag),
      onPointsTag: l(onPointsTag, other.onPointsTag),
      navSurface: l(navSurface, other.navSurface),
      navBorder: l(navBorder, other.navBorder),
      navSelectedTint: l(navSelectedTint, other.navSelectedTint),
      navSelected: l(navSelected, other.navSelected),
      navIdle: l(navIdle, other.navIdle),
      navBadge: l(navBadge, other.navBadge),
      onNavBadge: l(onNavBadge, other.onNavBadge),
    );
  }
}

extension OgHomeX on BuildContext {
  /// Home and tab bar colours: `context.home.hero`.
  OgHome get home => Theme.of(this).extension<OgHome>()!;
}

/// Sizes for Home and the floating tab bar (owner, 14 Nov 2026).
abstract final class OgHomeSize {
  /// Hero height below the status bar.
  static const double hero = 232;

  /// How far the search bar overlaps the hero's bottom edge.
  static const double searchOverlap = 28;

  /// The search bar.
  static const double search = 56;

  /// Home's side margin, and the gap between its blocks.
  static const double side = 20;
  static const double block = 28;

  /// The round Schedule and Saved buttons.
  static const double heroButton = 44;

  /// The tinted circle behind a favourite's icon.
  static const double favouriteIcon = 44;

  /// A circle in More services.
  static const double service = 60;

  /// A More services item: the circle plus a label under it.
  static const double serviceItemWidth = 72;

  /// The tab bar pill, and how far it sits in from each side.
  static const double nav = 64;
  static const double navSide = 16;

  /// Gap under the pill on phones with a home indicator, and on those
  /// without one.
  static const double navBottomIndicator = 24;
  static const double navBottomPlain = 12;

  /// The room content keeps clear above the pill.
  static const double navBreathing = 16;

  /// A tab's icon, the tint behind it, and the 90 % of the idle tabs.
  static const double navIcon = 22;
  static const double navTintWidth = 48;
  static const double navTintHeight = 28;
  static const double navIdleScale = 0.9;

  /// The most the tab labels grow with the text size, so five fit in a row.
  static const double navMaxTextScale = 1.3;

  /// The Inbox count bubble.
  static const double badge = 18;
}
