import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/domain/country.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/guardian_models.dart';

abstract interface class GuardianRepository {
  /// Saves the birthday once. Returns the age group the server worked out:
  /// `adult`, `teen` or `child`.
  Future<String> setBirthday(DateTime birthday, Country country);
  Future<Restrictions> restrictions();

  Future<ParentCode> createCode();
  Future<PendingLink> redeemCode(String code);
  Future<void> decide(String linkId, {required bool approve});
  Future<void> revoke(String linkId);
  Future<List<GuardianLink>> children();
  Future<List<GuardianLink>> parents();
  Future<List<ChildPost>> childPosts(String childId);
  Future<void> deletePost(String childId, ChildPost post);
  Future<List<GroupRequest>> groupRequests(String childId);
  Future<void> decideGroup(
    String childId,
    GroupRequest group, {
    required bool approve,
  });
}

class SupabaseGuardianRepository implements GuardianRepository {
  SupabaseGuardianRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Guardian error: ${e.code}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  @override
  Future<String> setBirthday(DateTime birthday, Country country) => _guard(
    () async => await _client.rpc(
      'set_birthday',
      params: {
        'p_birthday': birthday.toIso8601String().substring(0, 10),
        'p_country': country.code,
      },
    ) as String,
  );

  @override
  Future<Restrictions> restrictions() => _guard(() async {
    final r = await _client.rpc('my_restrictions');
    return Restrictions.fromRow(r as Map<String, dynamic>);
  });

  @override
  Future<ParentCode> createCode() => _guard(() async {
    final r = await _client.rpc('guardian_code_create') as Map<String, dynamic>;
    return ParentCode(
      code: r['code'] as String,
      expiresAt: DateTime.parse(r['expires_at'] as String),
    );
  });

  @override
  Future<PendingLink> redeemCode(String code) => _guard(() async {
    final r = await _client.rpc(
      'guardian_code_redeem',
      params: {'p_code': code},
    ) as Map<String, dynamic>;
    final error = r['error'] as String?;
    if (error != null) throw AuthFailure(error);
    return PendingLink(
      linkId: r['link_id'] as String,
      childName: r['child_name'] as String,
    );
  });

  @override
  Future<void> decide(String linkId, {required bool approve}) => _guard(
    () => _client.rpc(
      'guardian_link_decide',
      params: {'p_link': linkId, 'p_approve': approve},
    ),
  );

  @override
  Future<void> revoke(String linkId) => _guard(
    () => _client.rpc('guardian_link_revoke', params: {'p_link': linkId}),
  );

  Future<List<GuardianLink>> _links(String function) => _guard(() async {
    final rows = await _client.rpc(function) as List;
    return [
      for (final r in rows) GuardianLink.fromRow(r as Map<String, dynamic>),
    ];
  });

  @override
  Future<List<GuardianLink>> children() => _links('guardian_children');

  @override
  Future<List<GuardianLink>> parents() => _links('guardian_parents');

  @override
  Future<List<ChildPost>> childPosts(String childId) => _guard(() async {
    final rows = await _client.rpc(
      'guardian_child_posts',
      params: {'p_child': childId},
    ) as List;
    return [for (final r in rows) ChildPost.fromRow(r as Map<String, dynamic>)];
  });

  @override
  Future<void> deletePost(String childId, ChildPost post) => _guard(
    () => _client.rpc(
      'guardian_delete_post',
      params: {'p_child': childId, 'p_kind': post.kind, 'p_id': post.id},
    ),
  );

  @override
  Future<List<GroupRequest>> groupRequests(String childId) => _guard(() async {
    final rows = await _client.rpc(
      'guardian_group_requests',
      params: {'p_child': childId},
    ) as List;
    return [
      for (final r in rows) GroupRequest.fromRow(r as Map<String, dynamic>),
    ];
  });

  @override
  Future<void> decideGroup(
    String childId,
    GroupRequest group, {
    required bool approve,
  }) => _guard(
    () => group.kind == 'team'
        ? _client.rpc(
            'guardian_team_decide',
            params: {
              'p_child': childId,
              'p_team': group.clubId,
              'p_approve': approve,
            },
          )
        : _client.rpc(
            'guardian_group_decide',
            params: {
              'p_child': childId,
              'p_club': group.clubId,
              'p_approve': approve,
            },
          ),
  );
}

/// Used in demo mode. `DEMO_AUDIENCE` picks the age group, so restricted mode
/// can be seen without a server.
class DemoGuardianRepository implements GuardianRepository {
  bool _linked = Env.demoAudience == 'child_linked';
  bool _pending = false;
  final _children = <GuardianLink>[
    const GuardianLink(
      linkId: 'demo-link',
      childId: 'demo-child',
      name: 'Ethan Lim',
      status: LinkStatus.approved,
    ),
  ];
  final _posts = <ChildPost>[
    ChildPost(
      kind: 'chat',
      id: 'demo-post',
      body: 'See you at training on Saturday',
      createdAt: DateTime(2026, 10, 24, 18, 30),
    ),
  ];

  String get _audience =>
      Env.demoAudience == 'child_linked' ? 'child' : Env.demoAudience;

  @override
  Future<String> setBirthday(DateTime birthday, Country country) async {
    final now = DateTime.now();
    var age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age >= 18 ? 'adult' : (age >= 13 ? 'teen' : 'child');
  }

  @override
  Future<Restrictions> restrictions() async {
    final restricted = _audience != 'adult' && !_linked;
    return Restrictions(
      audience: _audience,
      restricted: restricted,
      pendingParent: _pending,
      canScan: !restricted && _audience != 'child',
      canChat: !restricted,
      canDiscover: !restricted,
      canShop: !restricted,
      canHost: !restricted,
    );
  }

  @override
  Future<ParentCode> createCode() async {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return ParentCode(
      code: String.fromCharCodes(
        List.generate(
          8,
          (_) => letters.codeUnitAt(random.nextInt(letters.length)),
        ),
      ),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  @override
  Future<PendingLink> redeemCode(String code) async {
    if (!RegExp(r'^[A-Z2-9]{8}$').hasMatch(code.trim().toUpperCase())) {
      throw const AuthFailure("That code didn't work. Check it and try again.");
    }
    _pending = true;
    return const PendingLink(linkId: 'demo-pending', childName: 'Ethan Lim');
  }

  @override
  Future<void> decide(String linkId, {required bool approve}) async {
    _pending = false;
    _linked = approve;
  }

  @override
  Future<void> revoke(String linkId) async {
    _children.removeWhere((c) => c.linkId == linkId);
  }

  @override
  Future<List<GuardianLink>> children() async => [..._children];

  @override
  Future<List<GuardianLink>> parents() async => const [];

  @override
  Future<List<ChildPost>> childPosts(String childId) async => [..._posts];

  @override
  Future<void> deletePost(String childId, ChildPost post) async {
    _posts.removeWhere((p) => p.id == post.id);
  }

  final _groups = <GroupRequest>[
    const GroupRequest(
      clubId: 'demo-club',
      name: 'Tampines Smashers',
      area: 'Tampines',
    ),
  ];

  @override
  Future<List<GroupRequest>> groupRequests(String childId) async => [
    ..._groups,
  ];

  @override
  Future<void> decideGroup(
    String childId,
    GroupRequest group, {
    required bool approve,
  }) async {
    _groups.remove(group);
  }
}
