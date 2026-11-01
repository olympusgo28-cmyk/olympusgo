import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:og_design/og_design.dart';
import 'package:olympus_admin/core/staff_api.dart';
import 'package:olympus_admin/features/shop/catalogue_screen.dart';
import 'package:olympus_admin/features/shop/orders_screen.dart';

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
  Future<String> documentUrl(String path) async => 'https://example.com/$path';

  @override
  Future<void> removeDocument(String path) async {}

  @override
  Future<Object?> act(String action, Map<String, dynamic> params) async {
    acted[action] = params;
    return null;
  }
}

const _shop = {
  'id': 's1',
  'name': 'Racket Lab',
  'active': true,
  'collect_address': '1 Test Road',
  'blurb': '',
  'commission_on_top': false,
  'owner': 'ravi',
  'products': 2,
};

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

Future<void> _giveReason(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).last, 'Checked with the shop');
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('A-07 lists shops, and stock moves by an amount', (tester) async {
    final api = _Api({
      'staff_shop_list': [_shop],
      'staff_product_list': [
        {
          'id': 'p1',
          'name': 'Grip',
          'price_cents': 900,
          'service': false,
          'stock': 4,
          'published': true,
          'hidden': false,
        },
      ],
    });
    await _pump(tester, api, const CatalogueScreen());
    expect(find.text('Racket Lab'), findsOneWidget);
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    expect(find.textContaining('S\$9.00'), findsOneWidget);

    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '-2');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await _giveReason(tester);
    expect(api.acted['staff_product_stock'], {
      'p_product': 'p1',
      'p_change': -2,
      'p_reason': 'Checked with the shop',
    });
  });

  testWidgets('A-07 a price becomes cents, not a double', (tester) async {
    final api = _Api({
      'staff_shop_list': [_shop],
    });
    await _pump(tester, api, const CatalogueScreen());
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a product'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Shuttles');
    await tester.enterText(fields.at(2), '12.1.5');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount, like 24.50'), findsOneWidget);
    await tester.enterText(fields.at(2), '24.50');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await _giveReason(tester);
    final p = api.acted['staff_product_save']!['p'] as Map;
    expect(p['price_cents'], 2450);
    expect(p['mall_id'], 's1');
  });

  testWidgets('A-07 a report is decided by line, with a reason', (
    tester,
  ) async {
    final api = _Api({
      'staff_order_list': [
        {
          'id': 'o1',
          'step': 'reported',
          'mall': 'Racket Lab',
          'placed_at': '2026-11-01T10:00:00Z',
          'report_note': 'Wrong size',
          'amount_minor': 2000,
        },
      ],
      'staff_order_get': {
        'id': 'o1',
        'step': 'reported',
        'mall_name': 'Racket Lab',
        'report_note': 'Wrong size',
        'service': false,
        'lines': [
          {
            'id': 'l1',
            'name': 'Shoe',
            'qty': 2,
            'refunded_qty': 0,
            'unit_paid': 1000,
          },
        ],
      },
    });
    await _pump(tester, api, const OrdersScreen());
    await tester.tap(find.text('Decide'));
    await tester.pumpAndSettle();
    expect(find.text('Release to the shop'), findsOneWidget);
    await tester.tap(find.byTooltip('Refund one more'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refund these items'));
    await tester.pumpAndSettle();
    await _giveReason(tester);
    expect(api.acted['staff_order_decide']?['p_lines'], [
      {'line': 'l1', 'qty': 1},
    ]);
    expect(api.acted['staff_order_decide']?['p_key'], isA<String>());
  });

  testWidgets('A-07 a refused role sees nothing', (tester) async {
    await _pump(tester, _Api(const {}, failing: true), const OrdersScreen());
    expect(find.text('Not found.'), findsWidgets);
    expect(find.text('Racket Lab'), findsNothing);
  });
}
