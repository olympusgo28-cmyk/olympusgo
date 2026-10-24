import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// OlympusGO type styles from the ThemeTokens artboard: display text is
/// Archivo (700 and 800), body text is Figtree. Sizes and line heights match
/// the artboards; colour comes from the surrounding [DefaultTextStyle]
/// unless a screen overrides it.
abstract final class OgText {
  static TextStyle display(double size, {double height = 1.1, Color? color}) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: FontWeight.w700,
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
  }) => GoogleFonts.figtree(
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: color,
  );

  /// Tight headings on club, team and shop screens (the design's `.d`
  /// class: extra bold, -0.01em tracking).
  static TextStyle heading(double size, {Color? color, double height = 1.05}) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: height,
        letterSpacing: -0.01 * size,
        color: color,
      );

  /// Screen titles: 34px Archivo.
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
