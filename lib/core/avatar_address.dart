// Where a player's photo lives and how the app may fetch it (Q267).

const _publicPath = '/storage/v1/object/public/avatars/';
const _signedInPath = '/storage/v1/object/authenticated/avatars/';

/// A stored photo address: the owner's own file in the avatars bucket, as a
/// path with no host (the database allows nothing else, Q267).
final _storedPhoto = RegExp(
  r'^/storage/v1/object/public/avatars/'
  r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'
  r'/(avatar\.(?:jpeg|png))(?:\?v=([0-9]{1,15}))?$',
);

/// Where to fetch a player's photo from, and the headers to send, or null
/// when nothing should be fetched.
///
/// Photos are private: the database checks each read against who may see
/// that player, so the request carries the viewer's session token. That
/// token must never go anywhere but our own storage. So only the stored
/// path form is accepted and the address is built from [baseUrl], never
/// from the stored value. A full address, another bucket, no session or no
/// backend gives null, and the avatar draws initials without any request.
({Uri url, Map<String, String> headers})? avatarRequest(
  String? stored, {
  required String baseUrl,
  required String? token,
  required String anonKey,
}) {
  if (stored == null || token == null || token.isEmpty || anonKey.isEmpty) {
    return null;
  }
  final photo = _storedPhoto.firstMatch(stored);
  final base = Uri.tryParse(baseUrl);
  if (photo == null || base == null || !_ourProject(base)) return null;
  final version = photo.group(3);
  return (
    url: Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '$_signedInPath${photo.group(1)}/${photo.group(2)}',
      queryParameters: version == null ? null : {'v': version},
    ),
    headers: {'Authorization': 'Bearer $token', 'apikey': anonKey},
  );
}

/// Whether [base] is a plain project address the token may go to: https
/// (or http to this machine only, for a local stack), a host, and nothing
/// tucked in before it. It is a build setting, not data, so this guards
/// against a mistyped build rather than an attacker.
bool _ourProject(Uri base) {
  const local = {'127.0.0.1', 'localhost', '10.0.2.2'};
  if (base.host.isEmpty || base.userInfo.isNotEmpty) return false;
  return base.scheme == 'https' ||
      (base.scheme == 'http' && local.contains(base.host));
}

/// The path form [avatarRequest] and the database accept, for a new upload.
String storedAvatarPath(String userId, String extension, int version) =>
    '$_publicPath$userId/avatar.$extension?v=$version';
