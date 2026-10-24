import '../../auth/data/auth_repository.dart';
import '../domain/safety_models.dart';

/// The player's reports and notices about their own content.
abstract interface class SafetyRepository {
  Future<List<SafetyReport>> myReports();
  Future<SafetyReport> report(String id);

  /// One second look, by a different reviewer.
  Future<void> askSecondLook(String id);

  Future<RemovalNotice> removal(String id);

  /// One review of a removal, with an optional reason.
  Future<void> askReview(String id, String note);
}

const _soon = AuthFailure(
  'Report tracking opens with the next release. Your reports are still sent.',
);

/// No report tracking tables yet: the list is empty and actions explain why.
class SupabaseSafetyRepository implements SafetyRepository {
  @override
  Future<List<SafetyReport>> myReports() async => const [];
  @override
  Future<SafetyReport> report(String id) => throw _soon;
  @override
  Future<void> askSecondLook(String id) => throw _soon;
  @override
  Future<RemovalNotice> removal(String id) => throw _soon;
  @override
  Future<void> askReview(String id, String note) => throw _soon;
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
}
