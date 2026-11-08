import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// OlympusGO type styles, all in Futura (owner, 8 Nov 2026, Q250). iPhones
/// include Futura; Android, the web and the admin web use Jost, the closest
/// free match, until a Futura licence is bought. Sizes and line heights match
/// the artboards; colour comes from the surrounding [DefaultTextStyle] unless
/// a screen overrides it.
abstract final class OgText {
  /// True where the system has Futura (iOS only).
  static bool get usesFutura =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// iOS Futura has Medium and Bold only: 600 draws Bold and 400 draws Medium.
  static TextStyle _face({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => usesFutura
      ? TextStyle(
          fontFamily: 'Futura',
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
          letterSpacing: letterSpacing,
          decoration: decoration,
          decorationColor: color,
        )
      : GoogleFonts.jost(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
          letterSpacing: letterSpacing,
          decoration: decoration,
          decorationColor: color,
        );

  static TextStyle display(double size, {double height = 1.1, Color? color}) =>
      _face(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: height,
        color: color,
      );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => _face(
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );

  /// Tight headings on club, team and shop screens (the design's `.d`
  /// class: -0.01em tracking).
  static TextStyle heading(double size, {Color? color, double height = 1.05}) =>
      _face(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: height,
        letterSpacing: -0.01 * size,
        color: color,
      );

  /// Screen titles: 34px.
  static TextStyle get h1 => display(34);

  /// Section titles such as "Meets near you": 22px.
  static TextStyle get section => display(22, height: 1.2);

  /// Pill button labels: 20px.
  static TextStyle get button => display(20, height: 1.2);

  /// Intro paragraph under a title.
  static TextStyle lead(Color color) => body(16, height: 1.45, color: color);

  /// Field labels.
  static TextStyle get label => body(14, weight: FontWeight.w600);

  /// Text typed into inputs.
  static TextStyle get input => body(18);
}
