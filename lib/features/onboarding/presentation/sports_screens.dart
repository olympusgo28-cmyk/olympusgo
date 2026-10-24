import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/cupertino_sheets.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/pressable.dart';
import '../application/onboarding_controller.dart';
import '../domain/onboarding_models.dart';
import '../domain/sport.dart';

/// Step 3: pick every sport you play or want to try.
class SportsScreen extends ConsumerWidget {
  const SportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(
      onboardingControllerProvider.select((d) => d.sports),
    );
    return OgFlowScreen(
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Pick your sports',
          step: 3,
          topGap: 16,
          lead: 'Choose every sport you play or want to try. You can change this later.',
        ),
        const SizedBox(height: 20),
        // Two columns of 84px tiles. Plain rows rather than a GridView so the
        // screen can measure its height and scroll under large text sizes.
        for (var i = 0; i < Sport.signUp.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final sport in Sport.signUp.skip(i).take(2)) ...[
                  if (sport != Sport.signUp[i]) const SizedBox(width: 10),
                  Expanded(
                    child: _SportTile(
                      sport: sport,
                      selected: chosen.contains(sport),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(onboardingControllerProvider.notifier)
                            .toggleSport(sport);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
      bottom: [
        OgButton(
          label: 'Continue',
          onPressed: chosen.isEmpty ? null : () => context.push(Routes.skills),
        ),
      ],
    );
  }
}

class _SportTile extends StatelessWidget {
  const _SportTile({
    required this.sport,
    required this.selected,
    required this.onTap,
  });

  final Sport sport;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Semantics(
      button: true,
      toggled: selected,
      label: sport.label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected ? c.primaryTint : c.surfaceRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? c.primary : c.borderControl,
              width: selected ? 3 : 2,
            ),
          ),
          child: ExcludeSemantics(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OgIcon(
                        sport.icon,
                        size: 34,
                        strokeWidth: 1.8,
                        color: selected ? c.link : c.text,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sport.label,
                        style: OgText.body(
                          16,
                          weight: FontWeight.w600,
                          color: c.text,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: OgIcon(
                        OgIcons.check,
                        size: 12,
                        color: c.onPrimary,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Orange circle holding a white sport icon.
class SportBadge extends StatelessWidget {
  const SportBadge(this.sport, {super.key, this.size = 52});

  final Sport sport;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: OgColors.tangerine,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: OgIcon(
        sport.icon,
        size: size * 0.54,
        color: OgColors.white,
        strokeWidth: 1.8,
      ),
    );
  }
}

/// Step 4: one row per chosen sport; tap to set level and play range.
class SkillLevelScreen extends ConsumerWidget {
  const SkillLevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final draft = ref.watch(onboardingControllerProvider);
    return OgFlowScreen(
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Set your skill levels',
          step: 4,
          topGap: 16,
          lead: 'Tap a sport to set your level and who you like to play with.',
        ),
        const SizedBox(height: 24),
        for (final sport in draft.sports) ...[
          Pressable(
            onPressed: () => context.push(Routes.skill(sport.id)),
            semanticLabel:
                '${sport.label}, ${draft.skillFor(sport).summary}. Edit',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: c.surfaceRaised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.borderControl, width: 2),
              ),
              child: Row(
                children: [
                  SportBadge(sport),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sport.label,
                          style: OgText.display(20, height: 1.2, color: c.text),
                        ),
                        Text(
                          draft.skillFor(sport).summary,
                          style: OgText.body(
                            15,
                            height: 1.4,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OgIcon(
                    OgIcons.chevronRight,
                    size: 22,
                    color: c.text,
                    strokeWidth: 2.5,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
      bottom: [
        OgButton(
          label: 'Continue',
          onPressed: () => context.push(Routes.username),
        ),
      ],
    );
  }
}

/// Level and "play with" range for one sport.
class SportSkillScreen extends ConsumerStatefulWidget {
  const SportSkillScreen({super.key, required this.sport});

  final Sport sport;

  @override
  ConsumerState<SportSkillScreen> createState() => _SportSkillScreenState();
}

class _SportSkillScreenState extends ConsumerState<SportSkillScreen> {
  late SportSkill _skill = ref
      .read(onboardingControllerProvider)
      .skillFor(widget.sport);

  Future<void> _pickLevel() async {
    final picked = await showOgListPicker<double>(
      context: context,
      title: 'Your skill level',
      items: SkillScale.levels,
      selected: _skill.level,
      label: SkillScale.describe,
    );
    if (picked != null) setState(() => _skill = _skill.copyWith(level: picked));
  }

  void _save() {
    ref.read(onboardingControllerProvider.notifier).setSkill(_skill);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    Widget end(String label, double value, CrossAxisAlignment align) => Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: OgText.body(14, color: c.textMuted)),
        Text(
          value.toStringAsFixed(1),
          style: OgText.display(24, height: 1.1, color: c.text),
        ),
      ],
    );
    return OgFlowScreen(
      children: [
        const OgBackButton(),
        OgHeading(
          title: widget.sport.label,
          topGap: 16,
          leading: SportBadge(widget.sport),
        ),
        const SizedBox(height: 12),
        const StepProgress(step: 4),
        const SizedBox(height: 28),
        Text('Your skill level', style: OgText.label),
        const SizedBox(height: 8),
        OgSelectField(
          value: SkillScale.describe(_skill.level),
          semanticLabel: 'Your skill level',
          onTap: _pickLevel,
        ),
        const SizedBox(height: 8),
        Text(
          'A starting point. It adjusts after your first few ranked matches.',
          style: OgText.body(14, height: 1.4, color: c.textMuted),
        ),
        const SizedBox(height: 28),
        Text('Play with levels', style: OgText.label),
        const SizedBox(height: 14),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            activeTrackColor: c.primary,
            inactiveTrackColor: c.border,
            overlayShape: SliderComponentShape.noOverlay,
            rangeThumbShape: _RingThumb(fill: c.surfaceRaised, ring: c.primary),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            showValueIndicator: ShowValueIndicator.never,
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
            padding: EdgeInsets.zero,
          ),
          child: SizedBox(
            height: 28,
            child: RangeSlider(
              min: SkillScale.min,
              max: SkillScale.max,
              divisions: 7,
              values: RangeValues(_skill.playMin, _skill.playMax),
              semanticFormatterCallback: (v) => v.toStringAsFixed(1),
              onChanged: (v) {
                if (v.start != _skill.playMin || v.end != _skill.playMax) {
                  HapticFeedback.selectionClick();
                }
                setState(
                  () => _skill = _skill.copyWith(
                    playMin: v.start,
                    playMax: v.end,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            end('Min', _skill.playMin, CrossAxisAlignment.start),
            end('Max', _skill.playMax, CrossAxisAlignment.end),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'We suggest Meets and partners inside this range.',
          style: OgText.body(14, height: 1.4, color: c.textMuted),
        ),
      ],
      bottom: [OgButton(label: 'Save', onPressed: _save)],
    );
  }
}

/// 28px white thumb with a 3px orange ring, as in the design.
class _RingThumb extends RangeSliderThumbShape {
  const _RingThumb({required this.fill, required this.ring});

  final Color fill;
  final Color ring;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(28, 28);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final canvas = context.canvas;
    final scale = 1 + 0.1 * activationAnimation.value;
    canvas.drawCircle(
      center + const Offset(0, 1),
      14 * scale,
      Paint()
        ..color = const Color(0x331C1F23)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(center, 14 * scale, Paint()..color = fill);
    canvas.drawCircle(
      center,
      12.5 * scale,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}
