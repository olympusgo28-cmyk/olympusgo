import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/og_colors.dart';
import '../../core/theme/og_text.dart';
import '../../core/theme/og_tones.dart';
import '../../core/widgets/og_icon.dart';
import '../../core/widgets/pressable.dart';
import 'application/home_services.dart';

/// One of Your favourites: a card with a line icon, name and what it's for.
class FavouriteCard extends StatelessWidget {
  const FavouriteCard({super.key, required this.service});

  final HomeService service;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final s = service;
    return Pressable(
      semanticLabel: '${s.label}. ${s.sub}',
      onPressed: () => context.push(s.route),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: t.soft,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primaryTint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(s.icon, size: 22, strokeWidth: 1.8, color: c.link),
            ),
            const SizedBox(height: 14),
            Text(
              s.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OgText.body(16, weight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              s.sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OgText.body(12, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Your favourites as a 2 × 2 grid.
class FavouriteGrid extends StatelessWidget {
  const FavouriteGrid({super.key, required this.services});

  final List<HomeService> services;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < services.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = row; i < row + 2; i++) ...[
                  if (i > row) const SizedBox(width: 12),
                  Expanded(
                    child: i < services.length
                        ? FavouriteCard(service: services[i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A service in More services: a line icon on a circle, its name below.
class ServiceCircle extends StatelessWidget {
  const ServiceCircle({super.key, required this.service});

  final HomeService service;

  static const width = 72.0;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final s = service;
    return Pressable(
      semanticLabel: s.label,
      onPressed: () => context.push(s.route),
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: t.soft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: OgIcon(s.icon, size: 24, strokeWidth: 1.7, color: c.text),
            ),
            const SizedBox(height: 8),
            Text(
              s.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: OgText.body(12, weight: FontWeight.w600, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
