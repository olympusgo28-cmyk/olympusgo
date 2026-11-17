/// Sign-in and contact codes (R-ACC-2, R-ACC-3, Q248). The server's
/// `auth.code_minutes` setting holds the same number; keep them in step.
abstract final class CodeRules {
  /// How long a code works, and how long before a new one can be sent.
  static const minutes = 3;
  static const resendSeconds = minutes * 60;
  static const length = 6;
}
