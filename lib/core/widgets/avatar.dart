import 'package:supabase_flutter/supabase_flutter.dart';

import '../avatar_address.dart';
import '../config/env.dart';

import 'package:flutter/material.dart';

import '../../core/theme/og_type.dart';

/// The pastel avatar colours used across the design.
enum AvatarTone {
  green(Color(0xFFDCF2E3), Color(0xFF1F6B3A)),
  yellow(Color(0xFFFFF0C2), Color(0xFF7A5600)),
  pink(Color(0xFFFCE1EC), Color(0xFFA12A5E)),
  blue(Color(0xFFDCE9FF), Color(0xFF1E4E8C)),
  purple(Color(0xFFECE4FF), Color(0xFF5B3BA8)),
  peach(Color(0xFFFFE3D1), Color(0xFF9A3A00)),
  brand(Color(0xFFE8590C), Color(0xFFFFFFFF));

  const AvatarTone(this.fill, this.ink);
  final Color fill;
  final Color ink;

  /// Fixed tones for known ids (the demo players match the design).
  static final overrides = <String, AvatarTone>{};

  /// A stable pastel for any player id.
  static AvatarTone forId(String id) {
    final fixed = overrides[id];
    if (fixed != null) return fixed;
    final pastels = values.where((t) => t != brand).toList();
    return pastels[id.codeUnits.fold(0, (a, b) => a + b) % pastels.length];
  }
}

/// What a photo request is made with: the project address and the viewer's
/// session.
typedef AvatarSession = ({String baseUrl, String? token, String anonKey});

/// Round (or, for groups, rounded-square) avatar: the photo when there is
/// one, otherwise initials on a pastel.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.initials,
    this.tone = AvatarTone.green,
    this.imageUrl,
    this.size = 48,
    this.square = false,
  });

  /// Tests stand in for the signed-in session here; always null in the app.
  @visibleForTesting
  static AvatarSession Function()? debugSession;

  static AvatarSession _session() => (
    baseUrl: Env.supabaseUrl,
    token: Env.hasSupabase
        ? Supabase.instance.client.auth.currentSession?.accessToken
        : null,
    anonKey: Env.supabaseAnonKey,
  );

  final String initials;
  final AvatarTone tone;
  final String? imageUrl;
  final double size;
  final bool square;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(square ? 14 : size / 2);
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone.fill, borderRadius: radius),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: context.type.initials(size).copyWith(color: tone.ink),
      ),
    );
    final session = debugSession ?? _session;
    final request = avatarRequest(
      imageUrl,
      baseUrl: session().baseUrl,
      token: session().token,
      anonKey: session().anonKey,
    );
    if (request == null) return ExcludeSemantics(child: fallback);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: radius,
        child: Image.network(
          request.url.toString(),
          headers: request.headers,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}
