import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The OlympusGO mascot mark. Its ears are bright orange on dark screens
/// (splash, "You're in") and charcoal on light ones (welcome).
class Mascot extends StatelessWidget {
  const Mascot({super.key, this.size = 200, this.onDark = true});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final ear = onDark ? '#FF7A1A' : '#1C1F23';
    return ExcludeSemantics(
      child: SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300">'
        '<path d="M150 46 L258 244 L42 244Z" fill="#E8590C" stroke="#E8590C" stroke-width="16" stroke-linejoin="round"/>'
        '<path d="M150 46 L193 124 L171 112 L150 134 L129 112 L107 124Z" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="6" stroke-linejoin="round"/>'
        '<ellipse cx="116" cy="40" rx="8" ry="20" transform="rotate(-55 116 40)" fill="$ear"/>'
        '<ellipse cx="184" cy="40" rx="8" ry="20" transform="rotate(55 184 40)" fill="$ear"/>'
        '<circle cx="124" cy="190" r="11" fill="#1C1F23"/>'
        '<circle cx="176" cy="190" r="11" fill="#1C1F23"/>'
        '<path d="M126 216 Q150 240 174 216" stroke="#1C1F23" stroke-width="9" stroke-linecap="round" fill="none"/>'
        '</svg>',
        width: size,
        height: size,
      ),
    );
  }
}
