/// Field checks, worded the way the screens show them.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _username = RegExp(r'^[A-Za-z0-9_]{3,30}$');

  static String? email(String v) {
    if (v.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(v)) return 'Enter an email like name@example.com.';
    return null;
  }

  static String? username(String v) {
    if (v.length < 3) return 'Use at least 3 characters.';
    if (v.length > 30) return 'Use 30 characters or fewer.';
    if (!_username.hasMatch(v)) {
      return 'Use only letters, numbers and underscores.';
    }
    return null;
  }

  static String? mobile(String digits) {
    if (digits.length < 7 || digits.length > 12) {
      return 'Enter a valid mobile number.';
    }
    return null;
  }
}
