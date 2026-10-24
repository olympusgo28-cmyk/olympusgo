import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/country.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/settings_models.dart';

/// The signed-in player's own account, personal details and preferences.
abstract interface class SettingsRepository {
  Future<AccountDetails> account();
  Future<void> saveAccount(AccountDetails details);

  /// Uploads a new profile photo and returns its public URL.
  Future<String> uploadAvatar(Uint8List bytes, String extension);

  Future<PrivateInfo> privateInfo();

  /// Starts an email change; Supabase emails a confirmation link.
  Future<void> changeEmail(String email);

  Future<NotificationPrefs> notifications();
  Future<void> saveNotifications(NotificationPrefs prefs);
  Future<PrivacyPrefs> privacy();
  Future<void> savePrivacy(PrivacyPrefs prefs);
}

class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository(this._client);
  final SupabaseClient _client;

  String get _me {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthFailure('Log in again to continue.');
    return id;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const AuthFailure('That username is taken. Try another one.');
      }
      if (e.code == '23514') {
        throw const AuthFailure('Check the highlighted details and try again.');
      }
      throw const AuthFailure('Something went wrong saving. Try again.');
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on StorageException {
      throw const AuthFailure("Your photo didn't upload. Try a smaller image.");
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  @override
  Future<AccountDetails> account() => _guard(() async {
    final r = await _client
        .from('profiles')
        .select('full_name, username, bio, gender, avatar_url')
        .eq('id', _me)
        .single();
    return AccountDetails(
      fullName: r['full_name'] as String? ?? '',
      username: r['username'] as String? ?? '',
      bio: r['bio'] as String? ?? '',
      gender: Gender.fromId(r['gender'] as String?),
      avatarUrl: r['avatar_url'] as String?,
    );
  });

  @override
  Future<void> saveAccount(AccountDetails d) => _guard(
    () => _client
        .from('profiles')
        .update({
          'full_name': d.fullName.trim(),
          'username': d.username.trim(),
          'bio': d.bio.trim().isEmpty ? null : d.bio.trim(),
          'gender': d.gender.id,
        })
        .eq('id', _me),
  );

  @override
  Future<String> uploadAvatar(
    Uint8List bytes,
    String extension,
  ) => _guard(() async {
    final path = '$_me/avatar.$extension';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$extension',
          ),
        );
    // Cache-bust so the new photo shows straight away.
    final url =
        '${_client.storage.from('avatars').getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
    await _client.from('profiles').update({'avatar_url': url}).eq('id', _me);
    return url;
  });

  @override
  Future<PrivateInfo> privateInfo() => _guard(() async {
    final user = _client.auth.currentUser!;
    final r = await _client
        .from('account_private')
        .select('birthday, country_code')
        .eq('id', _me)
        .single();
    final birthday = r['birthday'] as String?;
    return PrivateInfo(
      email: user.email ?? '',
      phone: user.phone ?? '',
      birthday: birthday == null ? null : DateTime.parse(birthday),
      country: Country.fromCode(r['country_code'] as String?),
    );
  });

  @override
  Future<void> changeEmail(String email) =>
      _guard(() => _client.auth.updateUser(UserAttributes(email: email)));

  @override
  Future<NotificationPrefs> notifications() => _guard(() async {
    final r = await _client
        .from('notification_settings')
        .select()
        .eq('user_id', _me)
        .maybeSingle();
    if (r == null) return const NotificationPrefs();
    return NotificationPrefs(
      meetReminders: r['meet_reminders'] as bool,
      courtCalls: r['court_calls'] as bool,
      messages: r['messages'] as bool,
      newFollowers: r['new_followers'] as bool,
      offersAndNews: r['offers_and_news'] as bool,
    );
  });

  @override
  Future<void> saveNotifications(NotificationPrefs p) => _guard(
    () => _client.from('notification_settings').upsert({
      'user_id': _me,
      'meet_reminders': p.meetReminders,
      'court_calls': p.courtCalls,
      'messages': p.messages,
      'new_followers': p.newFollowers,
      'offers_and_news': p.offersAndNews,
    }),
  );

  @override
  Future<PrivacyPrefs> privacy() => _guard(() async {
    final r = await _client
        .from('profiles')
        .select(
          'visibility, show_level, findable_by_phone, share_location_at_meets',
        )
        .eq('id', _me)
        .single();
    return PrivacyPrefs(
      visibility: ProfileVisibility.fromId(r['visibility'] as String?),
      showLevel: r['show_level'] as bool,
      findableByPhone: r['findable_by_phone'] as bool,
      shareLocationAtMeets: r['share_location_at_meets'] as bool,
    );
  });

  @override
  Future<void> savePrivacy(PrivacyPrefs p) => _guard(
    () => _client
        .from('profiles')
        .update({
          'visibility': p.visibility.id,
          'show_level': p.showLevel,
          'findable_by_phone': p.findableByPhone,
          'share_location_at_meets': p.shareLocationAtMeets,
        })
        .eq('id', _me),
  );
}

class DemoSettingsRepository implements SettingsRepository {
  DemoSettingsRepository(this._profiles);

  /// Shares the demo profile so edits show on the Profile tab.
  final DemoProfileRepository _profiles;
  Gender _gender = Gender.preferNotToSay;
  NotificationPrefs _notifications = const NotificationPrefs();
  PrivacyPrefs _privacy = const PrivacyPrefs();

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<AccountDetails> account() async {
    final p = _profiles.profile;
    return AccountDetails(
      fullName: p?.fullName ?? 'Aaron Ng',
      username: p?.username ?? 'aaronng',
      bio: p?.bio ?? '',
      gender: _gender,
      avatarUrl: p?.avatarUrl,
    );
  }

  @override
  Future<void> saveAccount(AccountDetails d) async {
    await _tick();
    _gender = d.gender;
    final p = _profiles.profile;
    if (p != null) {
      _profiles.profile = p.copyWith(
        fullName: d.fullName.trim(),
        username: d.username.trim(),
        bio: d.bio.trim().isEmpty ? null : d.bio.trim(),
      );
    }
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, String extension) async {
    await _tick();
    throw const AuthFailure('Photos upload once Supabase is connected.');
  }

  @override
  Future<PrivateInfo> privateInfo() async => PrivateInfo(
    email: 'aaron@example.com',
    phone: '+6591234567',
    birthday: DateTime(1996, 3, 14),
  );

  @override
  Future<void> changeEmail(String email) => _tick();

  @override
  Future<NotificationPrefs> notifications() async => _notifications;

  @override
  Future<void> saveNotifications(NotificationPrefs p) async =>
      _notifications = p;

  @override
  Future<PrivacyPrefs> privacy() async => _privacy;

  @override
  Future<void> savePrivacy(PrivacyPrefs p) async => _privacy = p;
}
