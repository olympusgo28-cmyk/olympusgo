import '../../features/play/domain/activity.dart';
import '../../features/play/domain/hub.dart';

/// Route paths. One per artboard in the OlympusGO Screens canvas.
abstract final class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const signUp = '/signup';
  static const signUpCode = '/signup/code';
  static const logIn = '/login';
  static const logInPhone = '/login/phone';
  static const logInUsername = '/login/username';
  static const logInCode = '/login/code';
  static const recovery = '/recovery';
  static const recoverySent = '/recovery/sent';

  static const name = '/onboarding/name';
  static const birthday = '/onboarding/birthday';
  static const parent = '/onboarding/parent';
  static const sports = '/onboarding/sports';
  static const skills = '/onboarding/skills';
  static String skill(String sportId) => '/onboarding/skills/$sportId';
  static const username = '/onboarding/username';
  static const mobile = '/onboarding/mobile';
  static const mobileVerify = '/onboarding/mobile/verify';
  static const ready = '/ready';

  static const home = '/home';
  static const discover = '/discover';
  static const scan = '/scan';
  static const inbox = '/inbox';
  static const profile = '/profile';

  // Account set-up right after onboarding.
  static const setupAccount = '/setup/account';
  static const setupPersonal = '/setup/personal';

  // Settings.
  static const settings = '/settings';
  static const accountCentre = '/settings/account';
  static const personalInfo = '/settings/personal';
  static const accountHub = '/settings/account-centre';
  static const profileSports = '/settings/sports';
  static const language = '/settings/language';
  static const deleteAccount = '/settings/delete';
  static const verifyPhoneChange = '/settings/personal/verify';
  static const notifications = '/settings/notifications';
  static const privacy = '/settings/privacy';
  static const blocked = '/settings/blocked';
  static const help = '/settings/help';
  static const communityRules = '/settings/help/rules';
  static const country = '/settings/country';
  static const identityCheck = '/settings/identity';

  // Open to everyone, signed in or not.
  static const legal = '/legal';
  static const refundRules = '/legal/refunds';
  static const under18 = '/legal/under-18';
  static const legalNotice = '/legal/notice';
  static const openPrefixes = [legal];
  static const myReports = '/settings/reports';
  static String reportStatus(String id) => '/settings/reports/$id';
  static String removalNotice(String id) => '/notices/$id';
  static const logOut = '/settings/logout';

  // Profile and social.
  static const passport = '/profile/passport';
  static String passportHistory(String sport) =>
      '/profile/passport/history/$sport';
  static const shareProfile = '/profile/share';
  static const saved = '/profile/saved';
  static String connections({bool followers = false}) =>
      '/profile/connections?tab=${followers ? 'followers' : 'following'}';
  static String player(String id) => '/players/$id';
  static String reportPlayer(String id) => '/players/$id/report';
  static String messagePlayer(String id) => '/players/$id/message';
  static String chat(String conversationId) => '/inbox/$conversationId';
  static const search = '/discover/search';
  static String searchResults(String q) =>
      '/discover/search/results?q=${Uri.encodeQueryComponent(q)}';
  static String scannedPlayer(String username) => '/scan/player/$username';

  // Play.
  static const editCategories = '/home/categories';
  static const play = '/home/play';
  static String playKind(ActivityKind kind) => '$play?kind=${kind.id}';
  static const playAddSport = '/play/sports';
  static String playAddSportFor(HubTab tab) => '$playAddSport?tab=${tab.name}';
  static String activity(String id) => '/activities/$id';
  static String guest(String id) => '/activities/$id/guest';
  static String waitlist(String id) => '/activities/$id/waitlist';
  static String meetPlayers(String id) => '/activities/$id/players';
  static String reportActivity(String id) => '/activities/$id/report';
  static String reportVideo(String id, {bool live = false}) =>
      live ? '/shop/live/$id/report' : '/shop/videos/$id/report';
  static String meetWalkIn(String id) => '/activities/$id/walk-in';
  static String meetAttendance(String id) => '/activities/$id/attendance';
  static String meetRecap(String id) => '/activities/$id/recap';
  static String meetCancel(String id) => '/activities/$id/cancel';
  static String scoreEntry(String id) => '/activities/$id/score';
  static String score(String id) => '/scores/$id';
  static String tournamentRegister(String id) => '/tournaments/$id/register';
  static String tournamentWithdraw(String id) => '/tournaments/$id/withdraw';
  static String tournamentResults(String id) => '/tournaments/$id/results';
  static String tournamentManage(String id) => '/tournaments/$id/manage';
  static String tournamentEntries(String id) => '/tournaments/$id/entries';
  static String tournamentCheckIn(String id) => '/tournaments/$id/check-in';
  static String tournamentMessage(String id) => '/tournaments/$id/message';
  static String tournamentCancel(String id) => '/tournaments/$id/cancel';
  static String tournamentRun(String id) => '/tournaments/$id/run';
  static String tournamentScore(String id, String match) =>
      '/tournaments/$id/score/$match';
  static String tournamentTab(String id, String tab) =>
      '/activities/$id?tab=$tab';
  static String eventTicket(String id) => '/events/$id/ticket';
  static String eventRelease(String id) => '/events/$id/release';
  static String eventManage(String id) => '/events/$id/manage';
  static String eventCancel(String id) => '/events/$id/cancel';
  static String eventScan(String id, {String? code}) => code == null
      ? '/events/$id/scan'
      : '/events/$id/scan?code=${Uri.encodeQueryComponent(code)}';
  static const myTickets = '/scan/tickets';
  static const checkTickets = '/scan/doors';
  static String schedule({bool hosting = false}) =>
      '/profile/schedule${hosting ? '?tab=hosting' : ''}';
  static String checkIn(String id) => '/scan/meet/$id';

  // Create.
  static const newMeetSport = '/create/meet/sport';
  static const newMeetBasics = '/create/meet/details';
  static const newEventSports = '/create/event/sports';
  static const newEventDetails = '/create/event/details';
  static const newTournSport = '/create/tournament/sport';
  static const newTournDetails = '/create/tournament/details';
  static String createDate(String field) => '/create/date/$field';
  static String createTime(String field) => '/create/time/$field';
  static const createVenue = '/create/venue';

  // Clubs.
  static const clubs = '/clubs';
  static String clubsTab({bool teams = false}) =>
      teams ? '/clubs?kind=teams' : clubs;
  static const createGroup = '/clubs/start';
  static const newClub = '/clubs/start/club';
  static const newClubSports = '/clubs/start/club/sports';
  static const newClubLevels = '/clubs/start/club/levels';
  static const newClubInvite = '/clubs/start/club/invite';
  static const newClubVenue = '/clubs/start/club/venue';
  static String club(String id) => '/clubs/$id';
  static String joinClub(String code) => '/join/$code';
  static String clubAbout(String id) => '/clubs/$id/about';
  static String clubLeaderboard(String id) => '/clubs/$id/leaderboard';
  static String clubChat(String id) => '/clubs/$id/chat';
  static String clubAnnouncements(String id) => '/clubs/$id/announcements';
  static String clubAnnounce(String id) => '/clubs/$id/announcements/new';
  static String clubMembers(String id) => '/clubs/$id/members';
  static String clubMember(String id, String userId) =>
      '/clubs/$id/members/$userId';
  static String clubRequests(String id) => '/clubs/$id/requests';
  static String clubRoles(String id) => '/clubs/$id/roles';
  static String clubRoleNew(String id) => '/clubs/$id/roles/new';
  static String clubRole(String id, String roleId) =>
      '/clubs/$id/roles/$roleId';
  static String clubRolePermissions(String id, String roleId) =>
      '/clubs/$id/roles/$roleId/permissions';
  static String clubRoleMembers(String id, String roleId) =>
      '/clubs/$id/roles/$roleId/members';
  static String clubRoleDelete(String id, String roleId) =>
      '/clubs/$id/roles/$roleId/delete';
  static String clubAudit(String id) => '/clubs/$id/audit';
  static String clubSettings(String id) => '/clubs/$id/settings';
  static String clubOverview(String id, {String tab = 'about'}) =>
      '/clubs/$id/overview?tab=$tab';
  static String clubReward(String id) => '/clubs/$id/reward';
  static String clubBans(String id) => '/clubs/$id/bans';
  static String clubTransfer(String id) => '/clubs/$id/transfer';
  static String clubLeave(String id) => '/clubs/$id/leave';
  static String clubDelete(String id) => '/clubs/$id/delete';
  static String clubModeration(String id) => '/clubs/$id/moderation';
  static String clubInvite(String id) => '/clubs/$id/invite';
  static String clubReport(String id) => '/clubs/$id/report';
  static String reportClubMessage(String clubId, String messageId) =>
      '/clubs/$clubId/chat/$messageId/report';
  static String reportTeamMessage(String teamId, String messageId) =>
      '/teams/$teamId/chat/$messageId/report';

  // Game.
  static const game = '/game';
  static String campaign(String id) => '/game/$id';
  static String cameraSetup(String id) => '/game/$id/setup';
  static String attempt(String id) => '/game/$id/attempt';
  static String attemptReview(String id) => '/game/$id/review';
  static const leaderboards = '/game/leaderboards';
  static String creator(String id) => '/creators/$id';
  static const creatorEarnings = '/creators/me/earnings';
  static const creatorChallenges = '/creators/me/challenges';
  static const newChallenge = '/creators/me/challenges/new';
  static const gear = '/gear';
  static String gearItem(String id) => '/gear/$id';
  static String gearEdit(String id) => '/gear/$id/edit';

  // Wallet.
  static const wallet = '/wallet';
  static const walletWithdraw = '/wallet/withdraw';
  static const points = '/wallet/points';
  static const receipts = '/wallet/receipts';
  static const earnings = '/wallet/earnings';
  static String earningsDetail(String id) => '/wallet/earnings/$id';
  static const payout = '/wallet/payout';
  static const payoutAccount = '/wallet/payout-account';

  // Shop.
  static const shop = '/shop';
  static String mallPage(String id) => '/shop/malls/$id';
  static String product(String id) => '/shop/products/$id';
  static String shopVideo(String id) => '/shop/videos/$id';
  static String shopLive(String id) => '/shop/live/$id';
  static const cart = '/shop/cart';
  static const checkout = '/shop/checkout';
  static const addresses = '/shop/addresses';
  static const addressNew = '/shop/addresses/new';
  static String orders({String tab = 'all'}) => '/shop/orders?tab=$tab';
  static String order(String id) => '/shop/orders/$id';
  static String orderCancel(String id) => '/shop/orders/$id/cancel';
  static String refund(String id) => '/shop/orders/$id/refund';
  static String orderReview(String id) => '/shop/orders/$id/review';
  static String orderReturn(String id) => '/shop/orders/$id/return';
  static String reportListing(String what) =>
      '/shop/report?what=${Uri.encodeQueryComponent(what)}';
  static String serviceBook(String id) => '/shop/services/$id';
  static const seller = '/shop/seller';
  static const sellerOrders = '/shop/seller/orders';
  static String sellerOrder(String id) => '/shop/seller/orders/$id';
  static const sellerProducts = '/shop/seller/products';
  static String sellerProduct(String id) => '/shop/seller/products/$id';
  static const sellerLive = '/shop/seller/live';
  static const sellerVideo = '/shop/seller/video';

  // Teams.
  static const newTeam = '/teams/start';
  static const newTeamSport = '/teams/start/sport';
  static const newTeamMembers = '/teams/start/members';
  static String team(String id) => '/teams/$id';
  static String teamRoster(String id, {String tab = 'lineup'}) =>
      '/teams/$id/roster?tab=$tab';
  static String teamChat(String id) => '/teams/$id/chat';
  static String teamFixture(String id, String fixtureId) =>
      '/teams/$id/fixtures/$fixtureId';
  static String teamNewFixture(String id) => '/teams/$id/new-fixture';
  static String teamLineup(String id, String fixtureId) =>
      '/teams/$id/fixtures/$fixtureId/lineup';
  static String teamSettings(String id) => '/teams/$id/settings';
  static String teamOverview(String id) => '/teams/$id/overview';
  static String teamAdd(String id) => '/teams/$id/add';
  static String teamLeave(String id) => '/teams/$id/leave';
  static String teamDelete(String id) => '/teams/$id/delete';

  /// A screen that is designed but not built yet (later phases).
  // Academies.
  static const academies = '/academies';
  static const newAcademy = '/academies/start';
  static const newAcademyLevels = '/academies/start/levels';
  static const newAcademyPolicies = '/academies/start/policies';
  static const newAcademyVerify = '/academies/start/verify';
  static const newAcademyCoaches = '/academies/start/coaches';
  static String academy(String id) => '/academies/$id';
  static String academyEnrol(String id) => '/academies/$id/enrol';
  static String academyTrial(String id) => '/academies/$id/trial';
  static String academyToday(String id) => '/academies/$id/today';
  static String academyClasses(String id) => '/academies/$id/classes';
  static String academyRequests(String id) => '/academies/$id/requests';
  static String classSession(String id, String classId) =>
      '/academies/$id/classes/$classId/session';
  static String classRoster(String id, String classId) =>
      '/academies/$id/classes/$classId/students';
  static String academySettings(String id) => '/academies/$id/settings';
  static String academyMessages(String id) => '/academies/$id/messages';
  static String academyClose(String id) => '/academies/$id/close';
  static String academyCoaches(String id) => '/academies/$id/coaches';
  static String classNew(String id) => '/academies/$id/classes/new';
  static String classEdit(String id, String classId) =>
      '/academies/$id/classes/$classId/edit';
  static String changeClass(String id, String classId) =>
      '/academies/$id/classes/$classId/change';
  static String inviteStudents(String id) => '/academies/$id/invite';
  static String curriculum(String id) => '/academies/$id/curriculum';
  static String lessonPlan(String id, int level, int week) =>
      '/academies/$id/curriculum/$level/$week';
  static const coachPay = '/academies/coach-pay';
  static String parentNote(String studentId) => '/students/$studentId/note';
  static String studentAttendance(String id) => '/students/$id/attendance';
  static String filmingConsent(String id) => '/students/$id/consent';
  static String studentHome(String id) => '/students/$id';
  static String studentClass(String id) => '/students/$id/class';
  static String studentFees(String id) => '/students/$id/fees';
  static String studentMakeup(String id) => '/students/$id/makeup';
  static String studentProgress(String id) => '/students/$id/progress';

  // Venues.
  static const venues = '/venues';
  static String venue(String id) => '/venues/$id';
  static String bookCourt(String id) => '/venues/$id/book';
  static String courtBooking(String id) => '/court-bookings/$id';
  static String cancelCourtBooking(String id) => '/court-bookings/$id/cancel';

  static const publicPrefixes = [welcome, signUp, logIn, recovery];
}
