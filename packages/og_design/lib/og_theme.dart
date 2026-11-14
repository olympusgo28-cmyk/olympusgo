import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'og_colors.dart';
import 'og_home.dart';
import 'og_tones.dart';
import 'og_type.dart';

/// App-wide theme. Screens draw from [OgColors]; this sets the platform
/// behaviour: iOS page transitions and swipe-back on every route, bouncing
/// scroll, and Cupertino-flavoured controls.
abstract final class OgTheme {
  static ThemeData light() =>
      _build(OgColors.light, OgTones.light, OgHome.light, Brightness.light);
  static ThemeData dark() =>
      _build(OgColors.dark, OgTones.dark, OgHome.dark, Brightness.dark);

  static ThemeData _build(
    OgColors c,
    OgTones tones,
    OgHome home,
    Brightness brightness,
  ) {
    final type = OgType.of(c);
    final text = type.textTheme(c.text);
    // Buttons, tabs and chips use the button role: they stand out by fill
    // and shape, not weight (Q257).
    final buttonText = WidgetStatePropertyAll(type.button);
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
      textTheme: text,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(textStyle: buttonText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(textStyle: buttonText),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(textStyle: buttonText),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(textStyle: buttonText),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: type.button,
        unselectedLabelStyle: type.button,
      ),
      chipTheme: ChipThemeData(labelStyle: type.button),
      extensions: [c, tones, type, home],
    );
    return base;
  }
}
