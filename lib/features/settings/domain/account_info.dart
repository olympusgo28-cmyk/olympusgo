import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/country.dart';
import 'settings_models.dart';

part 'account_info.freezed.dart';

/// What the Account information screen shows. Only the owner sees it. The
/// list masks the contacts; their edit screens show them in full.
@freezed
abstract class AccountInfo with _$AccountInfo {
  const AccountInfo._();

  const factory AccountInfo({
    @Default('') String email,
    @Default('') String phone,
    DateTime? birthday,
    @Default(Country.singapore) Country region,
  }) = _AccountInfo;

  factory AccountInfo.from(PrivateInfo p) => AccountInfo(
    email: p.email,
    phone: p.phone,
    birthday: p.birthday,
    region: p.country,
  );

  /// "n***8@gmail.com", or null when there is no email.
  String? get maskedEmail => email.isEmpty ? null : maskEmail(email);

  /// "+65 •••• 1234", or null when there is no mobile.
  String? get maskedPhone => phone.isEmpty ? null : maskPhone(phone);

  /// What a screen reader says for [maskedPhone]: "+65, ending in 1234".
  String? get spokenPhone => phone.isEmpty ? null : spokenMaskedPhone(phone);

  /// "8 June 1996".
  String? get birthdayText {
    final d = birthday;
    return d == null ? null : '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// The mobile's own dialling code, which can differ from the account's
  /// region (a Malaysian number on a Singapore account, Q254).
  Country get phoneCountry => Country.fromPhone(_e164(phone)) ?? region;

  /// No contact details or birthday, should this ever reach a log (golden
  /// rule 8).
  @override
  String toString() => 'AccountInfo(region: ${region.code})';
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _e164(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? '' : '+$digits';
}

String _lastFour(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
}

/// Keeps the first and last character before the @:
/// "nicholas8@example.com" is "n***8@example.com". A name of one or two
/// characters keeps only the first ("ab@example.com" is "a***@example.com"),
/// so the mask never shows the whole name.
String maskEmail(String email) {
  final at = email.lastIndexOf('@');
  if (at <= 0) return '***';
  final local = email.substring(0, at).characters;
  final last = local.length > 2 ? local.last : '';
  return '${local.first}***$last${email.substring(at)}';
}

/// The dialling code and the last 4 digits: "+65 •••• 1234". A number with
/// no known dialling code shows only "•••• 1234".
String maskPhone(String phone) {
  final dial = Country.fromPhone(_e164(phone))?.dialCode;
  return [?dial, '••••', _lastFour(phone)].join(' ');
}

/// [maskPhone] for a screen reader, which would read each dot aloud.
String spokenMaskedPhone(String phone) {
  final dial = Country.fromPhone(_e164(phone))?.dialCode;
  return [?dial, 'ending in ${_lastFour(phone)}'].join(', ');
}
