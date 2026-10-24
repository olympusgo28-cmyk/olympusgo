import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import 'router/routes.dart';

/// Public links into the app.
abstract final class Links {
  /// Where share links point. Change this once the app has its own domain.
  static const host = 'olympusgo.netlify.app';
  static const _base = 'https://$host';

  static String club(String id) => '$_base/club/$id';
  static String academy(String id) => '$_base/academy/$id';
  static String academyClass(String id, String classId) =>
      '${academy(id)}/join/$classId';
  static String clubInvite(String code) => '$_base/join/$code';
  static String teamInvite(String id) => '$_base/team/$id';
  static String leaderboard(String clubId) => '$_base/club/$clubId/ranks';
  static String meet(String id) => '$_base/meet/$id';
  static String event(String id) => '$_base/event/$id';
  static String tournament(String id) => '$_base/tournament/$id';

  /// Player codes are profile links: `<host>/<username>`.
  static String player(String username) => '$_base/$username';

  static final _username = RegExp(r'^[A-Za-z0-9_]{3,30}$');

  /// Website pages that aren't player profiles.
  static const _pages = {'terms', 'privacy'};

  /// The screen a share link opens, or null when [uri] isn't one.
  static String? route(Uri uri) {
    final s = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    return switch (s) {
      ['club', final id] => Routes.club(id),
      ['club', final id, 'ranks'] => Routes.clubLeaderboard(id),
      ['academy', final id] ||
      ['academy', final id, 'join', _] => Routes.academy(id),
      ['team', final id] => Routes.team(id),
      ['join', final code] => Routes.joinClub(code),
      ['meet' || 'event' || 'tournament', final id] => Routes.activity(id),
      [final name] when _username.hasMatch(name) && !_pages.contains(name) =>
        Routes.scannedPlayer(name),
      _ => null,
    };
  }
}

/// Opens the iOS share sheet anchored to [context]'s widget (iPad needs an
/// anchor for the popover).
Future<void> shareLink(BuildContext context, String text, String url) {
  final box = context.findRenderObject() as RenderBox?;
  return SharePlus.instance.share(
    ShareParams(
      text: '$text\n$url',
      subject: text,
      sharePositionOrigin: box == null || !box.hasSize
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
