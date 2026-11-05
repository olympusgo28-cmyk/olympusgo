import 'package:flutter/material.dart';

import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_kit.dart';

/// A category with nothing in it yet. The tile still opens something, so the
/// page says plainly what is coming.
class EmptyCategoryScreen extends StatelessWidget {
  const EmptyCategoryScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => KitScaffold(
    header: KitHeader(title: title),
    children: [
      DashedBox(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(message, style: OgText.lead(context.og.textMuted)),
        ),
      ),
    ],
  );
}
