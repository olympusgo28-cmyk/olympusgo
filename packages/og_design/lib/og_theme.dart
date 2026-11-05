import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'og_colors.dart';
import 'og_tones.dart';

/// App-wide theme. Screens draw from [OgColors]; this sets the platform
/// behaviour: iOS page transitions and swipe-back on every route, bouncing
/// scroll, and Cupertino-flavoured controls.
abstract final class OgTheme {
  static ThemeData light() =>
      _build(OgColors.light, OgTones.light, Brightness.light);
  static ThemeData dark() =>
      _build(OgColors.dark, OgTones.dark, Brightness.dark);

  static ThemeData _build(OgColors c, OgTones tones, Brightness brightness) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      platform: TargetPlatform.iOS,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        surface: c.bg,
        onSurface: c.text,
        error: c.error,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: c.primary,
        scaffoldBackgroundColor: c.bg,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withValues(alpha: 0.3),
        selectionHandleColor: c.primary,
      ),
      fontFamily: GoogleFonts.figtree().fontFamily,
      extensions: [c, tones],
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    );
  }
}
