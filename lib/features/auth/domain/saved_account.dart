import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_account.freezed.dart';
part 'saved_account.g.dart';

/// A tile on the Welcome screen. Holds only what the tile shows; the refresh
/// token is kept separately behind Face ID.
@freezed
abstract class SavedAccount with _$SavedAccount {
  const factory SavedAccount({
    required String userId,
    required String displayName,
    String? avatarUrl,
    required String maskedIdentifier,
  }) = _SavedAccount;

  factory SavedAccount.fromJson(Map<String, dynamic> json) =>
      _$SavedAccountFromJson(json);
}
