import 'package:flutter/material.dart';

import '../theme/og_text.dart';

/// The pastel avatar colours used across the design.
enum AvatarTone {
  green(Color(0xFFDCF2E3), Color(0xFF1F6B3A)),
  yellow(Color(0xFFFFF0C2), Color(0xFF7A5600)),
  pink(Color(0xFFFCE1EC), Color(0xFFA12A5E)),
  blue(Color(0xFFDCE9FF), Color(0xFF1E4E8C)),
  purple(Color(0xFFECE4FF), Color(0xFF5B3BA8)),
  peach(Color(0xFFFFE3D1), Color(0xFF9A3A00)),
  brand(Color(0xFFE8590C), Color(0xFFFFFFFF));

  const AvatarTone(this.fill, this.ink);
  final Color fill;
  final Color ink;

  /// Fixed tones for known ids (the demo players match the design).
  static final overrides = <String, AvatarTone>{};

  /// A stable pastel for any player id.
  static AvatarTone forId(String id) {
    final fixed = overrides[id];
    if (fixed != null) return fixed;
    final pastels = values.where((t) => t != brand).toList();
    return pastels[id.codeUnits.fold(0, (a, b) => a + b) % pastels.length];
  }
}

/// Round (or, for groups, rounded-square) avatar: the photo when there is
/// one, otherwise initials on a pastel.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.initials,
    this.tone = AvatarTone.green,
    this.imageUrl,
    this.size = 48,
    this.square = false,
    this.fontSize,
  });

  final String initials;
  final AvatarTone tone;
  final String? imageUrl;
  final double size;
  final bool square;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(square ? 14 : size / 2);
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone.fill, borderRadius: radius),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: OgText.display(fontSize ?? size * 0.375, color: tone.ink),
      ),
    );
    if (imageUrl == null) return ExcludeSemantics(child: fallback);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: radius,
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}
