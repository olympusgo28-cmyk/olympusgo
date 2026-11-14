import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/lesson_models.dart';

/// Assessment templates, and what a coach records against them.
abstract class AssessmentRepository {
  Future<List<AssessmentTemplate>> templates(String academyId);
  Future<void> saveTemplate(
    String academyId, {
    String? id,
    required String name,
    required int scaleMax,
    required List<String> criteria,
  });
  Future<void> archiveTemplate(String id);

  /// Everything this person may read about a player, oldest first.
  Future<List<Assessment>> list(String playerId);

  /// Writes a new assessment, or corrects one when [id] is set. With no [on],
  /// it's for today.
  Future<void> save({
    String? id,
    String? studentId,
    String? templateId,
    DateTime? on,
    int? level,
    required String note,
    required Map<String, int> scores,
  });
}

class SupabaseAssessmentRepository implements AssessmentRepository {
  SupabaseAssessmentRepository(this._client);
  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Assessment error: ${e.code}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Assessment network error');
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  @override
  Future<List<AssessmentTemplate>> templates(String academyId) =>
      _guard(() async {
        final rows =
            await _client.rpc(
              'assessment_template_list',
              params: {'p_academy': academyId},
            ) as List? ??
            [];
        return [
          for (final t in rows.cast<Map>())
            AssessmentTemplate(
              id: t['id'] as String,
              name: t['name'] as String,
              scaleMax: t['scale_max'] as int,
              used: t['used'] as bool? ?? false,
              criteria: [
                for (final c in (t['criteria'] as List).cast<Map>())
                  (c['id'] as String, c['label'] as String),
              ],
            ),
        ];
      });

  @override
  Future<void> saveTemplate(
    String academyId, {
    String? id,
    required String name,
    required int scaleMax,
    required List<String> criteria,
  }) => _guard(() async {
    await _client.rpc(
      'assessment_template_save',
      params: {
        'p_academy': academyId,
        'p': {
          'id': ?id,
          'name': name,
          'scale_max': scaleMax,
          'criteria': criteria,
        },
      },
    );
  });

  @override
  Future<void> archiveTemplate(String id) => _guard(() async {
    await _client.rpc(
      'assessment_template_archive',
      params: {'p_template': id},
    );
  });

  @override
  Future<List<Assessment>> list(String playerId) => _guard(() async {
    final rows =
        await _client.rpc('assessment_list', params: {'p_player': playerId})
            as List? ??
        [];
    return [
      for (final a in rows.cast<Map>())
        Assessment(
          id: a['id'] as String,
          academy: a['academy'] as String? ?? '',
          templateId: a['template_id'] as String,
          template: a['template'] as String? ?? '',
          coach: a['coach'] as String? ?? '',
          on: DateTime.parse(a['assessed_on'] as String),
          level: a['level'] as int?,
          note: a['note'] as String? ?? '',
          edited: a['edited'] as bool? ?? false,
          mine: a['mine'] as bool? ?? false,
          scores: [
            for (final s in (a['scores'] as List).cast<Map>())
              AssessmentScore(
                criterionId: s['criterion_id'] as String,
                label: s['label'] as String,
                score: s['score'] as int,
                max: s['max'] as int,
              ),
          ],
        ),
    ];
  });

  @override
  Future<void> save({
    String? id,
    String? studentId,
    String? templateId,
    DateTime? on,
    int? level,
    required String note,
    required Map<String, int> scores,
  }) => _guard(() async {
    await _client.rpc(
      'assessment_save',
      params: {
        'p': {
          'id': ?id,
          'student_id': ?studentId,
          'template_id': ?templateId,
          // Left out, the server uses today in Singapore.
          'assessed_on': ?on?.toIso8601String().substring(0, 10),
          'level': level,
          'note': note,
          'scores': scores,
        },
      },
    );
  });
}

/// Assessments without a backend, for demos and tests.
class DemoAssessmentRepository implements AssessmentRepository {
  final _templates = <AssessmentTemplate>[
    const AssessmentTemplate(
      id: 't-1',
      name: 'Term skills',
      scaleMax: 5,
      criteria: [('c-1', 'Footwork'), ('c-2', 'Serve')],
      used: true,
    ),
  ];
  final _all = <Assessment>[
    Assessment(
      id: 'as-1',
      academy: 'Smash Academy',
      templateId: 't-1',
      template: 'Term skills',
      coach: 'Coach Ravi',
      on: DateTime(2026, 9, 1),
      level: 2,
      note: 'A strong start.',
      scores: const [
        AssessmentScore(
          criterionId: 'c-1',
          label: 'Footwork',
          score: 2,
          max: 5,
        ),
        AssessmentScore(criterionId: 'c-2', label: 'Serve', score: 3, max: 5),
      ],
    ),
    Assessment(
      id: 'as-2',
      academy: 'Smash Academy',
      templateId: 't-1',
      template: 'Term skills',
      coach: 'Coach Ravi',
      on: DateTime(2026, 10, 1),
      level: 2,
      mine: true,
      scores: const [
        AssessmentScore(
          criterionId: 'c-1',
          label: 'Footwork',
          score: 4,
          max: 5,
        ),
        AssessmentScore(criterionId: 'c-2', label: 'Serve', score: 3, max: 5),
      ],
    ),
  ];

  @override
  Future<List<AssessmentTemplate>> templates(String academyId) async => [
    ..._templates,
  ];

  @override
  Future<void> saveTemplate(
    String academyId, {
    String? id,
    required String name,
    required int scaleMax,
    required List<String> criteria,
  }) async {
    _templates.add(
      AssessmentTemplate(
        id: 't-${_templates.length + 1}',
        name: name,
        scaleMax: scaleMax,
        criteria: [
          for (var i = 0; i < criteria.length; i++) ('n-$i', criteria[i]),
        ],
      ),
    );
  }

  @override
  Future<void> archiveTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<Assessment>> list(String playerId) async => [..._all];

  @override
  Future<void> save({
    String? id,
    String? studentId,
    String? templateId,
    DateTime? on,
    int? level,
    required String note,
    required Map<String, int> scores,
  }) async {}
}
