import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';

part 'pending_code.freezed.dart';
part 'pending_code.g.dart';

enum CodeChannel { signupMobile, loginMobile, loginEmail, loginUsername }

/// Where the last 6-digit code was sent, so the code screen can verify
/// and resend it.
@freezed
abstract class PendingCode with _$PendingCode {
  const factory PendingCode({
    required CodeChannel channel,
    required String destination,
  }) = _PendingCode;
}

@Riverpod(keepAlive: true)
class PendingCodeController extends _$PendingCodeController {
  @override
  PendingCode? build() => null;

  Future<void> send(CodeChannel channel, String destination) async {
    await ref
        .read(authRepositoryProvider)
        .sendCode(destination, signUp: channel == CodeChannel.signupMobile);
    state = PendingCode(channel: channel, destination: destination);
  }

  Future<void> resend() async {
    final p = state;
    if (p != null) await send(p.channel, p.destination);
  }

  Future<void> verify(String code) async {
    final p = state;
    if (p == null) return;
    await ref.read(authRepositoryProvider).verifyCode(p.destination, code);
  }
}
