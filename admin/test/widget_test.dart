import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:og_design/og_design.dart';
import 'package:olympus_admin/core/ui.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('A-01 a failed read shows a sentence, not a stack trace', (
    tester,
  ) async {
    final failed = Future<int>.error(StateError('secret detail'))..ignore();
    await tester.pumpWidget(
      MaterialApp(
        theme: OgTheme.light(),
        home: Scaffold(
          body: Loaded<int>(future: failed, builder: (_) => const SizedBox()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    expect(find.textContaining('secret detail'), findsNothing);
  });

  testWidgets('A-01 an empty list says so', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OgTheme.light(),
        home: Scaffold(
          body: Loaded<List<int>>(
            future: Future.value(const []),
            isEmpty: (d) => d.isEmpty,
            emptyText: 'No staff actions yet.',
            builder: (_) => const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No staff actions yet.'), findsOneWidget);
  });
}
