import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/og_colors.dart';
import '../../../../core/widgets/og_icon.dart';
import '../../../../core/widgets/og_kit.dart';
import '../../../../core/widgets/og_toast.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../social/application/social_providers.dart';
import '../../../social/domain/social_models.dart';
import '../../domain/activity.dart';

/// The heart that saves a Meet, tournament or event. Plain on a card with no
/// banner, frosted on a banner.
class PlayCardSaveButton extends ConsumerWidget {
  const PlayCardSaveButton({
    super.key,
    required this.activity,
    this.glass = false,
    this.onLight = false,
  });

  final Activity activity;

  /// A frosted round button for the banner of tournaments and events.
  final bool glass;

  /// The banner behind a glass button is light: its fill is near-black rather
  /// than white. The heart is white either way.
  final bool onLight;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    try {
      final now = await ref
          .read(savedIdsProvider(SavedKind.meet).notifier)
          .toggle(activity.id);
      if (context.mounted) {
        showOgToast(context, now ? 'Saved' : 'Removed from saved');
      }
    } on AuthFailure catch (e) {
      if (context.mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final saved =
        ref
            .watch(savedIdsProvider(SavedKind.meet))
            .value
            ?.contains(activity.id) ??
        false;
    final label = saved
        ? 'Remove ${activity.title} from saved'
        : 'Save ${activity.title}';
    if (!glass) {
      return KitIconButton(
        icon: OgIcons.heart,
        label: label,
        size: 22,
        strokeWidth: 1.8,
        color: saved ? c.primary : c.textMuted,
        fill: saved,
        onPressed: () => _toggle(context, ref),
      );
    }
    // Two tones for the fill only: white on a dark banner, near-black on a
    // light one. The edge is the fill (no separate line) and the heart is
    // always white (owner, 15 Nov 2026).
    final fill = (onLight ? OgColors.ink : Colors.white).withValues(
      alpha: onLight ? 0.10 : 0.22,
    );
    return Pressable(
      semanticLabel: label,
      selected: saved,
      onPressed: () => _toggle(context, ref),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: OgIcon(
                  OgIcons.heart,
                  size: 20,
                  strokeWidth: 2,
                  color: Colors.white,
                  fill: saved,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
