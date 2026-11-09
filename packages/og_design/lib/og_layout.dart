import 'package:flutter/animation.dart';

/// Spacing scale from the design system ("Spacing, radius, shadow").
/// Widgets take their padding and gaps from here, never a raw number.
abstract final class OgSpace {
  /// Icon to text.
  static const double s1 = 4;

  /// Label to field, chip gaps.
  static const double s2 = 8;

  /// Stacked buttons, list rows.
  static const double s3 = 12;

  /// Card padding.
  static const double s4 = 16;

  /// Screen side padding.
  static const double s6 = 24;

  /// Title block to form.
  static const double s8 = 32;

  /// Splash and celebration gaps.
  static const double s12 = 48;
}

/// Corner radii from the design system.
abstract final class OgRadius {
  /// Small tags.
  static const double sm = 8;

  /// Inputs, option rows.
  static const double md = 16;

  /// Cards.
  static const double lg = 20;

  /// Buttons and chips.
  static const double pill = 999;
}

/// Fixed sizes shared by components.
abstract final class OgSize {
  /// The shortest a settings-style row may be.
  static const double row = 56;

  /// The shortest a settings row with a subtitle may be.
  static const double rowWithSubtitle = 72;

  /// A row's leading icon.
  static const double icon = 24;

  /// The most of a settings row its value may take; the label keeps the
  /// rest.
  static const double valueShare = 0.6;

  /// The focus outline on a control (design system rule 6).
  static const double focusRing = 3;

  /// The "new" dot on a settings row.
  static const double dot = 8;

  /// The band between settings groups.
  static const double groupGap = 8;

  /// The search bar on a settings list (also its tap target).
  static const double searchBar = 44;

  /// The photo on Edit profile.
  static const double avatarLarge = 96;

  /// The smallest tap target.
  static const double tapTarget = 48;

  /// A divider between rows.
  static const double hairline = 1;

  /// A chevron or other small trailing icon.
  static const double iconSmall = 20;

  /// From this text scale a row whose label and value no longer fit on one
  /// line puts the value under the label instead of cutting it short.
  static const double stackTextScale = 1.3;

  /// The height of a skeleton line, about one line of body text.
  static const double skeletonLine = 14;

  /// Widest a card or form gets on a tablet.
  static const double readableWidth = 560;

  /// From this width the layout is a tablet's: cards centre at
  /// [readableWidth].
  static const double wide = 600;
}

/// Motion. UI feedback stays short and eases out; with reduced motion on,
/// movement goes and only colour or opacity changes remain.
abstract final class OgMotion {
  /// Press feedback on rows and buttons.
  static const press = Duration(milliseconds: 150);

  /// The page fade used instead of a slide when reduced motion is on.
  static const fade = Duration(milliseconds: 200);

  static const Curve ease = Curves.easeOut;

  /// The pause after typing before a live check (username free?) runs.
  static const debounce = Duration(milliseconds: 400);
}
