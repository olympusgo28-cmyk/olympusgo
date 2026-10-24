import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/share.dart';

void main() {
  String? open(String url) => Links.route(Uri.parse(url));

  test('share links open the matching screen', () {
    expect(open(Links.club('c1')), Routes.club('c1'));
    expect(open(Links.leaderboard('c1')), Routes.clubLeaderboard('c1'));
    expect(open(Links.academy('a1')), Routes.academy('a1'));
    expect(open(Links.academyClass('a1', 'k1')), Routes.academy('a1'));
    expect(open(Links.teamInvite('t1')), Routes.team('t1'));
    expect(open(Links.meet('m1')), Routes.activity('m1'));
    expect(open(Links.event('e1')), Routes.activity('e1'));
    expect(open(Links.tournament('x1')), Routes.activity('x1'));
    expect(open(Links.player('mei_tan')), Routes.scannedPlayer('mei_tan'));
    expect(open(Links.clubInvite('TS8KQ2')), Routes.joinClub('TS8KQ2'));
  });

  test('other paths are left alone', () {
    expect(open('https://${Links.host}/'), isNull);
    expect(open('https://${Links.host}/a'), isNull);
  });
}
