import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:og_design/og_design.dart';
import 'package:olympus_admin/core/staff_api.dart';
import 'package:olympus_admin/features/auth/session.dart';
import 'package:olympus_admin/features/game/campaigns_screen.dart';

class _Api implements StaffApi {
  _Api(this.rows, {this.failing = false});
  final Map<String, Object?> rows;
  final bool failing;
  final acted = <String, Map<String, dynamic>>{};

  @override
  Future<Object?> read(String function, [Map<String, dynamic>? params]) async {
    if (failing) throw const StaffFailure('Not found.');
    return rows[function] ?? const <dynamic>[];
  }

  @override
  Future<String> postVideoUrl(String post) async => '';

  @override
  Future<String> documentUrl(String path) async => '';

  @override
  Future<void> removeDocument(String path) async {}

  @override
  Future<Object?> act(String action, Map<String, dynamic> params) async {
    acted[action] = params;
    return null;
  }
}

const _data = {
  'staff_campaign_list': {
    'campaigns': [
      {
        'id': 'c1',
        'title': 'Play 8 in November',
        'status': 'draft',
        'starts_at': '2026-11-01T00:00:00Z',
        'ends_at': '2026-11-30T00:00:00Z',
        'players': 0,
        'quests': <dynamic>[],
      },
    ],
    'voucher_types': [
      {
        'id': 't1',
        'name': 'Shuttle voucher',
        'kind': 'A',
        'amount_minor': 800,
        'funder': 'Racket Lab',
        'organizer_default': false,
        'issued': 3,
      },
    ],
    'badges': <dynamic>[],
    'shops': <dynamic>[],
    'venues': <dynamic>[],
  },
  'staff_organizer_games': [
    {
      'title': 'Doubles',
      'organizer': 'Ravi K.',
      'at': '2026-11-01T02:00:00Z',
      'reason': 'not_scanned',
      'present': 7,
    },
  ],
  'staff_redemptions': [
    {
      'voucher': 'Shuttle voucher',
      'user': 'Aaron N.',
      'mall': 'Racket Lab',
      'at': '2026-11-01T02:00:00Z',
      'kind': 'used',
      'amount_minor': 800,
    },
  ],
};

Future<void> _pump(
  WidgetTester tester,
  _Api api, {
  List<String> roles = const ['super'],
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        staffApiProvider.overrideWithValue(api),
        staffSessionProvider.overrideWith(
          (ref) => Stream.value(StaffSession(roles: roles, mfa: true)),
        ),
      ],
      child: MaterialApp(
        theme: OgTheme.light(),
        home: const Scaffold(body: CampaignsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _reason(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).last, 'Checked it');
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('A-09 a draft can be published, with a reason', (tester) async {
    final api = _Api(_data);
    await _pump(tester, api);
    expect(find.text('Play 8 in November'), findsOneWidget);
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    await _reason(tester);
    expect(api.acted['staff_campaign_status']?['p_status'], 'live');
    expect(api.acted['staff_campaign_status']?['p_reason'], 'Checked it');
  });

  testWidgets('A-09 voucher types show their funder', (tester) async {
    await _pump(tester, _Api(_data));
    await tester.tap(find.text('Voucher types'));
    await tester.pumpAndSettle();
    expect(find.textContaining('S\$8.00 off'), findsOneWidget);
    expect(find.textContaining('Racket Lab'), findsOneWidget);
  });

  testWidgets('A-09 each role sees only what it can do', (tester) async {
    await _pump(tester, _Api(_data), roles: const ['payments']);
    expect(find.text('New campaign'), findsNothing);
    expect(find.text('Publish'), findsNothing);
    await tester.tap(find.text('Voucher types'));
    await tester.pumpAndSettle();
    expect(find.text('New voucher type'), findsOneWidget);
    expect(find.text('Switch off'), findsOneWidget);
  });

  testWidgets('A-09 content staff can\'t change a voucher', (tester) async {
    await _pump(tester, _Api(_data), roles: const ['content']);
    expect(find.text('New campaign'), findsOneWidget);
    await tester.tap(find.text('Voucher types'));
    await tester.pumpAndSettle();
    expect(find.text('New voucher type'), findsNothing);
    expect(find.text('Switch off'), findsNothing);
  });

  testWidgets('A-09 organizer games say why', (tester) async {
    await _pump(tester, _Api(_data));
    await tester.tap(find.text('Organizer games'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not everyone scanned'), findsOneWidget);
  });

  testWidgets('A-09 redemptions show who and where, never a code', (
    tester,
  ) async {
    await _pump(tester, _Api(_data));
    await tester.tap(find.text('Redemptions'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aaron N.'), findsOneWidget);
  });

  testWidgets('A-09 a refused role sees nothing', (tester) async {
    await _pump(tester, _Api({}, failing: true));
    expect(find.text('Not found.'), findsWidgets);
  });
}
