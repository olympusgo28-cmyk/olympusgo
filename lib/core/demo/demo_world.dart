import '../../features/auth/data/auth_repository.dart';
import '../../features/profile/domain/profile.dart';
import '../../features/social/domain/social_models.dart';
import '../widgets/avatar.dart';
import '../widgets/og_kit.dart';

/// The people and relationships from the design, used in demo mode so every
/// screen looks like the canvas without a backend.
class DemoWorld {
  DemoWorld._() {
    for (final p in _people) {
      AvatarTone.overrides[p.$1.id] = p.$2;
      players[p.$1.id] = p.$1;
    }
    Faces.overrides.addAll(_faces);
  }

  static final instance = DemoWorld._();

  static const me = DemoAuthRepository.demoUserId;

  /// The signed-in demo player: Aaron Ng, the player the canvas is drawn
  /// around.
  static const meSummary = PlayerSummary(
    id: me,
    username: 'aaronng',
    fullName: 'Aaron Ng',
  );

  // The canvas cast. Club members and other features register more people
  // through [register]; these ids match theirs.
  static const _people = [
    (
      PlayerSummary(
        id: 'cp-hannah',
        username: 'hannahgoh',
        fullName: 'Hannah Goh',
      ),
      AvatarTone.green,
      'Hosts Doubles Social every Tuesday and Friday.',
      6.2,
      null,
    ),
    (
      PlayerSummary(
        id: 'cp-priyar',
        username: 'priyaraman',
        fullName: 'Priya Raman',
      ),
      AvatarTone.blue,
      'Mixed doubles most weeks. Happy to rotate.',
      5.1,
      4.0,
    ),
    (
      PlayerSummary(id: 'cp-sitil', username: 'sitilim', fullName: 'Siti Lim'),
      AvatarTone.peach,
      'Weekend singles at Bedok.',
      5.0,
      null,
    ),
    (
      PlayerSummary(
        id: 'cp-meiling',
        username: 'meiling',
        fullName: 'Mei Ling',
      ),
      AvatarTone.purple,
      'New to the east side. Doubles, please!',
      5.4,
      null,
    ),
    (
      PlayerSummary(id: 'cp-mei', username: 'meiwong', fullName: 'Mei Wong'),
      AvatarTone.blue,
      'Second singles for School Team A.',
      4.6,
      null,
    ),
    (
      PlayerSummary(
        id: 'cp-kelvin',
        username: 'kelvinho',
        fullName: 'Kelvin Ho',
      ),
      AvatarTone.blue,
      'Just joined Tampines Smashers.',
      5.2,
      null,
    ),
    (
      PlayerSummary(
        id: 'cp-danielt',
        username: 'danieltan',
        fullName: 'Daniel Tan',
      ),
      AvatarTone.green,
      'Morning singles, any day of the week.',
      4.2,
      null,
    ),
    (
      PlayerSummary(
        id: 'cp-siti',
        username: 'sitikamal',
        fullName: 'Siti Kamal',
      ),
      AvatarTone.green,
      'Admin at Tampines Smashers.',
      5.7,
      null,
    ),
    (
      PlayerSummary(id: 'cp-ravi', username: 'ravitan', fullName: 'Ravi Tan'),
      AvatarTone.peach,
      'Coach. The 30-day smash challenge is live.',
      6.4,
      null,
    ),
    (
      PlayerSummary(
        id: 'cp-hafiz',
        username: 'hafiz_r',
        fullName: 'Hafiz Rahman',
      ),
      AvatarTone.yellow,
      'Pickleball on Sundays, badminton midweek.',
      5.4,
      4.0,
    ),
    (
      PlayerSummary(id: 'cp-dankoh', username: 'dankoh', fullName: 'Dan Koh'),
      AvatarTone.green,
      null,
      null,
      null,
    ),
    (
      PlayerSummary(id: 'cp-rina', username: 'rina_s', fullName: 'Rina Sato'),
      AvatarTone.peach,
      null,
      null,
      null,
    ),
  ];

