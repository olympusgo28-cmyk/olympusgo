import 'package:flutter/material.dart';

import '../../core/theme/og_colors.dart';
import '../../core/theme/og_type.dart';
import '../../core/widgets/og_icon.dart';
export '../../core/widgets/avatar.dart';

import '../../core/widgets/pressable.dart';

/// A Meet in a list: date eyebrow, name, venue and spots left.
class MeetCard extends StatelessWidget {
  const MeetCard({
    super.key,
    required this.when,
    required this.name,
    required this.venue,
    required this.spots,
    required this.onTap,
  });

  final String when;
  final String name;
  final String venue;
  final String spots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Pressable(
        onPressed: onTap,
        semanticLabel: '$name, $when, $venue, $spots',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(when, style: context.type.caption.copyWith(color: c.link)),
              const SizedBox(height: 2),
              Text(name, style: context.type.section),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(child: Text(venue, style: context.type.secondary)),
                  Text(spots, style: context.type.body),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category row on Discover: tinted icon, title, subtitle, chevron.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.top = 10,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double top;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Pressable(
        onPressed: onTap,
        semanticLabel: '$title. $subtitle',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.primaryTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: OgIcon(icon, color: c.link),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.type.body),
                    Text(subtitle, style: context.type.secondary),
                  ],
                ),
              ),
              OgIcon(
                OgIcons.chevronRight,
                size: 20,
                color: c.text,
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small orange pill button, e.g. "Follow".
class SmallPillButton extends StatelessWidget {
  const SmallPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      onPressed: onPressed,
      haptic: true,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: filled ? null : Border.all(color: c.borderControl, width: 2),
        ),
        child: Text(
          label,
          style: context.type.section.copyWith(
            color: filled ? c.onPrimary : c.text,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
