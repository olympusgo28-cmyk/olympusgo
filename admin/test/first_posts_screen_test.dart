import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:og_design/og_design.dart';
import 'package:olympus_admin/core/staff_api.dart';
import 'package:olympus_admin/features/posts/first_posts_screen.dart';

class _Api implements StaffApi {
  _Api({this.rows = const [], this.refuse = false});
  List<Map<String, Object?>> rows;
  final bool refuse;
  final acted = <String, Map<String, dynamic>>{};
  final asked = <String>[];

  @override
  Future<Object?> read(String function, [Map<String, dynamic>? params]) async =>
      rows;

  @override
  Future<String> postVideoUrl(String post) async {
    asked.add(post);
    if (refuse) throw const StaffFailure('This video can\'t be played.');
    return 'http://local/$post.mp4';
  }

  @override
  Future<String> documentUrl(String path) async => '';

  @override
  Future<void> removeDocument(String path) async {}

  @override
  Future<Object?> act(String action, Map<String, dynamic> params) async {
    acted[action] = params;
    rows = [];
    return null;
  }
}

const _row = {
  'id': 'p1',
  'caption': 'Smash practice',
  'sport': 'badminton',
  'seconds': 60,
  'flagged': true,
  'created_at': '2026-11-02T08:00:00Z',
  'deadline_at': '2026-11-03T08:00:00Z',
};

Future<void> _pump(WidgetTester tester, _Api api) async {
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [staffApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        theme: OgTheme.light(),
        home: const Scaffold(body: FirstPostsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a post shows its caption, not its person', (tester) async {
    await _pump(tester, _Api(rows: [_row]));
    expect(find.text('Smash practice'), findsOneWidget);
    expect(find.text('The automatic check flagged this.'), findsOneWidget);
    expect(find.textContaining('author'), findsNothing);
  });

  testWidgets('an empty queue says so', (tester) async {
    await _pump(tester, _Api());
    expect(find.text('No posts are waiting.'), findsOneWidget);
  });

  testWidgets('approving needs a reason', (tester) async {
    final api = _Api(rows: [_row]);
    await _pump(tester, api);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fine');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(api.acted['staff_post_decide'], {
      'p_post': 'p1',
      'p_outcome': 'live',
      'p_reason': 'Fine',
    });
    expect(find.text('No posts are waiting.'), findsOneWidget);
  });

  testWidgets('rejecting says which', (tester) async {
    final api = _Api(rows: [_row]);
    await _pump(tester, api);
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Not sport');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(api.acted['staff_post_decide']!['p_outcome'], 'rejected');
  });

  testWidgets('a refused video shows why', (tester) async {
    final api = _Api(rows: [_row], refuse: true);
    await _pump(tester, api);
    await tester.tap(find.text('Play video'));
    await tester.pumpAndSettle();
    expect(api.asked, ['p1']);
    expect(find.text('This video can\'t be played.'), findsOneWidget);
  });
}
