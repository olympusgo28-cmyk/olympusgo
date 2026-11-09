import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'og_colors.dart';

/// The type roles (owner, 9 Nov 2026, Q257). Every piece of text in the app
/// uses one of these; no screen sets a size or weight of its own.
///
/// Jost everywhere. Score, display, title and section are Medium (500);
/// everything else is Regular (400). There is no Bold. Hierarchy comes from
/// size and colour first.
///
/// | Role      | Size / weight | Colour    | Use                                  |
/// | --------- | ------------- | --------- | ------------------------------------ |
/// | score     | 32 / 500      | primary   | scores, ratings, prices, counters    |
/// | display   | 28 / 500      | primary   | at most one hero headline a screen   |
/// | title     | 20 / 500      | primary   | screen and app bar titles            |
/// | section   | 17 / 500      | primary   | card and section headings            |
/// | groupLabel| 15 / 500      | secondary | headers over settings groups         |
/// | body      | 15 / 400      | primary   | main text, row labels, list items    |
/// | secondary | 15 / 400      | secondary | values, meta info                    |
/// | caption   | 13 / 400      | secondary | helper text, timestamps, labels      |
/// | button    | 15 / 400      | per use   | buttons, tabs, chips, links          |
/// | tertiary  | 15 / 400      | tertiary  | placeholders and disabled text       |
///
/// Primary roles carry no colour, so text inherits the colour around it
/// (primary text on the page, light text on a dark card). Secondary, caption
/// and tertiary carry their grey.
@immutable
class OgType extends ThemeExtension<OgType> {
  const OgType({
    required this.score,
    required this.display,
    required this.title,
    required this.section,
    required this.body,
    required this.secondary,
    required this.caption,
    required this.button,
    required this.tertiary,
    required this.groupLabel,
  });

  factory OgType.of(OgColors c) => OgType(
    score: face(32, FontWeight.w500, height: 1.1),
    display: face(28, FontWeight.w500, height: 1.1),
    title: face(20, FontWeight.w500, height: 1.2),
    section: face(17, FontWeight.w500, height: 1.25),
    body: face(15, FontWeight.w400),
    secondary: face(15, FontWeight.w400, color: c.textMuted),
    caption: face(13, FontWeight.w400, color: c.textMuted),
    button: face(15, FontWeight.w400, height: 1.2),
    tertiary: face(15, FontWeight.w400, color: c.textTertiary),
    groupLabel: face(15, FontWeight.w500, color: c.textMuted),
  );

  final TextStyle score;
  final TextStyle display;
  final TextStyle title;
  final TextStyle section;
  final TextStyle body;
  final TextStyle secondary;
  final TextStyle caption;
  final TextStyle button;
  final TextStyle tertiary;

  /// The header over a group of settings rows ("How you use OlympusGO").
  final TextStyle groupLabel;

  /// The only place a size and weight become a font.
  static TextStyle face(
    double size,
    FontWeight weight, {
    double? height,
    Color? color,
  }) => GoogleFonts.jost(
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
  );

  /// Jost's two weights, to load before the first frame so nothing reflows.
  static Future<List<void>> preload() => GoogleFonts.pendingFonts([
    face(15, FontWeight.w400),
    face(15, FontWeight.w500),
  ]);

  /// An error line's sentence sits under a red outline; the field itself
  /// shows no error text, so this takes no room.
  static const collapsed = TextStyle(fontSize: 0, height: 0);

  /// Initials on an avatar or logo [diameter] across: the role whose size is
  /// nearest 40 % of it, so small avatars get caption and large ones score.
  TextStyle initials(double diameter) {
    final target = diameter * 0.4;
    final roles = [caption, body, section, title, display, score];
    roles.sort(
      (a, b) =>
          (a.fontSize! - target).abs().compareTo((b.fontSize! - target).abs()),
    );
    // Callers set the avatar's own ink colour on top.
    return roles.first;
  }

  /// Material's text theme, for widgets that read it (app bars, buttons,
  /// fields, plain [Text]). Primary roles get the primary colour here.
  TextTheme textTheme(Color primary) => TextTheme(
    displayLarge: score.copyWith(color: primary),
    displayMedium: score.copyWith(color: primary),
    displaySmall: score.copyWith(color: primary),
    headlineLarge: display.copyWith(color: primary),
    headlineMedium: display.copyWith(color: primary),
    headlineSmall: display.copyWith(color: primary),
    titleLarge: title.copyWith(color: primary),
    titleMedium: section.copyWith(color: primary),
    titleSmall: section.copyWith(color: primary),
    bodyLarge: body.copyWith(color: primary),
    bodyMedium: body.copyWith(color: primary),
    bodySmall: caption,
    labelLarge: button.copyWith(color: primary),
    labelMedium: caption,
    labelSmall: caption,
  );

  @override
  OgType copyWith() => this;

  @override
  OgType lerp(ThemeExtension<OgType>? other, double t) {
    if (other is! OgType) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return OgType(
      score: l(score, other.score),
      display: l(display, other.display),
      title: l(title, other.title),
      section: l(section, other.section),
      body: l(body, other.body),
      secondary: l(secondary, other.secondary),
      caption: l(caption, other.caption),
      button: l(button, other.button),
      tertiary: l(tertiary, other.tertiary),
      groupLabel: l(groupLabel, other.groupLabel),
    );
  }
}

extension OgTypeX on BuildContext {
  /// The type roles: `context.type.body`, `context.type.title` and so on.
  OgType get type => Theme.of(this).extension<OgType>()!;
}
