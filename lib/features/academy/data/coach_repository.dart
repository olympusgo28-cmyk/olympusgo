import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../../play/domain/meet_ops.dart' show newClientKey;
import '../domain/lesson_models.dart';

/// Coach pages, licences and academy verification.
abstract class CoachRepository {
  Future<CoachProfile> profile(String userId);
  Future<CoachLicence> myLicence();
  Future<void> saveProfile({
    required String headline,
    required String bio,
    int? years,
  });

  /// Uploads a photo of a document and returns where it went.
  Future<String> uploadDocument(Uint8List bytes, String contentType);
  Future<void> submitLicence({
    required String number,
    required DateTime expires,
    required String path,
  });
  Future<void> submitBusiness(
    String academyId, {
    required String uen,
    required String path,
  });
  Future<AcademyChecklist> checklist(String academyId);

  /// Academies that have asked this person to coach: (id, name).
  Future<List<(String, String)>> coachInvites();
  Future<void> answerInvite(String academyId, {required bool accept});
}

class SupabaseCoachRepository implements CoachRepository {
  SupabaseCoachRepository(this._client);
  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Coach error: ${e.code}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on StorageException {
      debugPrint('Coach upload error');
      throw const AuthFailure('We couldn\'t upload that. Try a smaller photo.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Coach network error');
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  Map<String, dynamic> _map(dynamic r) => (r as Map).cast<String, dynamic>();

  @override
  Future<CoachProfile> profile(String userId) => _guard(() async {
    final r = _map(
      await _client.rpc('coach_profile_get', params: {'p_user': userId}),
    );
    return CoachProfile(
      id: r['id'] as String,
      name: r['name'] as String? ?? 'Coach',
      headline: r['headline'] as String? ?? '',
      bio: r['bio'] as String? ?? '',
      yearsCoaching: r['years_coaching'] as int?,
      academies: [
        for (final a in (r['academies'] as List? ?? const []).cast<Map>())
          (
            a['id'] as String,
            a['name'] as String? ?? '',
            a['role'] as String? ?? 'Coach',
          ),
      ],
    );
  });

  @override
  Future<CoachLicence> myLicence() => _guard(() async {
    final r = _map(await _client.rpc('coach_licence_my'));
    return CoachLicence(
      status: r['status'] as String? ?? 'none',
      number: r['nroc_number'] as String?,
      expiresOn: r['expires_on'] == null
          ? null
          : DateTime.parse(r['expires_on'] as String),
      rejectedReason: r['rejected_reason'] as String?,
      current: r['current'] as bool? ?? false,
      headline: r['headline'] as String? ?? '',
      bio: r['bio'] as String? ?? '',
      yearsCoaching: r['years_coaching'] as int?,
    );
  });

  @override
  Future<void> saveProfile({
    required String headline,
    required String bio,
    int? years,
  }) => _guard(() async {
    await _client.rpc(
      'coach_profile_save',
      params: {'p_headline': headline, 'p_bio': bio, 'p_years': years},
    );
  });

  @override
  Future<String> uploadDocument(Uint8List bytes, String contentType) =>
      _guard(() async {
        final me = _client.auth.currentUser?.id;
        if (me == null) throw const AuthFailure('Sign in first.');
        final ext = contentType == 'application/pdf' ? 'pdf' : 'jpg';
        final path = '$me/${newClientKey()}.$ext';
        await _client.storage
            .from('verification-docs')
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: contentType),
            );
        return path;
      });

  @override
  Future<void> submitLicence({
    required String number,
    required DateTime expires,
    required String path,
  }) => _guard(() async {
    await _client.rpc(
      'coach_licence_submit',
      params: {
        'p_number': number,
        'p_expires': expires.toIso8601String().substring(0, 10),
        'p_path': path,
      },
    );
  });

  @override
  Future<void> submitBusiness(
    String academyId, {
    required String uen,
    required String path,
  }) => _guard(() async {
    await _client.rpc(
      'academy_submit_business',
      params: {'p_academy': academyId, 'p_uen': uen, 'p_path': path},
    );
  });

  @override
  Future<AcademyChecklist> checklist(String academyId) => _guard(() async {
    final r = _map(
      await _client.rpc(
        'academy_verification',
        params: {'p_academy': academyId},
      ),
    );
    return AcademyChecklist(
      verification: r['verification'] as String? ?? 'none',
      uen: r['uen'] as String?,
      rejectedReason: r['rejected_reason'] as String?,
      payoutReady: r['payout_ready'] as bool? ?? false,
      isOwner: r['is_owner'] as bool? ?? false,
      coaches: [
        for (final k in (r['coaches'] as List? ?? const []).cast<Map>())
          ChecklistCoach(
            name: k['name'] as String? ?? 'Coach',
            head: k['head'] as bool? ?? false,
            accepted: k['accepted'] as bool? ?? false,
            licence: k['licence'] as String? ?? 'none',
          ),
      ],
    );
  });

  @override
  Future<List<(String, String)>> coachInvites() => _guard(() async {
    final rows = await _client.rpc('academy_my_coach_invites') as List? ?? [];
    return [
      for (final r in rows.cast<Map>())
        (r['academy_id'] as String, r['name'] as String? ?? ''),
    ];
  });

  @override
  Future<void> answerInvite(String academyId, {required bool accept}) =>
      _guard(() async {
        await _client.rpc(
          'academy_coach_answer',
          params: {'p_academy': academyId, 'p_accept': accept},
        );
      });
}

/// Coach data without a backend, for demos and tests.
class DemoCoachRepository implements CoachRepository {
  CoachLicence _licence = const CoachLicence(
    status: 'verified',
    number: 'NROC-1042',
    current: true,
    headline: 'Junior specialist',
    bio: 'Ten years with beginners.',
    yearsCoaching: 10,
  );
  String _verification = 'none';

  @override
  Future<CoachProfile> profile(String userId) async => CoachProfile(
    id: userId,
    name: 'Coach Ravi',
    headline: _licence.headline,
    bio: _licence.bio,
    yearsCoaching: _licence.yearsCoaching,
    academies: const [('a-smash', 'Smash Academy', 'Head coach')],
  );

  @override
  Future<CoachLicence> myLicence() async => _licence;

  @override
  Future<void> saveProfile({
    required String headline,
    required String bio,
    int? years,
  }) async {
    _licence = CoachLicence(
      status: _licence.status,
      number: _licence.number,
      current: _licence.current,
      headline: headline,
      bio: bio,
      yearsCoaching: years,
    );
  }

  @override
  Future<String> uploadDocument(Uint8List bytes, String contentType) async =>
      'demo/doc.jpg';

  @override
  Future<void> submitLicence({
    required String number,
    required DateTime expires,
    required String path,
  }) async {
    _licence = CoachLicence(status: 'submitted', number: number);
  }

  @override
  Future<void> submitBusiness(
    String academyId, {
    required String uen,
    required String path,
  }) async {
    _verification = 'submitted';
  }

  @override
  Future<AcademyChecklist> checklist(String academyId) async =>
      AcademyChecklist(
        verification: _verification,
        isOwner: true,
        coaches: [
          ChecklistCoach(
            name: 'Coach Ravi',
            head: true,
            accepted: true,
            licence: _licence.status,
          ),
        ],
      );

  @override
  Future<List<(String, String)>> coachInvites() async => const [
    ('a-smash', 'Smash Academy'),
  ];

  @override
  Future<void> answerInvite(String academyId, {required bool accept}) async {}
}
