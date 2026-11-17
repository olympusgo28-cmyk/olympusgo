import 'package:flutter/material.dart';

import '../../../../core/theme/og_tones.dart';
import '../../../../core/theme/og_type.dart';
import '../../../../core/widgets/og_kit.dart';
import '../../domain/activity.dart';

/// The "who is going" line: a 28-point avatar, 8 points, then the sentence in
/// Inter 13 regular (the name muted, the rest a darker grey).
class PlayCardProof extends StatelessWidget {
  const PlayCardProof(this.proof, {super.key});

  final SocialProof proof;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SolidAvatar(
          initials: proof.mark,
          color: Color(proof.color),
          ink: Color(proof.ink),
          size: 28,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: proof.name, style: context.type.caption),
                TextSpan(text: ' ${proof.text}'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.type.caption.copyWith(color: context.tones.onTag),
          ),
        ),
      ],
    );
  }
}

/// The last row of a card, 12 points under the one above: the friend row, 28
/// points tall. On Home it is left out when no friend is going; elsewhere an
/// empty strip keeps every card in a row the same height.
class PlayCardFriendRow extends StatelessWidget {
  const PlayCardFriendRow({
    super.key,
    required this.proof,
    required this.onHome,
  });

  final SocialProof? proof;
  final bool onHome;

  @override
  Widget build(BuildContext context) {
    if (onHome && proof == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 28,
        child: proof == null ? null : PlayCardProof(proof!),
      ),
    );
  }
}

/// A Meet's "is going" reads "joined" (owner, 15 Nov 2026).
SocialProof playCardJoined(SocialProof proof) => proof.copyWith(
  text: proof.text.replaceFirst(RegExp(r'(is|are) going$'), 'joined'),
);
