import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/academy/presentation/academy_screens.dart';
import '../../features/academy/presentation/coach_screens.dart';
import '../../features/academy/presentation/create_academy_screens.dart';
import '../../features/academy/presentation/parent_screens.dart';
import '../../features/auth/presentation/code_screen.dart';
import '../../features/auth/presentation/log_in_screen.dart';
import '../../features/auth/presentation/recovery_screens.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/clubs/data/club_repository.dart';
import '../../features/clubs/presentation/club_info_screens.dart';
import '../../features/clubs/presentation/club_admin_screens.dart';
import '../../features/academy/presentation/academy_more_screens.dart';
import '../../features/game/presentation/creator_screens.dart';
import '../../features/game/presentation/game_screens.dart';
import '../../features/game/presentation/gear_screens.dart';
import '../../features/settings/presentation/account_screens.dart';
import '../../features/shop/domain/commerce_models.dart';
import '../../features/shop/presentation/order_screens.dart';
import '../../features/shop/presentation/seller_screens.dart';
import '../../features/shop/presentation/shop_screens.dart';
import '../../features/wallet/presentation/wallet_screens.dart';
import '../../features/clubs/presentation/club_overview_screen.dart';
import '../../features/clubs/presentation/club_page_screen.dart';
import '../../features/clubs/presentation/club_role_screens.dart';
import '../../features/clubs/presentation/team_screens.dart';
import '../../features/clubs/presentation/clubs_home_screen.dart';
import '../../features/clubs/presentation/create_group_screens.dart';
import '../../features/clubs/presentation/group_chat_screens.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/onboarding/domain/sport.dart';
import '../../features/onboarding/presentation/account_screens.dart';
import '../../features/onboarding/presentation/name_birthday_screens.dart';
import '../../features/onboarding/presentation/sports_screens.dart';
import '../../features/play/domain/activity.dart';
import '../../features/play/domain/hub.dart';
import '../../features/play/presentation/create_screens.dart';
import '../../features/play/presentation/create_competition_screens.dart';
import '../../features/play/presentation/create_meet_screens.dart';
import '../../features/play/presentation/event_screens.dart';
import '../../features/play/presentation/tournament_host_screens.dart';
import '../../features/play/presentation/tournament_screens.dart';
import '../../features/play/presentation/meet_action_screens.dart';
import '../../features/play/presentation/meet_host_screens.dart';
import '../../features/play/presentation/score_screens.dart';
import '../../features/play/presentation/meet_detail_screen.dart';
import '../../features/play/presentation/play_screen.dart';
import '../../features/profile/presentation/passport_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/scan/scan_player_screen.dart';
import '../../features/scan/scan_screen.dart';
import '../../features/settings/presentation/settings_screens.dart';
import '../../features/social/presentation/chat_screen.dart';
import '../../features/social/presentation/connections_screens.dart';
import '../../features/social/presentation/other_profile_screens.dart';
import '../../features/social/presentation/search_screens.dart';
import '../../features/shell/main_shell.dart';
import '../../features/venues/presentation/venue_screens.dart';
import '../../features/profile/presentation/passport_history_screen.dart';
import '../../features/safety/presentation/legal_screens.dart';
import '../../features/safety/presentation/safety_screens.dart';
import '../../features/home/edit_categories_screen.dart';
import '../navigation/breadcrumbs.dart';
import '../providers.dart';
import '../share.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// The app-wide navigator, above the tab shell. Detail screens that should
/// cover the tab bar use it as their parent.
final rootKey = GlobalKey<NavigatorState>();