  /// Solid avatar colours (background, ink) from the canvas.
  static const _faces = <String, (int, int)>{
    'cp-hannah': (0xFF101010, 0xFFC6FF00),
    'cp-priyar': (0xFF3E6B8A, 0xFFFFFFFF),
    'cp-sitil': (0xFFC8553D, 0xFFFFFFFF),
    'cp-meiling': (0xFF7B5EA7, 0xFFFFFFFF),
    'cp-mei': (0xFF2F3A5F, 0xFFFFFFFF),
    'cp-kelvin': (0xFF3E6B8A, 0xFFFFFFFF),
    'cp-danielt': (0xFF0E6B4E, 0xFFFFFFFF),
    'cp-siti': (0xFF0E6B4E, 0xFFFFFFFF),
    'cp-ravi': (0xFFC8553D, 0xFFFFFFFF),
    'cp-hafiz': (0xFFE0A82E, 0xFFFFFFFF),
    'cp-dankoh': (0xFF1C1F23, 0xFFFFFFFF),
    'cp-rina': (0xFFB9832A, 0xFFFFFFFF),
  };

  final players = <String, PlayerSummary>{};

  /// People added by other demo features (club members, coaches).
  final _extra =
      <String, (PlayerSummary, AvatarTone, String?, double?, double?)>{};

  /// Makes a person from another demo feature open as a full profile.
  void register(
    PlayerSummary player, {
    double? badminton,
    double? pickleball,
    String? bio,
  }) {
    if (players.containsKey(player.id)) return;
    players[player.id] = player;
    _extra[player.id] = (
      player,
      AvatarTone.forId(player.id),
      bio,
      badminton,
      pickleball,
    );
  }

  PlayerDetail detail(
    String id, {
    required bool iFollow,
    required bool followsMe,
  }) {
    final p = _extra[id] ?? _people.firstWhere((e) => e.$1.id == id);
    return PlayerDetail(
      player: p.$1,
      bio: p.$3,
      sports: [
        if (p.$4 != null)
          PlayerSport(
            sport: 'badminton',
            level: p.$4!,
            playMin: p.$4! - 1,
            playMax: p.$4! + 1,
          ),
        if (p.$5 != null)
          PlayerSport(
            sport: 'pickleball',
            level: p.$5!,
            playMin: p.$5! - 1,
            playMax: p.$5! + 0.5,
          ),
      ],
      social: PlayerSocial(
        followers: 214,
        following: 86,
        iFollow: iFollow,
        followsMe: followsMe,
      ),
      played: 57,
    );
  }

  // Not Hannah, Priya, Siti Lim or Mei Ling: Home suggests them.
  final following = {
    'cp-ravi',
    'cp-siti',
    'cp-mei',
    'cp-kelvin',
    'cp-hafiz',
    'cp-danielt',
  };
  final followers = {'cp-hannah', 'cp-priyar', 'cp-mei', 'cp-kelvin'};
  final blocked = {'cp-dankoh', 'cp-rina'};
  final savedPlayers = <String>{'cp-ravi'};
  final savedMeets = <String>{'t-open'};
  final savedClubs = <String>{};

  /// Conversation id -> other player id, newest first.
  final conversations = <String, String>{
    'conv-hannah': 'cp-hannah',
    'conv-priya': 'cp-priyar',
    'conv-ravi': 'cp-ravi',
    'conv-daniel': 'cp-danielt',
  };

  final unread = <String>{'conv-hannah'};

  late final messages = <String, List<ChatMessage>>{
    'conv-hannah': _thread('conv-hannah', 'cp-hannah', [
      (false, 'Courts 3 and 4 are ours tonight'),
      (true, 'On my way after work'),
      (false, 'Great. Bring a spare tube of shuttles?'),
      (true, 'Will do'),
      (false, 'See you at Our Tampines Hub at 8'),
    ], minutesAgo: 2),
    'conv-priya': _thread('conv-priya', 'cp-priyar', [
      (true, 'Partner for mixed doubles at the Open?'),
      (false, 'Partner for mixed doubles? I accepted your invite'),
    ], minutesAgo: 60 * 24),
    'conv-ravi': _thread('conv-ravi', 'cp-ravi', [
      (false, 'Nice smash form at the ladder night'),
    ], minutesAgo: 60 * 24 * 3),
    'conv-daniel': _thread('conv-daniel', 'cp-danielt', [
      (false, 'Thanks for the singles game'),
    ], minutesAgo: 60 * 24 * 6),
  };

  List<ChatMessage> _thread(
    String conv,
    String other,
    List<(bool, String)> lines, {
    required int minutesAgo,
  }) {
    final end = DateTime.now().subtract(Duration(minutes: minutesAgo));
    return [
      for (var i = 0; i < lines.length; i++)
        ChatMessage(
          id: '$conv-$i',
          senderId: lines[i].$1 ? me : other,
          body: lines[i].$2,
          createdAt: end.subtract(
            Duration(minutes: (lines.length - 1 - i) * 3),
          ),
        ),
    ];
  }
}
