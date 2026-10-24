import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/format.dart';
import '../../auth/data/auth_repository.dart';
import '../../clubs/domain/club_models.dart' show ContentReport;
import '../domain/safety_models.dart';

/// The player's reports, notices about their own content, and legal notices.
abstract interface class SafetyRepository {
  Future<List<SafetyReport>> myReports();
  Future<SafetyReport> report(String id);

  /// One second look, by a different reviewer.
  Future<void> askSecondLook(String id);

  Future<RemovalNotice> removal(String id);

  /// One review of a removal, with an optional reason.
  Future<void> askReview(String id, String note);

  /// Sends a legal notice, signed in or not. Returns its reference.
  Future<String> sendLegalNotice(LegalNotice notice);
}

class SupabaseSafetyRepository implements SafetyRepository {
  SupabaseSafetyRepository(this._client);
  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Safety error: ${e.code} ${e.message}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Safety network error: $e');
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  static const _playerReasons = {
    'spam': 'Spam',
    'harassment': 'Harassment',
    'inappropriate': 'Inappropriate content',
    'cheating': 'Cheating',
    'other': 'Something else',
  };

  static String _reasonLabel(String id) =>
      ContentReport.values.where((r) => r.id == id).firstOrNull?.label ??
      _playerReasons[id] ??
      'Something else';

  static String _initials(String s) {
    final words = s
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && RegExp(r'[A-Za-z0-9]').hasMatch(w[0]))
        .toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  static String _when(DateTime at) {
    final now = DateTime.now();
    final day = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final label = day == today
        ? 'Today'
        : day == today.subtract(const Duration(days: 1))
        ? 'Yesterday'
        : Fmt.day(at);
    return '$label, ${Fmt.time(at)}';
  }

  static SafetyReport _report(Map<String, dynamic> r) {
    final kind = r['kind'] as String;
    final what = r['what'] as String? ?? '';
    final who = r['who'] as String?;
    final at = DateTime.parse(r['at'] as String).toLocal();
    final state = switch (r['status'] as String) {
      'removed' => ReportState.removed,
      'no_action' => ReportState.noAction,
      _ => ReportState.inReview,
    };
    final activity = switch (r['activity_kind'] as String?) {
      'tournament' => 'Tournament',
      'event' => 'Event',
      _ => 'Meet',
    };
    final label = switch (kind) {
      'message' => 'Message',
      'club' => 'Club',
      'team' => 'Team',
      'activity' => activity,
      'video' => 'Video',
      'live' => 'Live',
      _ => 'Player',
    };
    final decided = r['decided_at'] == null
        ? null
        : DateTime.parse(r['decided_at'] as String).toLocal();
    return SafetyReport(
      id: r['id'] as String,
      what: what.isEmpty ? label : '$label · $what',
      reason: _reasonLabel(r['reason'] as String),
      at: at,
      state: state,
      initials: _initials(who ?? (what.isEmpty ? label : what)),
      heading: switch (kind) {
        'message' => what.isEmpty ? 'Message' : 'Message in $what chat',
        'player' => 'Player profile',
        _ => what.isEmpty ? label : what,
      },
      detail: who ?? label,
      steps: [
        ('Report sent', '${_when(at)}. Hidden from you straight away'),
        if (decided != null)
          (
            'Decided',
            '${_when(decided)}. ${state == ReportState.removed ? 'Removed' : 'Kept'}',
          ),
      ],
      decideBy: state == ReportState.inReview
          ? 'By ${_when(at.add(const Duration(hours: 24)))} at the latest'
          : null,
      result:
          r['result'] as String? ??
          switch (state) {
            ReportState.removed => 'It broke the community rules and was removed. The person was told which rule.',
            ReportState.noAction => 'It does not break the community rules, so it stays. You can still block or hide it.',
            ReportState.inReview => null,
          },
      secondLook: r['second_look'] as bool? ?? false,
    );
  }

  @override
  Future<List<SafetyReport>> myReports() => _guard(() async {
    final rows = await _client.rpc('my_reports') as List? ?? const [];
    return [for (final r in rows) _report(Map<String, dynamic>.from(r as Map))];
  });

  @override
  Future<SafetyReport> report(String id) async {
    final found = (await myReports()).where((r) => r.id == id).firstOrNull;
    if (found == null) {
      throw const AuthFailure('This report no longer exists.');
    }
    return found;
  }

  @override
  Future<void> askSecondLook(String id) =>
      _guard(() => _client.rpc('report_second_look', params: {'p_id': id}));

  @override
  Future<RemovalNotice> removal(String id) => _guard(() async {
    final r = await _client
        .from('content_removals')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (r == null) throw const AuthFailure('This notice no longer exists.');
    return RemovalNotice(
      id: r['id'] as String,
      what: r['what'] as String,
      where: r['where_text'] as String? ?? '',
      rule: r['rule'] as String,
      decidedBy: r['decided_by'] as String? ?? 'Olympus review team',
      why: r['why'] as String? ?? '',
      next: [for (final n in r['next'] as List? ?? const []) n as String],
      reviewAsked: r['review_asked'] as bool? ?? false,
    );
  });

