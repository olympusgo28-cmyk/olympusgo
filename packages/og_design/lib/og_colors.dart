import 'package:flutter/material.dart';

/// OlympusGO colour tokens from the design system: orange on white in the
/// light theme, lime on charcoal in the dark theme. There is no lime in the
/// light theme. Every screen reads colours from here, never raw hex.
@immutable
class OgColors extends ThemeExtension<OgColors> {
  const OgColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryPressed,
    required this.primarySmall,
    required this.primaryTint,
    required this.accent,
    required this.onAccent,
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.groupedBg,
    required this.groupedSurface,
    required this.border,
    required this.borderControl,
    required this.text,
    required this.textMuted,
    required this.textTertiary,
    required this.link,
    required this.focusRing,
    required this.success,
    required this.error,
    required this.warning,
    required this.inverseCard,
    required this.onInverseCard,
    required this.onInverseCardMuted,
    required this.highlight,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryPressed;

  /// Fill behind small text. White on [primary] is only large-text contrast,
  /// so anything under 18.66 px bold sits on this instead.
  final Color primarySmall;

  /// Soft tinted fill behind selected options and category icons.
  final Color primaryTint;
  final Color accent;
  final Color onAccent;
  final Color bg;
  final Color surface;
  final Color surfaceRaised;

  /// The page behind a grouped settings list: light grey, or the dark
  /// background.
  final Color groupedBg;

  /// A settings group on [groupedBg]: white, or the dark surface.
  final Color groupedSurface;
  final Color border;
  final Color borderControl;
  final Color text;
  final Color textMuted;

  /// Placeholders and disabled text: lighter than [textMuted] (Q257).
  final Color textTertiary;
  final Color link;
  final Color focusRing;
  final Color success;
  final Color error;
  final Color warning;

  /// The charcoal "Next up" card on Home and similar dark cards.
  final Color inverseCard;
  final Color onInverseCard;
  final Color onInverseCardMuted;

  /// Eyebrows and icons on dark cards.
  final Color highlight;

  static const orange500 = Color(0xFFE8590C);
  static const orange700 = Color(0xFFC94A00);
  static const orange800 = Color(0xFFA83B00);
  static const orange300 = Color(0xFFFF7A1A);
  static const lime400 = Color(0xFFC6F432);
  static const charcoal900 = Color(0xFF1C1F23);
  static const charcoal950 = Color(0xFF14171A);
  static const paper = Color(0xFFF7F7F4);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF4F5F2);
  static const grey400 = Color(0xFFA9AFB6);

  // Short names the screens use.
  static const ink = charcoal900;
  static const night = charcoal950;

  static const light = OgColors(
    primary: orange500,
    onPrimary: white,
    primaryPressed: orange700,
    primarySmall: orange700,
    primaryTint: Color(0xFFFFE6D6),
    accent: orange300,
    onAccent: charcoal900,
    bg: white,
    surface: paper,
    surfaceRaised: white,
    groupedBg: Color(0xFFF3F2EC),
    groupedSurface: white,
    border: Color(0xFFD9D9D2),
    borderControl: Color(0xFF7A8088),
    text: charcoal900,
    textMuted: Color(0xFF5A5F66),
    textTertiary: Color(0xFF868B92),
    link: orange800,
    focusRing: charcoal900,
    success: Color(0xFF1A7F4B),
    error: Color(0xFFC42B1C),
    warning: Color(0xFF8F4E00),
    inverseCard: charcoal900,
    onInverseCard: offWhite,
    onInverseCardMuted: grey400,
    highlight: orange300,
  );

  static const dark = OgColors(
    primary: lime400,
    onPrimary: charcoal900,
    primaryPressed: Color(0xFFA9D11A),
    primarySmall: lime400,
    primaryTint: Color(0xFF2E3A10),
    accent: orange300,
    onAccent: charcoal900,
    bg: charcoal950,
    surface: charcoal900,
    surfaceRaised: Color(0xFF262A2F),
    groupedBg: charcoal950,
    groupedSurface: charcoal900,
    border: Color(0xFF3A4047),
    borderControl: Color(0xFF7C838B),
    text: offWhite,
    textMuted: grey400,
    textTertiary: Color(0xFF737980),
    link: lime400,
    focusRing: lime400,
    success: Color(0xFF5AD68F),
    error: Color(0xFFFF8A7A),
    warning: Color(0xFFFFC14D),
    inverseCard: Color(0xFF262A2F),
    onInverseCard: offWhite,
    onInverseCardMuted: grey400,
    highlight: lime400,
  );

  @override
  OgColors copyWith() => this;

  @override
  OgColors lerp(ThemeExtension<OgColors>? other, double t) {
    if (other is! OgColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return OgColors(
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primaryPressed: l(primaryPressed, other.primaryPressed),
      primarySmall: l(primarySmall, other.primarySmall),
      primaryTint: l(primaryTint, other.primaryTint),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      groupedBg: l(groupedBg, other.groupedBg),
      groupedSurface: l(groupedSurface, other.groupedSurface),
      border: l(border, other.border),
      borderControl: l(borderControl, other.borderControl),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textTertiary: l(textTertiary, other.textTertiary),
      link: l(link, other.link),
      focusRing: l(focusRing, other.focusRing),
      success: l(success, other.success),
      error: l(error, other.error),
      warning: l(warning, other.warning),
      inverseCard: l(inverseCard, other.inverseCard),
      onInverseCard: l(onInverseCard, other.onInverseCard),
      onInverseCardMuted: l(onInverseCardMuted, other.onInverseCardMuted),
      highlight: l(highlight, other.highlight),
    );
  }
}

extension OgThemeX on BuildContext {
  OgColors get og => Theme.of(this).extension<OgColors>()!;
}
