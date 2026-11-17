import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/og_colors.dart';
import '../../../../core/theme/og_home.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/activity.dart';
import 'play_card_text.dart';

/// The shell every play card shares: a tap target that opens the activity, a
/// 20-point rounded box and, optionally, an outline. Only the Meet card has an
/// outline (owner, 15 Nov 2026).
class PlayCardFrame extends StatelessWidget {
  const PlayCardFrame({
    super.key,
    required this.activity,
    required this.onHome,
    required this.outlined,
    required this.child,
  });

  final Activity activity;

  /// On Home the card is white with a light border (near-black with a dark
  /// one in the dark theme).
  final bool onHome;
  final bool outlined;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final a = activity;
    return Pressable(
      semanticLabel:
          '${a.kind.label}: ${a.title}. ${playCardDateLine(a)}. ${a.venue.name}',
      onPressed: () => context.push(Routes.activity(a.id)),
      child: Container(
        decoration: BoxDecoration(
          color: onHome ? context.home.page : c.bg,
          borderRadius: BorderRadius.circular(20),
          border: outlined
              ? Border.all(color: onHome ? context.home.cardBorder : c.border)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
