import 'package:flutter/material.dart';

/// Status fills and soft surfaces used by the club, team, shop and creator
/// artboards (phase 3 onwards). Kept beside [OgColors] so those screens still
/// read every colour from the theme and follow dark mode.
@immutable
class OgTones extends ThemeExtension<OgTones> {
  const OgTones({
    required this.soft,
    required this.softer,
    required this.track,
    required this.divider,
    required this.tag,
    required this.onTag,
    required this.successFill,
    required this.onSuccessFill,
    required this.successInk,
    required this.warnFill,
    required this.onWarnFill,
    required this.warnInk,
    required this.infoFill,
    required this.onInfoFill,
    required this.dangerFill,
    required this.onDangerFill,
    required this.danger,
    required this.dangerText,
    required this.badge,
    required this.gold,
    required this.onGold,
    required this.disabledFill,
    required this.onDisabledFill,
    required this.scrim,
  });

  /// Grey panels, notes and search fields (#F4F5F2).
  final Color soft;

  /// Warmer grey behind quoted messages and dashed placeholders (#F7F6F1).
  final Color softer;

  /// Segmented-control track (#E7E5DC).
  final Color track;

  /// Hairline between rows inside a bordered card (#F0EEE7).
  final Color divider;

  /// Level and status tags (#EFEDE5 on #3A3F45).
  final Color tag;
  final Color onTag;

  final Color successFill;
  final Color onSuccessFill;

  /// Green ticks in "You keep" lists (#0A6B4A).
  final Color successInk;

  final Color warnFill;
  final Color onWarnFill;

  /// Darker text on warning tags (#5A4300).
  final Color warnInk;

  final Color infoFill;
  final Color onInfoFill;
  final Color dangerFill;
  final Color onDangerFill;

  /// Destructive buttons and crosses (#C8372D).
  final Color danger;

  /// Destructive text links (#B42318).
  final Color dangerText;

  /// Unread and request count badges (#D2342C).
  final Color badge;

  /// Gold for podiums, pinned tags and logo initials (#F2C14E).
  final Color gold;
  final Color onGold;

  final Color disabledFill;
  final Color onDisabledFill;

  /// Dim behind bottom sheets.
  final Color scrim;

  static const light = OgTones(
    soft: Color(0xFFF3F2EC),
    softer: Color(0xFFF7F6F1),
    track: Color(0xFFE7E5DC),
    divider: Color(0xFFF0EEE7),
    tag: Color(0xFFEFEDE5),
    onTag: Color(0xFF3A3F45),
    successFill: Color(0xFFDCEEE6),
    onSuccessFill: Color(0xFF0A4F3A),
    successInk: Color(0xFF0E6B4E),
    warnFill: Color(0xFFFBE7B0),
    onWarnFill: Color(0xFF3A2C00),
    warnInk: Color(0xFF5A4300),
    infoFill: Color(0xFFE3ECF3),
    onInfoFill: Color(0xFF2F3A5F),
    dangerFill: Color(0xFFFBE3E0),
    onDangerFill: Color(0xFF8A2E1C),
    danger: Color(0xFFD2342C),
    dangerText: Color(0xFFB42318),
    badge: Color(0xFFD2342C),
    gold: Color(0xFFF2C14E),
    onGold: Color(0xFF3A2C00),
    disabledFill: Color(0xFFE7E5DC),
    onDisabledFill: Color(0xFF8A8F96),
    scrim: Color(0x7317171A),
  );

  static const dark = OgTones(
    soft: Color(0xFF22262B),
    softer: Color(0xFF1F2328),
    track: Color(0xFF2E333A),
    divider: Color(0xFF2A2F35),
    tag: Color(0xFF2A2F35),
    onTag: Color(0xFFD0D4D9),
    successFill: Color(0xFF0F3B36),
    onSuccessFill: Color(0xFF5EEAD4),
    successInk: Color(0xFF5EEAD4),
    warnFill: Color(0xFF3D3214),
    onWarnFill: Color(0xFFF7D98A),
    warnInk: Color(0xFFF2C14E),
    infoFill: Color(0xFF1E2A3A),
    onInfoFill: Color(0xFFB7C8E6),
    dangerFill: Color(0xFF3D211C),
    onDangerFill: Color(0xFFFFB4A8),
    danger: Color(0xFFFF5A4E),
    dangerText: Color(0xFFFF8A7A),
    badge: Color(0xFFFF5A4E),
    gold: Color(0xFFF2C14E),
    onGold: Color(0xFF3A2C00),
    disabledFill: Color(0xFF2E333A),
    onDisabledFill: Color(0xFF8A9097),
    scrim: Color(0x99000000),
  );

  @override
  OgTones copyWith() => this;

  @override
  OgTones lerp(ThemeExtension<OgTones>? other, double t) {
    if (other is! OgTones) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return OgTones(
      soft: l(soft, other.soft),
      softer: l(softer, other.softer),
      track: l(track, other.track),
      divider: l(divider, other.divider),
      tag: l(tag, other.tag),
      onTag: l(onTag, other.onTag),
      successFill: l(successFill, other.successFill),
      onSuccessFill: l(onSuccessFill, other.onSuccessFill),
      successInk: l(successInk, other.successInk),
      warnFill: l(warnFill, other.warnFill),
      onWarnFill: l(onWarnFill, other.onWarnFill),
      warnInk: l(warnInk, other.warnInk),
      infoFill: l(infoFill, other.infoFill),
      onInfoFill: l(onInfoFill, other.onInfoFill),
      dangerFill: l(dangerFill, other.dangerFill),
      onDangerFill: l(onDangerFill, other.onDangerFill),
      danger: l(danger, other.danger),
      dangerText: l(dangerText, other.dangerText),
      badge: l(badge, other.badge),
      gold: l(gold, other.gold),
      onGold: l(onGold, other.onGold),
      disabledFill: l(disabledFill, other.disabledFill),
      onDisabledFill: l(onDisabledFill, other.onDisabledFill),
      scrim: l(scrim, other.scrim),
    );
  }
}

extension OgTonesX on BuildContext {
  OgTones get tones => Theme.of(this).extension<OgTones>()!;
}
