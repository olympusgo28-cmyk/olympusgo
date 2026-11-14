import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/theme/og_colors.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/og_kit.dart';

/// P0-06: the shared parts, in light and dark. Run with --update-goldens after
/// a deliberate design change.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget sheet(ThemeData theme) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Builder(
      builder: (context) => Scaffold(
        backgroundColor: context.og.bg,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              KitButton(label: 'Join', onPressed: () {}),
              KitButton.outline(label: 'Maybe later', onPressed: () {}),
              const KitButton(label: 'Disabled', onPressed: null),
              const KitNote(
                'Ask a parent to link your account',
                tone: KitTone.warn,
              ),
              const KitNote('Game is on', tone: KitTone.success),
              Row(
                spacing: 8,
                children: [
                  KitChip(label: 'Anyone', selected: true, onTap: () {}),
                  KitChip(label: 'Men', onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  for (final (name, theme) in [
    ('light', OgTheme.light()),
    ('dark', OgTheme.dark()),
  ]) {
    testWidgets('P0-06 shared parts in $name', (tester) async {
      await tester.binding.setSurfaceSize(const Size(402, 440));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(sheet(theme));
      await tester.pump();
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/shared_parts_$name.png'),
      );
    });
  }
}
