// Audit S3 (Q269): when the server refuses a report, the app shows its plain
// message instead of "Something went wrong". The player-report path is
// proven through the real API in test/supabase_report_local_test.dart.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/clubs/data/club_repository.dart';
import 'package:olympus_go/features/clubs/data/supabase_club_repository.dart';
import 'package:olympus_go/features/clubs/domain/club_models.dart';
import 'package:olympus_go/features/play/data/play_repository.dart';
import 'package:olympus_go/features/shop/data/shop_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _limit = "You've sent a lot of reports. Try again in an hour.";
const _refused = "This can't be reported.";

/// A client whose every request is refused with [message], as the database
/// raises it.
SupabaseClient _refusing(String message) => SupabaseClient(
  'http://127.0.0.1:1',
  'test-key',
  httpClient: MockClient(
    (request) async => http.Response(
      jsonEncode({'code': 'P0001', 'message': message}),
      400,
      headers: {'content-type': 'application/json'},
      request: request,
    ),
  ),
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

Matcher _failsWith(String message) =>
    throwsA(isA<AuthFailure>().having((e) => e.message, 'message', message));

void main() {
  for (final message in [_refused, _limit]) {
    test('a club report shows "$message"', () async {
      final client = _refusing(message);
      final repo = SupabaseClubRepository(
        client,
        SupabasePlayRepository(client),
      );
      await expectLater(
        repo.report(
          const ReportTarget.club('c1'),
          ContentReport.harassment,
          '',
        ),
        _failsWith(message),
      );
    });

    test('a shop report shows "$message"', () async {
      final repo = SupabaseShopRepository(_refusing(message));
      await expectLater(repo.report('p1', reason: 'spam'), _failsWith(message));
    });
  }
}
