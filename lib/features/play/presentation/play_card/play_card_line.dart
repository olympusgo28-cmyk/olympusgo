import 'package:flutter/material.dart';

import '../../../../core/theme/og_colors.dart';
import '../../../../core/theme/og_type.dart';
import '../../../../core/widgets/og_icon.dart';

/// An icon, a first line (Inter 15 regular) and, under it, a second line
/// (Inter 13 regular, muted): the date and venue rows of a card.
class PlayCardLine extends StatelessWidget {
  const PlayCardLine(
    this.icon,
    this.title,
    this.sub, {
    super.key,
    this.tight = false,
  });

  /// Leaves out the spare line a missing second line would take.
  final bool tight;
  final String icon;
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: OgIcon(icon, size: 18, color: c.textMuted, strokeWidth: 1.8),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.body,
              ),
              // Always takes a line, so cards line up with or without one.
              if (!tight || (sub?.isNotEmpty ?? false))
                Text(
                  sub ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.caption,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// An icon and one line of Inter 13 regular, muted: the people, player and
/// court rows of a card.
class PlayCardIconRow extends StatelessWidget {
  const PlayCardIconRow(this.icon, this.text, {super.key});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Row(
      children: [
        OgIcon(icon, size: 18, color: c.textMuted, strokeWidth: 1.8),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.type.caption,
          ),
        ),
      ],
    );
  }
}
