import 'package:flutter/material.dart';

/// OlympusGO colour tokens, from the ThemeTokens artboard (light
/// "Tangerine", dark "Electric lime"). Every screen reads colours from here, never raw hex.
@immutable
class OgColors extends ThemeExtension<OgColors> {
  const OgColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryPressed,
    required this.primaryTint,
    required this.accent,
    required this.onAccent,
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.borderControl,
    required this.text,
    required this.textMuted,
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

  /// Soft tinted fill behind selected options and category icons.
  final Color primaryTint;
  final Color accent;
  final Color onAccent;
  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color borderControl;
  final Color text;
  final Color textMuted;
  final Color link;
  final Color focusRing;
  final Color success;
  final Color error;
  final Color warning;

  /// The charcoal "Next up" card on Home and similar dark cards.
  final Color inverseCard;
  final Color onInverseCard;
  final Color onInverseCardMuted;

  /// Lime used for eyebrows and icons on dark cards (#C6FF00).
  final Color highlight;

  // ThemeTokens: light "Tangerine", dark "Electric lime".
  static const tangerine = Color(0xFFF28500);
  static const tangerineLine = Color(0xFFE67700);
  static const tangerineText = Color(0xFFA85200);
  static const onTangerine = Color(0xFF1B1206);
  static const lime = Color(0xFFC6FF00);
  static const ink = Color(0xFF16181B);
  static const night = Color(0xFF0F1113);
  static const paper = Color(0xFFF3F2EC);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF2F3F0);
  static const grey400 = Color(0xFFA3A9B0);

  // Kept for the few places that name them directly.
  static const charcoal900 = ink;
  static const orange300 = lime;

  static const light = OgColors(
    primary: tangerine,
    onPrimary: onTangerine,
    primaryPressed: tangerineLine,
    primaryTint: Color(0xFFFFE8CC),
    accent: lime,
    onAccent: ink,
    bg: white,
    surface: paper,
    surfaceRaised: white,
    border: Color(0xFFE2E0D8),
    borderControl: Color(0xFFD6D3C9),
    text: ink,
    textMuted: Color(0xFF5B6168),
    link: tangerineText,
    focusRing: ink,
    success: Color(0xFF0E6B4E),
    error: Color(0xFFD2342C),
    warning: Color(0xFF8F4E00),
    inverseCard: ink,
    onInverseCard: offWhite,
    onInverseCardMuted: grey400,
    highlight: lime,
  );

  static const dark = OgColors(
    primary: lime,
    onPrimary: night,
    primaryPressed: Color(0xFFA8D900),
    primaryTint: Color(0xFF2A3600),
    accent: lime,
    onAccent: night,
    bg: night,
    surface: Color(0xFF1A1D21),
    surfaceRaised: Color(0xFF1A1D21),
    border: Color(0xFF2E333A),
    borderControl: Color(0xFF4A5058),
    text: offWhite,
    textMuted: grey400,
    link: lime,
    focusRing: lime,
    success: Color(0xFF5EEAD4),
    error: Color(0xFFFF5A4E),
    warning: Color(0xFFFFC14D),
    inverseCard: Color(0xFF1A1D21),
    onInverseCard: offWhite,
    onInverseCardMuted: grey400,
    highlight: lime,
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
      primaryTint: l(primaryTint, other.primaryTint),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      border: l(border, other.border),
      borderControl: l(borderControl, other.borderControl),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
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
