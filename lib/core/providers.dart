import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/venues/data/venue_repository.dart';
import '../features/game/data/game_repository.dart';
import '../features/inbox/data/updates_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/biometric_vault.dart';
import '../features/clubs/data/club_repository.dart';
import '../features/clubs/data/demo_club_repository.dart';
import '../features/clubs/data/supabase_club_repository.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/domain/profile.dart';
import '../features/safety/data/safety_repository.dart';
import '../features/play/data/competition_repository.dart';
import '../features/play/data/payment_gateway.dart';
import '../features/play/data/play_repository.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/shop/data/shop_repository.dart';
import '../features/wallet/data/wallet_repository.dart';
import '../features/social/data/chat_repository.dart';
import '../features/social/data/social_repository.dart';
import 'config/env.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
BiometricVault biometricVault(Ref ref) => BiometricVault();

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  if (!Env.hasSupabase) return DemoAuthRepository();
  final repo = SupabaseAuthRepository(
    Supabase.instance.client,
    ref.watch(biometricVaultProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => Env.hasSupabase
    ? SupabaseProfileRepository(Supabase.instance.client)
    : DemoProfileRepository();

@Riverpod(keepAlive: true)
SocialRepository socialRepository(Ref ref) => Env.hasSupabase
    ? SupabaseSocialRepository(Supabase.instance.client)
    : DemoSocialRepository();

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) => Env.hasSupabase
    ? SupabaseChatRepository(Supabase.instance.client)
    : DemoChatRepository();

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => Env.hasSupabase
    ? SupabaseSettingsRepository(Supabase.instance.client)
    : DemoSettingsRepository(
        ref.watch(profileRepositoryProvider) as DemoProfileRepository,
      );

@Riverpod(keepAlive: true)
PlayRepository playRepository(Ref ref) => Env.hasSupabase
    ? SupabasePlayRepository(Supabase.instance.client)
    : DemoPlayRepository();

@Riverpod(keepAlive: true)
PaymentGateway paymentGateway(Ref ref) => Env.hasSupabase
    ? SupabasePaymentGateway()
    : DemoPaymentGateway(
        ref.watch(playRepositoryProvider) as DemoPlayRepository,
      );

@Riverpod(keepAlive: true)
TournamentRepository tournamentRepository(Ref ref) => Env.hasSupabase
    ? SupabaseTournamentRepository(
        Supabase.instance.client,
        ref.watch(playRepositoryProvider),
      )
    : DemoTournamentRepository(
        ref.watch(playRepositoryProvider) as DemoPlayRepository,
      );

@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) => Env.hasSupabase
    ? SupabaseEventRepository(
        Supabase.instance.client,
        ref.watch(playRepositoryProvider),
      )
    : DemoEventRepository(
        ref.watch(playRepositoryProvider) as DemoPlayRepository,
      );

@Riverpod(keepAlive: true)
ClubRepository clubRepository(Ref ref) => Env.hasSupabase
    ? SupabaseClubRepository(
        Supabase.instance.client,
        ref.watch(playRepositoryProvider) as SupabasePlayRepository,
      )
    : DemoClubRepository(
        ref.watch(playRepositoryProvider) as DemoPlayRepository,
      );

@Riverpod(keepAlive: true)
ShopRepository shopRepository(Ref ref) => Env.hasSupabase
    ? SupabaseShopRepository(Supabase.instance.client)
    : DemoShopRepository(
        ref.watch(walletRepositoryProvider) as DemoWalletRepository,
      );

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) => Env.hasSupabase
    ? SupabaseWalletRepository(Supabase.instance.client)
    : DemoWalletRepository();

@Riverpod(keepAlive: true)
VenueRepository venueRepository(Ref ref) => Env.hasSupabase
    ? SupabaseVenueRepository(Supabase.instance.client)
    : DemoVenueRepository();

@Riverpod(keepAlive: true)
GameRepository gameRepository(Ref ref) => Env.hasSupabase
    ? SupabaseGameRepository(Supabase.instance.client)
    : DemoGameRepository();

@Riverpod(keepAlive: true)
SafetyRepository safetyRepository(Ref ref) => Env.hasSupabase
    ? SupabaseSafetyRepository(Supabase.instance.client)
    : DemoSafetyRepository();

@Riverpod(keepAlive: true)
UpdatesRepository updatesRepository(Ref ref) => Env.hasSupabase
    ? SupabaseUpdatesRepository(Supabase.instance.client)
    : DemoUpdatesRepository();

/// The signed-in user's id, or null when signed out.
@Riverpod(keepAlive: true)
Stream<String?> currentUserId(Ref ref) async* {
  final auth = ref.watch(authRepositoryProvider);
  yield auth.currentUserId;
  yield* auth.userIdChanges;
}

/// The signed-in player's profile; null when signed out.
@Riverpod(keepAlive: true)
class SessionProfile extends _$SessionProfile {
  @override
  Future<Profile?> build() async {
    final userId = await ref.watch(currentUserIdProvider.future);
    if (userId == null) return null;
    return ref.watch(profileRepositoryProvider).fetch(userId);
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(build);
  }
}

/// The signed-in player's sports and levels.
@riverpod
Future<ProfileSummary?> mySummary(Ref ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).summary(userId);
}

@riverpod
Future<List<PlayerSport>> mySports(Ref ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return const [];
  ref.watch(sessionProfileProvider);
  return ref.watch(profileRepositoryProvider).sports(userId);
}
