import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/routes.dart';
import '../domain/inbox_models.dart';

/// The Inbox's Updates: notices about Meets, clubs, points and reports.
abstract interface class UpdatesRepository {
  Future<List<InboxUpdate>> updates();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class SupabaseUpdatesRepository implements UpdatesRepository {
  SupabaseUpdatesRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<InboxUpdate>> updates() async {
    final rows = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return [
      for (final r in rows)
        InboxUpdate(
          id: r['id'] as String,
          title: r['title'] as String,
          body: r['body'] as String? ?? '',
          mark: r['mark'] as String? ?? '•',
          color: _hex(r['color'] as String?) ?? 0xFF16181B,
          ink: _hex(r['ink'] as String?) ?? 0xFFC6FF00,
          square: r['square'] as bool? ?? false,
          link: r['link'] as String?,
          at: DateTime.parse(r['created_at'] as String).toLocal(),
          read: r['read_at'] != null,
        ),
    ];
  }

  /// "#F2C14E" → 0xFFF2C14E.
  static int? _hex(String? s) => s == null || s.length != 7
      ? null
      : int.tryParse('FF${s.substring(1)}', radix: 16);

  @override
  Future<void> markRead(String id) => _client
      .from('notifications')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('id', id);

  @override
  Future<void> markAllRead() => _client
      .from('notifications')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .isFilter('read_at', null);
}

class DemoUpdatesRepository implements UpdatesRepository {
  DemoUpdatesRepository() {
    final now = DateTime.now();
    DateTime today(int h, int m) =>
        DateTime(now.year, now.month, now.day, h, m);
    DateTime ago(int days, int h) =>
        DateTime(now.year, now.month, now.day - days, h);
    _items = [
      InboxUpdate(
        id: 'u-academy',
        title: 'Smash Academy is moving',
        body: 'From Sat 24 Oct. Juniors Level 2 moves to the new place',
        mark: 'SA',
        color: 0xFFF2C14E,
        ink: 0xFF3A2C00,
        link: Routes.studentHome('s-ethan'),
        at: today(14, 50).isAfter(now) ? ago(1, 14) : today(14, 50),
      ),
      InboxUpdate(
        id: 'u-report',
        title: 'Your report: in review',
        body: 'Message in Tampines Smashers. Decision by tomorrow, 9:24 AM',
        mark: 'Rv',
        link: Routes.reportStatus('r-message'),
        at: today(9, 31).isAfter(now) ? ago(1, 9) : today(9, 31),
      ),
      InboxUpdate(
        id: 'u-score',
        title: 'Confirm your score',
        body: 'Mei Wong entered Morning Singles: 21–15, 18–21, 21–17',
        mark: 'Sc',
        link: Routes.score('sc-morning'),
        at: ago(1, 11),
      ),
      InboxUpdate(
        id: 'u-points',
        title: 'You earned 4 points',
        body: 'Hannah marked you present at Doubles Social',
        mark: 'Pt',
        color: 0xFFFFE8CC,
        ink: 0xFF7A3B00,
        link: Routes.points,
        at: ago(1, 22),
      ),
      InboxUpdate(
        id: 'u-recap',
        title: 'Your Meet recap is ready',
        body: '3 wins, rating 5.3 to 5.4. Share your stats card',
        mark: 'St',
        ink: 0xFFF28500,
        link: Routes.meetRecap('ts-social'),
        at: ago(1, 22),
      ),
      InboxUpdate(
        id: 'u-removed',
        title: 'A message of yours was removed',
        body: 'Personal details shared. See why, or ask for a review',
        mark: '!',
        color: 0xFFFBE3E0,
        ink: 0xFF7A1F17,
        link: Routes.removalNotice('n-removed'),
        at: ago(4, 15),
        read: true,
      ),
      InboxUpdate(
        id: 'u-open',
        title: 'Tampines Open closes Sun 18 Oct',
        body: 'Mixed doubles has 6 spots left',
        mark: 'To',
        color: 0xFFFBE7B0,
        ink: 0xFF5A4300,
        link: Routes.activity('t-open'),
        at: ago(4, 12),
        read: true,
      ),
      InboxUpdate(
        id: 'u-reward',
        title: 'Club reward: 2 of 4 Meets',
        body: 'Tampines Smashers is halfway to discounted shuttles',
        mark: 'Cl',
        color: 0xFFDCEEE6,
        ink: 0xFF0A4F3A,
        link: Routes.clubReward('c-ts'),
        at: ago(5, 18),
        read: true,
      ),
    ];
  }

  late List<InboxUpdate> _items;

  @override
  Future<List<InboxUpdate>> updates() async => [..._items];

  @override
  Future<void> markRead(String id) async => _items = [
    for (final u in _items) u.id == id ? u.copyWith(read: true) : u,
  ];

  @override
  Future<void> markAllRead() async =>
      _items = [for (final u in _items) u.copyWith(read: true)];
}
