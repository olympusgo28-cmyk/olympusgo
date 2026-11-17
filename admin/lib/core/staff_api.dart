import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A problem to show staff, worded for the screen.
class StaffFailure implements Exception {
  const StaffFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads go straight to `staff_*` database functions. Writes go through the
/// admin-action Edge Function. Both check the role and MFA in the database.
class StaffApi {
  StaffApi(this._client);
  final SupabaseClient _client;

  Future<Object?> read(String function, [Map<String, dynamic>? params]) async {
    try {
      return await _client.rpc(function, params: params);
    } on PostgrestException catch (e) {
      throw StaffFailure(
        e.code == 'P0001' ? e.message : 'Something went wrong. Try again.',
      );
    }
  }

  Future<Object?> act(String action, Map<String, dynamic> params) async {
    try {
      final res = await _client.functions.invoke(
        'admin-action',
        body: {'action': action, 'params': params},
      );
      return (res.data as Map)['data'];
    } on FunctionException catch (e) {
      final details = e.details;
      throw StaffFailure(
        details is Map && details['error'] is String
            ? details['error'] as String
            : 'Something went wrong. Try again.',
      );
    }
  }

  /// A short link to one video. The database records every look.
  Future<String> postVideoUrl(String post) async {
    try {
      final res = await _client.functions.invoke(
        'feed-media',
        body: {'action': 'staff_play', 'post': post},
      );
      return (res.data as Map)['url'] as String;
    } on FunctionException catch (e) {
      final details = e.details;
      throw StaffFailure(
        details is Map && details['error'] is String
            ? details['error'] as String
            : 'We couldn\'t open that video.',
      );
    }
  }

  /// A link to a verification file, good for a minute.
  Future<String> documentUrl(String path) async {
    try {
      return await _client.storage
          .from('verification-docs')
          .createSignedUrl(path, 60);
    } on StorageException {
      throw const StaffFailure('We couldn\'t open that file.');
    }
  }

  /// Files go once the check is done.
  Future<void> removeDocument(String path) async {
    try {
      await _client.storage.from('verification-docs').remove([path]);
    } on StorageException {
      throw const StaffFailure('We couldn\'t delete that file. Try again.');
    }
  }
}

final staffApiProvider = Provider((ref) => StaffApi(Supabase.instance.client));