  @override
  Future<void> askReview(String id, String note) => _guard(
    () =>
        _client.rpc('removal_ask_review', params: {'p_id': id, 'p_note': note}),
  );

  @override
  Future<String> sendLegalNotice(LegalNotice n) => _guard(
    () async => await _client.rpc(
      'legal_notice_send',
      params: {
        'p': {
          'role': n.role,
          'name': n.name,
          'email': n.email,
          'country': n.country.code,
          'location': n.location,
          'reasons': n.reasons,
          'details': n.details,
          'true': true,
        },
      },
    ) as String,
  );
}

class DemoSafetyRepository implements SafetyRepository {
  DemoSafetyRepository() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Sent at 9:24 today, or yesterday if it isn't 9:31 yet, as in Inbox.
    final early = now.isBefore(
      today.add(const Duration(hours: 9, minutes: 31)),
    );
    final sent = today.add(
      Duration(days: early ? -1 : 0, hours: 9, minutes: 24),
    );
    final day = early ? 'Yesterday' : 'Today';
    _reports = [
      SafetyReport(
        id: 'r-message',
        what: 'Message · Tampines Smashers',
        reason: 'Personal details shared',
        at: sent,
        state: ReportState.inReview,
        initials: 'KH',
        heading: 'Message in Tampines Smashers chat',
        detail: 'Kelvin Ho, 9:15 AM',
        steps: [
          ('Report sent', '$day, 9:24 AM. Hidden from you straight away'),
          ('A reviewer picked it up', '$day, 9:31 AM. Marked urgent'),
        ],
        decideBy: 'By ${early ? 'today' : 'tomorrow'}, 9:24 AM at the latest',
      ),
      SafetyReport(
        id: 'r-listing',
        what: 'Listing · Carbon racket 4U',
        reason: 'Fake or unsafe product',
        at: today.subtract(const Duration(days: 17)),
        state: ReportState.noAction,
        initials: 'RL',
        heading: 'Listing in the Shop',
        detail: 'Carbon racket 4U, sold by RL Sports',
        steps: const [
          ('Report sent', 'Hidden from you straight away'),
          ('A reviewer picked it up', 'The same day'),
          ('Decided', 'Kept. It does not break the rules'),
        ],
        result: 'The seller showed proof the racket is genuine, so the listing stays. You can still hide it from your Shop.',
      ),
      SafetyReport(
        id: 'r-player',
        what: 'Player · Ryan Teo',
        reason: 'Harassment',
        at: today.subtract(const Duration(days: 34)),
        state: ReportState.removed,
        initials: 'RT',
        heading: 'Player profile',
        detail: 'Ryan Teo',
        steps: const [
          ('Report sent', 'Hidden from you straight away'),
          ('A reviewer picked it up', 'Within the hour'),
          ('Decided', 'Removed, and the player was told which rule'),
        ],
        result: 'The messages broke the harassment rule. They were removed and the player can no longer message you.',
      ),
    ];
    _removals = {
      'n-removed': const RemovalNotice(
        id: 'n-removed',
        what: 'Your message of Thu 1 Oct, 8:02 PM',
        where: 'Tampines Smashers chat',
        rule: 'Personal details shared',
        decidedBy: 'Olympus review team',
        why: 'The message gave another member’s home address. Posting someone’s address, phone, school or workplace without their consent is not allowed, even as a joke.',
        next: [
          'This is a first warning. Nothing else changes',
          'A second time pauses your chat for 7 days',
          'You can ask once for a review if you think we got it wrong',
        ],
      ),
    };
  }

  late List<SafetyReport> _reports;
  late Map<String, RemovalNotice> _removals;

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 250));

  @override
  Future<List<SafetyReport>> myReports() async {
    await _tick();
    return [..._reports];
  }

  @override
  Future<SafetyReport> report(String id) async {
    await _tick();
    return _reports.firstWhere((r) => r.id == id);
  }

  @override
  Future<void> askSecondLook(String id) async {
    await _tick();
    _reports = [
      for (final r in _reports) r.id == id ? r.copyWith(secondLook: true) : r,
    ];
  }

  @override
  Future<RemovalNotice> removal(String id) async {
    await _tick();
    return _removals[id]!;
  }

  @override
  Future<void> askReview(String id, String note) async {
    await _tick();
    _removals[id] = _removals[id]!.asked();
  }

  @override
  Future<String> sendLegalNotice(LegalNotice notice) async {
    await _tick();
    final now = DateTime.now();
    return 'OLY-${now.year % 100}${now.month.toString().padLeft(2, '0')}-0412';
  }
}
