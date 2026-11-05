import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:og_design/og_design.dart';
import 'package:olympus_admin/core/staff_api.dart';
import 'package:olympus_admin/features/analysis/analysis_screen.dart';

class _Api implements StaffApi {
  _Api({this.failing = false});
  final bool failing;
  final acted = <String, Map<String, dynamic>>{};

  @override
  Future<Object?> read(String function, [Map<String, dynamic>? params]) async {
    if (failing) throw const StaffFailure('Not found.');
    return {
      'queued': 2,
      'running': 1,
      'done_24h': 14,
      'failed_24h': 1,
      'clips_held': 30,
      'storage_bytes': 3221225472,
      'files_waiting': 0,
      'files_overdue': 0,
      'cost_cents_30d': 1250,
      'failures': [
        {
          'id': 'j1',
          'kind': 'analyse',
          'error_code': 'timeout',
          'attempts': 2,
          'at': '2026-11-02T08:00:00Z',
        },
      ],
    };
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

Future<void> _pump(WidgetTester tester, _Api api) async {
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [staffApiProvider.overrideWithValue(api)],
      child: MaterialApp(
        theme: OgTheme.light(),
        home: const Scaffold(body: AnalysisScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows the queue, failures, storage and cost', (tester) async {
    await _pump(tester, _Api());
    expect(find.text('In the queue'), findsOne);
    expect(find.text('3.0 GB'), findsOne);
    expect(find.text('S\$12.50'), findsOne);
    expect(find.textContaining('Timed out'), findsOne);
  });

  testWidgets('retrying asks for a reason', (tester) async {
    final api = _Api();
    await _pump(tester, api);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Worker restarted');
    await tester.pumpAndSettle();
    final buttons = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    );
    await tester.tap(buttons.first);
    await tester.pumpAndSettle();
    expect(api.acted['staff_analysis_retry']?['p_job'], 'j1');
    expect(api.acted['staff_analysis_retry']?['p_reason'], 'Worker restarted');
  });

  testWidgets('a role without access sees the error', (tester) async {
    await _pump(tester, _Api(failing: true));
    expect(find.textContaining('Not found'), findsOne);
  });
}
