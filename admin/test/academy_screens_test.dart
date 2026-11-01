import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:og_design/og_design.dart';
import 'package:olympus_admin/core/staff_api.dart';
import 'package:olympus_admin/features/academy/lessons_screen.dart';
import 'package:olympus_admin/features/academy/services_screen.dart';
import 'package:olympus_admin/features/academy/verification_screen.dart';

class _Api implements StaffApi {
  _Api(this.rows, {this.failing = false});
  final Map<String, Object?> rows;
  final bool failing;
  final acted = <String, Map<String, dynamic>>{};
  final removed = <String>[];

  @override
  Future<Object?> read(String function, [Map<String, dynamic>? params]) async {
    if (failing) throw const StaffFailure('Not found.');
    return rows[function] ?? const <dynamic>[];
  }

  @override
  Future<String> postVideoUrl(String post) async => '';

  @override
  Future<String> documentUrl(String path) async => 'https://example.com/$path';

  @override
  Future<void> removeDocument(String path) async => removed.add(path);

  @override
  Future<Object?> act(String action, Map<String, dynamic> params) async {
    acted[action] = params;
    return null;
  }
}

Future<void> _pump(WidgetTester tester, _Api api, Widget screen) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [staffApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        theme: OgTheme.light(),
        home: Scaffold(body: screen),
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

const _verification = {
  'staff_verification_list': {
    'academies': [
      {
        'id': 'a1',
        'name': 'Smash Academy',
        'uen': '201912345A',
        'verification': 'submitted',
        'file_path': 'u/doc.jpg',
        'head_licensed': true,
        'payout_ready': true,
      },
    ],
    'licences': [
      {
        'user_id': 'u1',
        'name': 'Coach Ravi',
        'nroc_number': 'NROC-1',
        'expires_on': '2027-01-01',
        'status': 'submitted',
        'file_path': 'u/lic.jpg',
      },
    ],
  },
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('verifying an academy deletes its file', (tester) async {
    final api = _Api(_verification);
    await _pump(tester, api, const VerificationScreen());
    expect(find.text('Smash Academy'), findsOneWidget);
    await tester.tap(find.text('Verify').first);
    await tester.pumpAndSettle();
    await _reason(tester);
    expect(api.acted['staff_academy_decide']?['p_approve'], true);
    expect(api.removed, ['u/doc.jpg']);
    expect(api.acted['staff_doc_removed']?['p_kind'], 'academy');
  });

  testWidgets('rejecting a licence sends the reason', (tester) async {
    final api = _Api(_verification);
    await _pump(tester, api, const VerificationScreen());
    await tester.tap(find.text('Reject').last);
    await tester.pumpAndSettle();
    await _reason(tester);
    expect(api.acted['staff_licence_decide']?['p_approve'], false);
    expect(api.acted['staff_licence_decide']?['p_reason'], 'Checked it');
  });

  testWidgets('a role that can’t see it gets the refusal', (tester) async {
    await _pump(tester, _Api({}, failing: true), const VerificationScreen());
    expect(find.text('Not found.'), findsOneWidget);
  });

  testWidgets('a reported lesson can go either way', (tester) async {
    final api = _Api({
      'staff_lesson_list': [
        {
          'id': 'l1',
          'title': 'One-to-one · Ravi',
          'academy': 'Smash Academy',
          'amount_minor': 5500,
          'step': 'reported',
          'starts_at': '2026-11-01T02:00:00Z',
          'report_note': 'No coach came',
        },
      ],
    });
    await _pump(tester, api, const LessonsScreen());
    expect(find.textContaining('S\$55.00'), findsOneWidget);
    expect(find.text('Pay academy'), findsOneWidget);
    await tester.tap(find.text('Refund'));
    await tester.pumpAndSettle();
    await _reason(tester);
    expect(api.acted['staff_lesson_decide']?['p_refund'], true);
  });

  testWidgets('a released lesson can only be refunded', (tester) async {
    await _pump(
      tester,
      _Api({
        'staff_lesson_list': [
          {
            'id': 'l1',
            'title': 'Trial',
            'academy': 'Smash',
            'amount_minor': 1700,
            'step': 'released',
            'starts_at': '2026-11-01T02:00:00Z',
          },
        ],
      }),
      const LessonsScreen(),
    );
    expect(find.text('Pay academy'), findsNothing);
    expect(find.text('Refund'), findsOneWidget);
  });

  testWidgets('partners show counts, never names', (tester) async {
    final api = _Api({
      'staff_service_list': [
        {
          'id': 'p1',
          'name': 'Rally Physio',
          'area': 'Bishan',
          'blurb': '',
          'booking_url': 'https://x.example',
          'ref_code': 'OLY',
          'active': true,
          'referrals': 3,
        },
      ],
    });
    await _pump(tester, api, const ServicesScreen());
    expect(find.textContaining('3 referrals'), findsOneWidget);
    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();
    await _reason(tester);
    expect((api.acted['staff_service_save']?['p'] as Map)['active'], false);
  });
}
