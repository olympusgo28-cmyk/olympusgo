import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/avatar_address.dart';
import '../../../core/domain/country.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../domain/settings_models.dart';

/// The signed-in player's own account, personal details and preferences.
abstract interface class SettingsRepository {
  Future<AccountDetails> account();

  /// Writes only the details given; the others stay as they are, so a
  /// change made elsewhere is never overwritten with an old value.
  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    Gender? gender,
  });

  /// Uploads a new profile photo and returns its public URL.
  Future<String> uploadAvatar(Uint8List bytes, String extension);

  /// Clears the profile photo and deletes its file.
  Future<void> removeAvatar();

  Future<PrivateInfo> privateInfo();

  /// Sets the country for currency, emergency number and local rules.
  Future<void> saveCountry(Country country);

  /// Starts an email change; Supabase emails a confirmation link.

  Future<NotificationPrefs> notifications();
  Future<void> saveNotifications(NotificationPrefs prefs);
  Future<PrivacyPrefs> privacy();
  Future<void> savePrivacy(PrivacyPrefs prefs);

  /// Closes the account now and returns the day it is erased, unless the
  /// player logs in before then and keeps it (R-ACC-11, R-REF-18).
  Future<DateTime> requestDeletion(String? reason);

  /// Undoes [requestDeletion].
  Future<void> keepAccount();
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
  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    Gender? gender,
  }) => _guard(
    () => _client
        .from('profiles')
        .update({
          'full_name': ?fullName?.trim(),
          'username': ?username?.trim(),
          if (bio != null) 'bio': bio.trim().isEmpty ? null : bio.trim(),
          'gender': ?gender?.id,
        })
        .eq('id', _me),
  );

  @override
  Future<void> saveCountry(Country country) => _guard(
    () => _client.rpc('set_country', params: {'p_country': country.code}),
  );

  @override
  Future<String> uploadAvatar(Uint8List bytes, String extension) => _guard(
    () async {
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
      // A path with no host; the database accepts nothing else (Q267). The
      // number makes the new photo show straight away.
      final url = storedAvatarPath(
        _me,
        extension,
        DateTime.now().millisecondsSinceEpoch,
      );
      await _client.from('profiles').update({'avatar_url': url}).eq('id', _me);
      return url;
    },
  );

  @override
  Future<void> removeAvatar() async {
    const failed = AuthFailure("Your photo wasn't removed. Try again.");
    try {
      final bucket = _client.storage.from('avatars');
      // The files go first, so a photo is never left readable after the
      // profile stops pointing at it. Both names an upload can have.
      await bucket.remove(['$_me/avatar.jpeg', '$_me/avatar.png']);
      // remove() says nothing when a file stays, so look again.
      final left = await bucket.list(
        path: _me,
        searchOptions: const SearchOptions(search: 'avatar.'),
      );
      if (left.isNotEmpty) throw failed;
      await _client.from('profiles').update({'avatar_url': null}).eq('id', _me);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw failed;
    }
  }

  @override
  Future<PrivateInfo> privateInfo() => _guard(() async {
    final r = await _client
        .from('account_private')
        .select('birthday, country_code, identity_verified_at, mobile, email')
        .eq('id', _me)
        .single();
    final birthday = r['birthday'] as String?;
    return PrivateInfo(
      email: r['email'] as String? ?? '',
      phone: r['mobile'] as String? ?? '',
      birthday: birthday == null ? null : DateTime.parse(birthday),
      country: Country.fromCode(r['country_code'] as String?),
      identityVerified: r['identity_verified_at'] != null,
    );
  });

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

  /// The database says in plain words when something must be handed over
  /// first, and that reaches the player as it is.
  Future<T> _deletionGuard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  @override
  Future<DateTime> requestDeletion(String? reason) => _deletionGuard(() async {
    final r = await _client.rpc(
      'account_delete_request',
      params: {'p_reason': reason},
    ) as Map<String, dynamic>;
    return DateTime.parse(r['erase_after'] as String);
  });

  @override
  Future<void> keepAccount() =>
      _deletionGuard(() => _client.rpc('account_delete_cancel'));
}

class DemoSettingsRepository implements SettingsRepository {
  @override
  Future<DateTime> requestDeletion(String? reason) async {
    await _tick();
    return DateTime.now().add(const Duration(days: 30));
  }

  @override
  Future<void> keepAccount() => _tick();

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
  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    Gender? gender,
  }) async {
    await _tick();
    if (gender != null) _gender = gender;
    final p = _profiles.profile;
    if (p != null) {
      _profiles.profile = p.copyWith(
        fullName: fullName?.trim() ?? p.fullName,
        username: username?.trim() ?? p.username,
        bio: bio == null ? p.bio : (bio.trim().isEmpty ? null : bio.trim()),
      );
    }
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, String extension) async {
    await _tick();
    throw const AuthFailure('Photos upload once Supabase is connected.');
  }

  @override
  Future<void> removeAvatar() async {
    await _tick();
    final p = _profiles.profile;
    if (p != null) _profiles.profile = p.copyWith(avatarUrl: null);
  }

  @override
  Future<PrivateInfo> privateInfo() async => PrivateInfo(
    email: 'aaron@example.com',
    phone: '+6591234567',
    birthday: DateTime(1996, 3, 14),
    country: _country,
    identityVerified: true,
  );

  Country _country = Country.singapore;

  @override
  Future<void> saveCountry(Country country) async {
    await _tick();
    _country = country;
  }

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
