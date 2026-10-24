import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/play/presentation/play_screen.dart';

/// The level range slider moves its ends by dragging, not just tapping.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('dragging moves the nearer end', (tester) async {
    var range = (3, 5);
    await tester.pumpWidget(
      MaterialApp(
        theme: OgTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 400,
              child: BandRangePicker(
                lo: range.$1,
                hi: range.$2,
                onChanged: (lo, hi) => setState(() => range = (lo, hi)),
              ),
            ),
          ),
        ),
      ),
    );
    final pro = tester.getCenter(find.text('PRO'));
    final hi = tester.getCenter(find.text('HI'));
    final lb = tester.getCenter(find.text('LB'));

    // From the high end (HI) to PRO.
    await tester.dragFrom(Offset(hi.dx, hi.dy - 30), Offset(pro.dx - hi.dx, 0));
    await tester.pump();
    expect(range, (3, 7));

    // From the low end (LI) down to LB.
    final li = tester.getCenter(find.text('LI'));
    await tester.dragFrom(Offset(li.dx, li.dy - 30), Offset(lb.dx - li.dx, 0));
    await tester.pump();
    expect(range, (0, 7));
  });
}
