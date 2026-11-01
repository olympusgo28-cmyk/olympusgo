import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:og_design/og_design.dart';
import 'package:olympus_admin/core/staff_api.dart';
import 'package:olympus_admin/features/money/money_screens.dart';

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
  Future<String> documentUrl(String path) async => 'https://example.com/$path';

  @override
  Future<void> removeDocument(String path) async {}

  @override
  Future<Object?> act(String action, Map<String, dynamic> params) async {
    acted[action] = params;
    return null;
  }
}

const _overview = {
  'held_minor': 1200,
  'refunds_pending_minor': 800,
  'failed_refunds': 1,
  'open_holds': 1,
  'open_disputes': 0,
  'suspense_minor': 0,
  'open_alerts': 1,
};

Future<void> _pump(WidgetTester tester, _Api api) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [staffApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        theme: OgTheme.light(),
        home: const Scaffold(body: MoneyScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('A-06 shows the money at a glance', (tester) async {
    await _pump(tester, _Api({'staff_money_overview': _overview}));
    expect(find.text('S\$12.00'), findsOneWidget);
    expect(find.text('Refunds pending'), findsOneWidget);
    expect(find.text('No open alerts.'), findsOneWidget);
  });

  testWidgets('A-06 a refused role sees no money', (tester) async {
    await _pump(tester, _Api(const {}, failing: true));
    expect(find.text('Not found.'), findsWidgets);
    expect(find.text('S\$12.00'), findsNothing);
  });

  testWidgets('A-06 a held report can be released, with a reason', (
    tester,
  ) async {
    final api = _Api({
      'staff_money_overview': _overview,
      'staff_held_list': [
        {
          'activity_id': 'a1',
          'title': 'Doubles Social',
          'ends_at': '2026-11-01T10:00:00Z',
          'held_minor': 600,
          'oldest': '2026-10-30T10:00:00Z',
          'hold_id': 'h1',
        },
      ],
    });
    await _pump(tester, api);
    await tester.tap(find.text('Held money'));
    await tester.pumpAndSettle();
    expect(find.textContaining('held by a report'), findsOneWidget);
    await tester.tap(find.text('Release'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Looked at the report');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(api.acted['staff_hold_decide'], {
      'p_activity': 'a1',
      'p_refund_all': false,
      'p_reason': 'Looked at the report',
    });
  });

  testWidgets('A-06 alerts read as sentences, and empty holds stay out', (
    tester,
  ) async {
    await _pump(
      tester,
      _Api({
        'staff_money_overview': _overview,
        'staff_alert_list': [
          {
            'id': 'a1',
            'kind': 'refund_failed',
            'created_at': '2026-11-01T10:00:00Z',
            'detail': {'code': 'card_declined'},
          },
        ],
        'staff_held_list': [
          {
            'activity_id': 'a2',
            'title': 'Refunded Meet',
            'ends_at': '2026-11-01T10:00:00Z',
            'held_minor': 0,
            'oldest': '2026-10-30T10:00:00Z',
            'hold_id': null,
          },
        ],
      }),
    );
    expect(find.text('Refund failed'), findsOneWidget);
    expect(find.textContaining('code: card_declined'), findsOneWidget);
    await tester.tap(find.text('Held money'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Refunded Meet'), findsNothing);
    expect(find.text('Nothing is held.'), findsOneWidget);
  });

  testWidgets('A-06 a run over the limit asks for a second approval', (
    tester,
  ) async {
    await _pump(
      tester,
      _Api({
        'staff_money_overview': _overview,
        'staff_payout_list': [
          {
            'id': 'r1',
            'week_start': '2026-11-02',
            'total_minor': 600000,
            'status': 'prepared',
            'first_approver': 'someone',
            'needs_second': true,
            'items': const [],
          },
        ],
      }),
    );
    await tester.tap(find.text('Payouts'));
    await tester.pumpAndSettle();
    expect(find.text('Second approval'), findsOneWidget);
    expect(find.textContaining('needs a second approver'), findsOneWidget);
  });
}
