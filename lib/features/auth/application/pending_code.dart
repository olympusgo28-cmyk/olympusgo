import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../presentation/code_copy.dart';

part 'pending_code.freezed.dart';
part 'pending_code.g.dart';

/// Where the last 6-digit code was sent, so the code screen can verify
/// and resend it.
@freezed
abstract class PendingCode with _$PendingCode {
  const factory PendingCode({
    required CodeTarget target,
    required String destination,
  }) = _PendingCode;
}

@Riverpod(keepAlive: true)
class PendingCodeController extends _$PendingCodeController {
  @override
  PendingCode? build() => null;

  /// A mobile always asks for a sign-up code: a number with no account gets
  /// one and then onboarding, a number with an account simply logs in, and
  /// the answer is the same either way (Q247, R-ACC-4). Email and username
  /// only log in.
  Future<void> send(CodeTarget target, String destination) async {
    await ref
        .read(authRepositoryProvider)
        .sendCode(destination, signUp: target == CodeTarget.mobile);
    state = PendingCode(target: target, destination: destination);
  }

  Future<void> resend() async {
    final p = state;
    if (p != null) await send(p.target, p.destination);
  }

  Future<void> verify(String code) async {
    final p = state;
    if (p == null) return;
    await ref.read(authRepositoryProvider).verifyCode(p.destination, code);
  }
}