Page<void> cupertinoPage(GoRouterState state, Widget child) =>
    CupertinoPage<void>(key: state.pageKey, child: child);

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Re-run redirects whenever sign-in or the profile changes.
  final refresh = ValueNotifier(0);
  ref.listen(currentUserIdProvider, (_, _) => refresh.value++);
  ref.listen(sessionProfileProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  // A share link opened while signed out, opened once they're in.
  String? pending;

  String? redirect(BuildContext context, GoRouterState state) {
    final userId = ref.read(currentUserIdProvider).value;
    // A share link opened the app: send it to the matching screen.
    if (state.error != null) {
      final to = Links.route(state.uri);
      if (to != null) {
        if (userId == null) pending = to;
        return to;
      }
    }
    final loc = state.matchedLocation;
    if (loc == Routes.splash) return null;
    if (Routes.openPrefixes.any(loc.startsWith)) return null;

    final isPublic = Routes.publicPrefixes.any(loc.startsWith);
    if (userId == null) {
      // Club invite links match a screen directly, so keep those too.
      if (loc.startsWith('/join/')) pending = state.uri.toString();
      return isPublic ? null : Routes.welcome;
    }

    final profile = ref.read(sessionProfileProvider);
    // Wait for the profile before deciding where a signed-in player belongs.
    if (profile.isLoading && !profile.hasValue) return null;
    final onboarded = profile.value?.onboardingCompleted ?? false;
    final inOnboarding = loc.startsWith('/onboarding') || loc == Routes.ready;

    if (onboarded && pending != null && !inOnboarding) {
      final to = pending;
      pending = null;
      if (to != state.uri.toString()) return to;
    }
    if (isPublic) return onboarded ? Routes.home : Routes.name;
    if (!onboarded && !inOnboarding) return Routes.name;
    if (onboarded && loc.startsWith('/onboarding')) return Routes.home;
    return null;
  }

  // CupertinoPage gives every screen the iOS slide and edge swipe-back.
  GoRoute page(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, pageBuilder: (_, s) => cupertinoPage(s, build(s)));

  String id(GoRouterState s) => s.pathParameters['id']!;

  final router = GoRouter(
    observers: [Crumbs.root],
    navigatorKey: rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      page(Routes.splash, (_) => const SplashScreen()),
      page(Routes.accountHub, (_) => const AccountHubScreen()),
      page(Routes.profileSports, (_) => const ProfileSportsScreen()),
      page(Routes.language, (_) => const LanguageScreen()),
      page(Routes.deleteAccount, (_) => const DeleteAccountScreen()),
      // Game.
      page(Routes.game, (_) => const GameHomeScreen()),
      page(Routes.leaderboards, (_) => const LeaderboardsScreen()),
      page('/game/:id', (s) => CampaignScreen(id: s.pathParameters['id']!)),
      page(
        '/game/:id/setup',
        (s) => CameraSetupScreen(id: s.pathParameters['id']!),
      ),
      page(
        '/game/:id/attempt',
        (s) => AttemptScreen(id: s.pathParameters['id']!),
      ),
      page(
        '/game/:id/review',
        (s) => AttemptReviewScreen(
          id: s.pathParameters['id']!,
          recorded: s.extra as (int, int)?,
        ),
      ),
      page(Routes.creatorEarnings, (_) => const CreatorEarningsScreen()),
      page(Routes.creatorChallenges, (_) => const CreatorChallengesScreen()),
      page(Routes.newChallenge, (_) => const NewChallengeScreen()),
      page(
        '/creators/:id',
        (s) => CreatorProfileScreen(id: s.pathParameters['id']!),
      ),
      page(Routes.gear, (_) => const MyGearScreen()),
      page('/gear/:id', (s) => GearItemScreen(id: s.pathParameters['id']!)),
      page(
        '/gear/:id/edit',
        (s) => GearEditScreen(id: s.pathParameters['id']!),
      ),
      // Academy tools.
      page(Routes.coachPay, (_) => const CoachPayScreen()),
      page('/academies/:id/settings', (s) => AcademySettingsScreen(id: id(s))),
      page('/academies/:id/messages', (s) => AcademyMessagesScreen(id: id(s))),
      page('/academies/:id/close', (s) => AcademyCloseScreen(id: id(s))),
      page(
        '/academies/:id/classes/:class/change',
        (s) =>
            ChangeClassScreen(id: id(s), classId: s.pathParameters['class']!),
      ),
      page('/academies/:id/invite', (s) => InviteStudentsScreen(id: id(s))),
      page('/academies/:id/curriculum', (s) => CurriculumScreen(id: id(s))),
      page(
        '/academies/:id/curriculum/:level/:week',
        (s) => LessonPlanEditScreen(
          id: id(s),
          level: int.parse(s.pathParameters['level']!),
          week: int.parse(s.pathParameters['week']!),
        ),
      ),
      page('/students/:id/note', (s) => ParentNoteScreen(studentId: id(s))),
      page(
        '/students/:id/attendance',
        (s) => AttendanceHistoryScreen(studentId: id(s)),
      ),
      page(
        '/students/:id/consent',
        (s) => FilmingConsentScreen(studentId: id(s)),
      ),
      // Wallet.
      page(Routes.wallet, (_) => const WalletScreen()),
      page(Routes.walletWithdraw, (_) => const WithdrawScreen()),
      page(Routes.points, (_) => const PointsWalletScreen()),
      page(Routes.receipts, (_) => const ReceiptsScreen()),
      page(Routes.earnings, (_) => const EarningsScreen()),
      page(
        '/wallet/earnings/:id',
        (s) => EarningsDetailScreen(id: s.pathParameters['id']!),
      ),
      page(Routes.payout, (_) => const PayoutScreen()),
      page(Routes.payoutAccount, (_) => const PayoutAccountScreen()),
      // Shop.
      page(Routes.shop, (_) => const ShopHomeScreen()),
      page(
        '/shop/malls/:id',
        (s) => MallPageScreen(id: s.pathParameters['id']!),
      ),
      page(
        '/shop/products/:id',
        (s) => ProductPageScreen(id: s.pathParameters['id']!),
      ),
      page(
        '/shop/videos/:id',
        (s) => ShopVideoScreen(id: s.pathParameters['id']!),
      ),
      page(
        '/shop/live/:id',
        (s) => ShopLiveScreen(id: s.pathParameters['id']!),
      ),
      page(Routes.cart, (_) => const CartScreen()),
      page(Routes.checkout, (s) => CheckoutScreen(only: s.extra as CartLine?)),
      page(Routes.addresses, (_) => const AddressesScreen()),
      page(Routes.addressNew, (_) => const AddressNewScreen()),
      page(
        '/shop/orders',
        (s) => OrdersScreen(tab: s.uri.queryParameters['tab'] ?? 'all'),
      ),
      page(
        '/shop/orders/:id',
        (s) => OrderDetailScreen(id: s.pathParameters['id']!),
      ),
      page(
        '/shop/orders/:id/cancel',
        (s) => OrderCancelScreen(id: s.pathParameters['id']!),
      ),
      page(
        '/shop/orders/:id/refund',
        (s) => RefundStatusScreen(id: s.pathParameters['id']!),
      ),
      page(
        '/shop/report',
        (s) => ReportListingScreen(what: s.uri.queryParameters['what'] ?? ''),
      ),
      page(
        '/shop/services/:id',
        (s) => ServiceBookScreen(id: s.pathParameters['id']!),
      ),
      page(Routes.seller, (_) => const SellerHomeScreen()),
      page(Routes.sellerOrders, (_) => const SellerOrdersScreen()),
      page(
        '/shop/seller/orders/:id',
        (s) => SellerOrderDetailScreen(id: s.pathParameters['id']!),
      ),
      page(Routes.sellerProducts, (_) => const SellerProductsScreen()),
      page(Routes.sellerLive, (_) => const SellerGoLiveScreen()),
      page(Routes.sellerVideo, (_) => const SellerUploadVideoScreen()),
      page(
        '/shop/seller/products/:id',
        (s) => SellerProductEditScreen(id: s.pathParameters['id']!),
      ),
      page(Routes.welcome, (_) => const WelcomeScreen()),
      page(Routes.signUp, (_) => const SignUpScreen()),
      page(Routes.signUpCode, (_) => const CodeScreen()),
      page(Routes.logIn, (_) => const LogInScreen(method: LoginMethod.email)),
      page(
        Routes.logInPhone,
        (_) => const LogInScreen(method: LoginMethod.phone),
      ),
      page(
        Routes.logInUsername,
        (_) => const LogInScreen(method: LoginMethod.username),
      ),
      page(Routes.logInCode, (_) => const CodeScreen()),
      page(Routes.recovery, (_) => const RecoveryScreen()),
      page(Routes.recoverySent, (_) => const RecoverySentScreen()),
      page(Routes.name, (_) => const FullNameScreen()),
      page(Routes.birthday, (_) => const BirthdayScreen()),
      page(Routes.parent, (_) => const ParentApprovalScreen()),
      page(Routes.sports, (_) => const SportsScreen()),
      page(Routes.skills, (_) => const SkillLevelScreen()),
      page(
        '${Routes.skills}/:sport',
        (s) =>
            SportSkillScreen(sport: Sport.fromId(s.pathParameters['sport']!)),
      ),
      page(Routes.username, (_) => const UsernameScreen()),
      page(Routes.mobile, (_) => const MobileNumberScreen()),
      page(Routes.mobileVerify, (_) => const VerifyMobileScreen()),
      page(Routes.ready, (_) => const ReadyScreen()),
      page(
        Routes.setupAccount,
        (_) => const AccountCentreScreen(onboarding: true),
      ),
      page(
        Routes.setupPersonal,
        (_) => const PersonalInfoScreen(onboarding: true),
      ),
      page(Routes.settings, (_) => const SettingsScreen()),
      page(Routes.accountCentre, (_) => const AccountCentreScreen()),
      page(Routes.personalInfo, (_) => const PersonalInfoScreen()),
      page(
        Routes.verifyPhoneChange,
        (s) => VerifyPhoneChangeScreen(phone: s.extra! as String),
      ),
      page(Routes.notifications, (_) => const NotificationsScreen()),
      page(Routes.privacy, (_) => const PrivacyScreen()),
      page(Routes.blocked, (_) => const BlockedPlayersScreen()),
      page(Routes.help, (_) => const HelpScreen()),
      page(Routes.communityRules, (_) => const CommunityRulesScreen()),
      page(
        '/profile/passport/history/:sport',
        (s) => PassportHistoryScreen(sport: s.pathParameters['sport']!),
      ),
      page(Routes.country, (_) => const CountryScreen()),
      page(Routes.identityCheck, (_) => const IdentityCheckScreen()),
      page(Routes.legal, (_) => const TermsPrivacyScreen()),
      page(Routes.refundRules, (_) => const RefundRulesScreen()),
      page(Routes.under18, (_) => const Under18ProtectionScreen()),
      page(Routes.legalNotice, (_) => const LegalNoticeScreen()),
      page(Routes.editCategories, (_) => const EditCategoriesScreen()),
      page(Routes.myReports, (_) => const MyReportsScreen()),
      page(
        '/settings/reports/:id',
        (s) => ReportStatusScreen(id: id(s), fromList: s.extra == true),
      ),
      page('/notices/:id', (s) => RemovalNoticeScreen(id: id(s))),
      page(Routes.logOut, (_) => const LogOutScreen()),
      page(
        '/players/:id',
        (s) => OtherProfileScreen(playerId: s.pathParameters['id']!),
      ),
      page(
        '/players/:id/report',
        (s) => ReportBlockScreen(playerId: s.pathParameters['id']!),
      ),
      page(
        '/players/:id/message',
        (s) => OpenChatScreen(playerId: s.pathParameters['id']!),
      ),
      page(
        '/scan/player/:username',
        (s) => ScanPlayerScreen(username: s.pathParameters['username']!),
      ),
      page(
        Routes.playAddSport,
        (s) => PlayAddSportScreen(
          tab: HubTab.fromId(s.uri.queryParameters['tab']),
        ),
      ),
      page(
        '/activities/:id',
        (s) => MeetDetailScreen(
          activityId: s.pathParameters['id']!,
          tab: s.uri.queryParameters['tab'],
        ),
      ),
      for (final (path, build) in <(String, Widget Function(String))>[
        ('register', (id) => TournamentRegisterScreen(activityId: id)),
        ('withdraw', (id) => TournamentWithdrawScreen(activityId: id)),
        ('results', (id) => TournamentResultsScreen(activityId: id)),
        ('manage', (id) => TournamentManageScreen(activityId: id)),
        ('entries', (id) => TournamentEntriesScreen(activityId: id)),
        ('check-in', (id) => TournamentCheckInScreen(activityId: id)),
        ('message', (id) => TournamentMessageScreen(activityId: id)),
        ('cancel', (id) => TournamentCancelScreen(activityId: id)),
      ])
        page('/tournaments/:id/$path', (s) => build(s.pathParameters['id']!)),
      for (final (path, build) in <(String, Widget Function(String))>[
        ('ticket', (id) => EventTicketScreen(activityId: id)),
        ('release', (id) => EventReleaseScreen(activityId: id)),
        ('manage', (id) => EventManageScreen(activityId: id)),
        ('cancel', (id) => EventCancelScreen(activityId: id)),
      ])
        page('/events/:id/$path', (s) => build(s.pathParameters['id']!)),
      page(
        '/events/:id/scan',
        (s) => ScanTicketScreen(
          activityId: id(s),
          code: s.uri.queryParameters['code'],
        ),
      ),
      page(Routes.myTickets, (_) => const MyTicketsScreen()),
      page(Routes.checkTickets, (_) => const CheckTicketsScreen()),
      page(
        '/activities/:id/guest',
        (s) => GuestScreen(activityId: s.pathParameters['id']!),
      ),
      page(
        '/activities/:id/waitlist',
        (s) => WaitlistScreen(activityId: s.pathParameters['id']!),
      ),
      page(
        '/activities/:id/players',
        (s) => MeetPlayersScreen(activityId: s.pathParameters['id']!),
      ),
      page(
        '/activities/:id/walk-in',
        (s) => MeetWalkInScreen(activityId: s.pathParameters['id']!),
      ),
      page(
        '/activities/:id/attendance',
        (s) => MeetAttendanceScreen(activityId: s.pathParameters['id']!),
      ),
      page(
        '/activities/:id/recap',
        (s) => MeetRecapScreen(activityId: s.pathParameters['id']!),
      ),
      page(
        '/activities/:id/cancel',
        (s) => MeetCancelScreen(activityId: s.pathParameters['id']!),
      ),
      page(
        '/activities/:id/score',
        (s) => ScoreEntryScreen(activityId: s.pathParameters['id']!),
      ),
      page(
        '/scores/:id',
        (s) => ScoreConfirmScreen(scoreId: s.pathParameters['id']!),
      ),
      page(
        '/scan/meet/:id',
        (s) => CheckInScreen(activityId: s.pathParameters['id']!),
      ),
      page(
        Routes.newMeetSport,
        (_) => const NewSportScreen(kind: ActivityKind.meet),
      ),
      page(Routes.newMeetBasics, (_) => const NewMeetDetailsScreen()),
      page(
        Routes.newEventSports,
        (_) => const NewSportScreen(kind: ActivityKind.event),
      ),
      page(Routes.newEventDetails, (_) => const NewEventScreen()),
      page(
        Routes.newTournSport,
        (_) => const NewSportScreen(kind: ActivityKind.tournament),
      ),
      page(Routes.newTournDetails, (_) => const NewTournamentScreen()),
      page(
        '/create/date/:field',
        (s) => PickDateScreen(field: s.pathParameters['field']!),
      ),
      page('/create/time/:field', (_) => const PickTimeScreen()),
      page(Routes.createVenue, (_) => const PickVenueScreen()),
      page(Routes.academies, (_) => const AcademiesScreen()),
      page(Routes.newAcademy, (_) => const NewAcademyScreen()),
      page(Routes.newAcademyLevels, (_) => const NewAcademyLevelsScreen()),
      page(Routes.newAcademyPolicies, (_) => const NewAcademyPoliciesScreen()),
      page(Routes.newAcademyVerify, (_) => const NewAcademyVerifyScreen()),
      page(Routes.newAcademyCoaches, (_) => const NewAcademyCoachesScreen()),
      page('/academies/:id', (s) => AcademyPageScreen(id: id(s))),
      page('/academies/:id/enrol', (s) => AcademyEnrolScreen(id: id(s))),
      page('/academies/:id/trial', (s) => TrialClassScreen(id: id(s))),
      page('/academies/:id/today', (s) => AcademyTodayScreen(id: id(s))),
      page('/academies/:id/classes', (s) => AcademyClassesScreen(id: id(s))),
      page('/academies/:id/requests', (s) => EnrolRequestsScreen(id: id(s))),
      page(
        '/academies/:id/classes/:class/session',
        (s) => ClassSessionScreen(
          academyId: id(s),
          classId: s.pathParameters['class']!,
        ),
      ),
      page(
        '/academies/:id/classes/:class/students',
        (s) => ClassRosterScreen(
          academyId: id(s),
          classId: s.pathParameters['class']!,
        ),
      ),
      page('/students/:id', (s) => StudentHomeScreen(id: id(s))),
      page('/students/:id/class', (s) => StudentClassScreen(id: id(s))),
      page('/students/:id/fees', (s) => StudentFeesScreen(id: id(s))),
      page('/students/:id/makeup', (s) => BookMakeupScreen(id: id(s))),
      page('/students/:id/progress', (s) => StudentProgressScreen(id: id(s))),
      page(Routes.venues, (_) => const VenuesScreen()),
      page('/venues/:id', (s) => VenuePageScreen(id: id(s))),
      page('/venues/:id/book', (s) => BookCourtScreen(venueId: id(s))),
      page('/court-bookings/:id', (s) => CourtBookingScreen(id: id(s))),
      page(
        '/court-bookings/:id/cancel',
        (s) => CancelCourtBookingScreen(id: id(s)),
      ),
      // Clubs. Literal paths come before /clubs/:id.
      page(
        Routes.clubs,
        (s) => ClubsHomeScreen(teams: s.uri.queryParameters['kind'] == 'teams'),
      ),
      page(Routes.createGroup, (_) => const CreateGroupTypeScreen()),
      page(Routes.newClub, (_) => const NewClubScreen()),
      page(Routes.newClubVenue, (_) => const PickVenueScreen(forClub: true)),
      page(Routes.newClubSports, (_) => const NewClubSportsScreen()),
      page(Routes.newClubLevels, (_) => const NewClubLevelsScreen()),
      page(Routes.newClubInvite, (_) => const NewClubInviteScreen()),
      page('/clubs/:id', (s) => ClubScreen(id: id(s))),
      page(
        '/join/:code',
        (s) => ClubInviteLinkScreen(code: s.pathParameters['code']!),
      ),
      page('/clubs/:id/about', (s) => ClubAboutScreen(id: id(s))),
      page('/clubs/:id/leaderboard', (s) => LeaderboardScreen(id: id(s))),
      page(
        '/clubs/:id/chat',
        (s) => GroupChatScreen(scope: ChatScope.club(id(s))),
      ),
      page(
        '/clubs/:id/chat/:message/report',
        (s) => ReportContentScreen.message(
          scope: ChatScope.club(id(s)),
          messageId: s.pathParameters['message']!,
        ),
      ),
      page(
        '/clubs/:id/announcements',
        (s) => AnnouncementsScreen(clubId: id(s)),
      ),
      page(
        '/clubs/:id/announcements/new',
        (s) => NewAnnouncementScreen(clubId: id(s)),
      ),
      page('/clubs/:id/reward', (s) => ClubRewardScreen(id: id(s))),
      page('/clubs/:id/moderation', (s) => ChatModerationScreen(clubId: id(s))),
      page('/clubs/:id/report', (s) => ReportContentScreen.club(clubId: id(s))),
      page(
        '/activities/:id/report',
        (s) => ReportContentScreen.activity(activityId: id(s)),
      ),
      page(
        '/shop/videos/:id/report',
        (s) => ReportContentScreen.video(videoId: id(s)),
      ),
      page(
        '/shop/live/:id/report',
        (s) => ReportContentScreen.video(videoId: id(s), live: true),
      ),
      page('/clubs/:id/members', (s) => ClubMembersScreen(id: id(s))),
      page(
        '/clubs/:id/members/:user',
        (s) => ClubMemberScreen(id: id(s), userId: s.pathParameters['user']!),
      ),
      page('/clubs/:id/requests', (s) => JoinRequestsScreen(id: id(s))),
      page('/clubs/:id/roles', (s) => ManageRolesScreen(id: id(s))),
      page('/clubs/:id/roles/new', (s) => CreateRoleScreen(id: id(s))),
      page(
        '/clubs/:id/roles/:role',
        (s) => RoleEditScreen(id: id(s), roleId: s.pathParameters['role']!),
      ),
      page(
        '/clubs/:id/roles/:role/permissions',
        (s) =>
            RolePermissionsScreen(id: id(s), roleId: s.pathParameters['role']!),
      ),
      page(
        '/clubs/:id/roles/:role/members',
        (s) => RoleMembersScreen(id: id(s), roleId: s.pathParameters['role']!),
      ),
      page(
        '/clubs/:id/roles/:role/delete',
        (s) => RoleDeleteScreen(id: id(s), roleId: s.pathParameters['role']!),
      ),
      page('/clubs/:id/audit', (s) => AuditLogScreen(id: id(s))),
      page('/clubs/:id/settings', (s) => ClubSettingsScreen(id: id(s))),
      page(
        '/clubs/:id/overview',
        (s) => ClubOverviewScreen(
          id: id(s),
          tab: s.uri.queryParameters['tab'] ?? 'about',
        ),
      ),
      page('/clubs/:id/bans', (s) => ClubBansScreen(id: id(s))),
      page('/clubs/:id/transfer', (s) => ClubTransferScreen(id: id(s))),
      page('/clubs/:id/leave', (s) => ClubLeaveScreen(id: id(s))),
      page('/clubs/:id/delete', (s) => ClubDeleteScreen(id: id(s))),
      page('/clubs/:id/invite', (s) => ClubInviteScreen(id: id(s))),
      // Teams.
      page(Routes.newTeam, (_) => const NewTeamScreen()),
      page(Routes.newTeamSport, (_) => const NewTeamSportScreen()),
      page(Routes.newTeamMembers, (_) => const NewTeamMembersScreen()),
      page(
        '/teams/:id/chat',
        (s) => GroupChatScreen(scope: ChatScope.team(id(s))),
      ),
      page(
        '/teams/:id/chat/:message/report',
        (s) => ReportContentScreen.message(
          scope: ChatScope.team(id(s)),
          messageId: s.pathParameters['message']!,
        ),
      ),
      page('/teams/:id', (s) => TeamPageScreen(id: id(s))),
      page(
        '/teams/:id/roster',
        (s) => TeamRosterScreen(
          id: id(s),
          tab: s.uri.queryParameters['tab'] ?? 'lineup',
        ),
      ),
      page('/teams/:id/new-fixture', (s) => NewFixtureScreen(teamId: id(s))),
      page(
        '/teams/:id/fixtures/:fixture',
        (s) => TeamFixtureScreen(
          teamId: id(s),
          fixtureId: s.pathParameters['fixture']!,
        ),
      ),
      page(
        '/teams/:id/fixtures/:fixture/lineup',
        (s) => EditLineupScreen(
          teamId: id(s),
          fixtureId: s.pathParameters['fixture']!,
        ),
      ),
      page('/teams/:id/settings', (s) => TeamSettingsScreen(id: id(s))),
      page('/teams/:id/overview', (s) => TeamOverviewScreen(id: id(s))),
      page('/teams/:id/add', (s) => TeamAddPlayersScreen(id: id(s))),
      page('/teams/:id/leave', (s) => TeamLeaveScreen(id: id(s))),
      page('/teams/:id/delete', (s) => TeamDeleteScreen(id: id(s))),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            observers: [Crumbs.tabs[0]],
            routes: [
              GoRoute(
                path: Routes.home,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: HomeScreen()),
                routes: [
                  GoRoute(
                    path: 'play',
                    pageBuilder: (_, s) => cupertinoPage(
                      s,
                      PlayScreen(
                        initialKind: ActivityKind.values
                            .where((k) => k.id == s.uri.queryParameters['kind'])
                            .firstOrNull,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [Crumbs.tabs[1]],
            routes: [
              GoRoute(
                path: Routes.discover,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: DiscoverScreen()),
                routes: [
                  // Search keeps the tab bar, as in the design.
                  GoRoute(
                    path: 'search',
                    pageBuilder: (_, s) =>
                        cupertinoPage(s, const SearchScreen()),
                    routes: [
                      GoRoute(
                        path: 'results',
                        pageBuilder: (_, s) => cupertinoPage(
                          s,
                          SearchResultsScreen(
                            query: s.uri.queryParameters['q'] ?? '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [Crumbs.tabs[2]],
            routes: [
              GoRoute(
                path: Routes.scan,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: ScanScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [Crumbs.tabs[3]],
            routes: [
              GoRoute(
                path: Routes.inbox,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: InboxScreen()),
                routes: [
                  GoRoute(
                    path: ':conversation',
                    parentNavigatorKey: rootKey,
                    pageBuilder: (_, s) => cupertinoPage(
                      s,
                      ChatScreen(
                        conversationId: s.pathParameters['conversation']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [Crumbs.tabs[4]],
            routes: [
              GoRoute(
                path: Routes.profile,
                pageBuilder: (_, _) =>
                    const NoTransitionPage(child: ProfileScreen()),
                routes: [
                  GoRoute(
                    path: 'schedule',
                    pageBuilder: (_, s) => cupertinoPage(
                      s,
                      ScheduleScreen(
                        hosting: s.uri.queryParameters['tab'] == 'hosting',
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'saved',
                    pageBuilder: (_, s) =>
                        cupertinoPage(s, const SavedScreen()),
                  ),
                  GoRoute(
                    path: 'passport',
                    parentNavigatorKey: rootKey,
                    pageBuilder: (_, s) =>
                        cupertinoPage(s, const PassportScreen()),
                  ),
                  GoRoute(
                    path: 'share',
                    parentNavigatorKey: rootKey,
                    pageBuilder: (_, s) =>
                        cupertinoPage(s, const ShareProfileScreen()),
                  ),
                  GoRoute(
                    path: 'connections',
                    parentNavigatorKey: rootKey,
                    pageBuilder: (_, s) => cupertinoPage(
                      s,
                      ConnectionsScreen(
                        followers: s.uri.queryParameters['tab'] == 'followers',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
