import '../../../core/domain/code_rules.dart';
import '../../../core/domain/country.dart';

/// Where a 6-digit code went, for the wording of every code screen.
enum CodeTarget { mobile, email, username }

/// "Check your messages" after an SMS, "Check your email" after an email.
String codeTitle(CodeTarget target) => switch (target) {
  CodeTarget.mobile => 'Check your messages',
  CodeTarget.email => 'Check your email',
  CodeTarget.username => 'Check your email or messages',
};

/// Names what the player typed. A username's code goes to the email or mobile
/// behind it, which is never shown, so nothing about the account leaks.
String codeLead(CodeTarget target, String destination) {
  final to = switch (target) {
    CodeTarget.mobile => displayPhone(destination),
    CodeTarget.email => destination,
    CodeTarget.username => 'the email or mobile on @$destination',
  };
  return 'We sent a 6-digit code to $to. '
      'It works for ${CodeRules.minutes} minutes.';
}

/// "+6580000003" → "+65 8000 0003".
String displayPhone(String phone) {
  final compact = phone.replaceAll(' ', '');
  for (final country in Country.values) {
    if (!compact.startsWith(country.dialCode)) continue;
    final rest = compact.substring(country.dialCode.length);
    final grouped = rest.length == 8
        ? '${rest.substring(0, 4)} ${rest.substring(4)}'
        : rest;
    return '${country.dialCode} $grouped';
  }
  return phone;
}
