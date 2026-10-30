import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the signed-in session in the Keychain or Keystore. The default is
/// plain app preferences, which would leave the refresh token readable from
/// a backup of the phone.
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const _key = 'og_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}

/// Supabase's sign-out always ends the session on the server, which would kill
/// the token a saved tile holds. While [keepSession] is on, that one call stops
/// here, so sign-out only clears this device.
class SessionHttpClient extends http.BaseClient {
  final _inner = http.Client();
  bool keepSession = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (keepSession && request.url.path.endsWith('/logout')) {
      return http.StreamedResponse(const Stream.empty(), 204, request: request);
    }
    return _inner.send(request);
  }
}

final sessionHttpClient = SessionHttpClient();
