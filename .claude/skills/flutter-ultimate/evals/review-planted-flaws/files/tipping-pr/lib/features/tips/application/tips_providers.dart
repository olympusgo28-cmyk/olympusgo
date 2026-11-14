import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/tips_repository.dart';

part 'tips_providers.g.dart';

@riverpod
TipsRepository tipsRepository(Ref ref) =>
    TipsRepository(Supabase.instance.client);

@riverpod
Future<List<Tip>> myTips(Ref ref) => ref.watch(tipsRepositoryProvider).myTips();

@riverpod
class TipController extends _$TipController {
  @override
  FutureOr<String?> build() => null;

  Future<void> send({
    required String toCoach,
    required double amount,
    String? note,
  }) async {
    state = const AsyncLoading();
    final id = await ref
        .read(tipsRepositoryProvider)
        .sendTip(toCoach: toCoach, amount: amount, note: note);
    state = AsyncData(id);
  }
}
