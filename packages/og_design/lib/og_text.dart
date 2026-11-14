import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The old type helpers, kept for the admin web app. The phone app uses the
/// roles in [OgType] instead (Q257). Jost everywhere; no Bold.
abstract final class OgText {
  static TextStyle _face({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => GoogleFonts.jost(
    fontSize: fontSize,
    fontWeight: fontWeight.value > 500 ? FontWeight.w500 : fontWeight,
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
