// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clubList)
final clubListProvider = ClubListFamily._();

final class ClubListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClubListItem>>,
          List<ClubListItem>,
          FutureOr<List<ClubListItem>>
        >
    with
        $FutureModifier<List<ClubListItem>>,
        $FutureProvider<List<ClubListItem>> {
  ClubListProvider._({
    required ClubListFamily super.from,
    required ClubTab super.argument,
  }) : super(
         retry: null,
         name: r'clubListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubListHash();

  @override
  String toString() {
    return r'clubListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ClubListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClubListItem>> create(Ref ref) {
    final argument = this.argument as ClubTab;
    return clubList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubListHash() => r'dd2a73f8d76777d832b18b38af2627fa145e52eb';

final class ClubListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ClubListItem>>, ClubTab> {
  ClubListFamily._()
    : super(
        retry: null,
        name: r'clubListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClubListProvider call(ClubTab tab) =>
      ClubListProvider._(argument: tab, from: this);

  @override
  String toString() => r'clubListProvider';
}

@ProviderFor(teamList)
final teamListProvider = TeamListFamily._();

final class TeamListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamListItem>>,
          List<TeamListItem>,
          FutureOr<List<TeamListItem>>
        >
    with
        $FutureModifier<List<TeamListItem>>,
        $FutureProvider<List<TeamListItem>> {
  TeamListProvider._({
    required TeamListFamily super.from,
    required ClubTab super.argument,
  }) : super(
         retry: null,
         name: r'teamListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamListHash();

  @override
  String toString() {
    return r'teamListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TeamListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeamListItem>> create(Ref ref) {
    final argument = this.argument as ClubTab;
    return teamList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamListHash() => r'974b3ea80398913b400f8057ab3bef6e1bf47a02';

final class TeamListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TeamListItem>>, ClubTab> {
  TeamListFamily._()
    : super(
        retry: null,
        name: r'teamListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamListProvider call(ClubTab tab) =>
      TeamListProvider._(argument: tab, from: this);

  @override
  String toString() => r'teamListProvider';
}

@ProviderFor(club)
final clubProvider = ClubFamily._();

final class ClubProvider
    extends $FunctionalProvider<AsyncValue<Club>, Club, FutureOr<Club>>
    with $FutureModifier<Club>, $FutureProvider<Club> {
  ClubProvider._({
    required ClubFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clubProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubHash();

  @override
  String toString() {
    return r'clubProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Club> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Club> create(Ref ref) {
    final argument = this.argument as String;
    return club(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubHash() => r'e8bae26f02069d8cfc86c371b98ae34848148c3b';

final class ClubFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Club>, String> {
  ClubFamily._()
    : super(
        retry: null,
        name: r'clubProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClubProvider call(String id) => ClubProvider._(argument: id, from: this);

  @override
  String toString() => r'clubProvider';
}

@ProviderFor(clubIdForCode)
final clubIdForCodeProvider = ClubIdForCodeFamily._();

final class ClubIdForCodeProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  ClubIdForCodeProvider._({
    required ClubIdForCodeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clubIdForCodeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubIdForCodeHash();

  @override
  String toString() {
    return r'clubIdForCodeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return clubIdForCode(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubIdForCodeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubIdForCodeHash() => r'08fbf31092cd316c18a2c251cffea4ed73fe2765';

final class ClubIdForCodeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  ClubIdForCodeFamily._()
    : super(
        retry: null,
        name: r'clubIdForCodeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClubIdForCodeProvider call(String code) =>
      ClubIdForCodeProvider._(argument: code, from: this);

  @override
  String toString() => r'clubIdForCodeProvider';
}

@ProviderFor(clubSessions)
final clubSessionsProvider = ClubSessionsFamily._();

final class ClubSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Activity>>,
          List<Activity>,
          FutureOr<List<Activity>>
        >
    with $FutureModifier<List<Activity>>, $FutureProvider<List<Activity>> {
  ClubSessionsProvider._({
    required ClubSessionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clubSessionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubSessionsHash();

  @override
  String toString() {
    return r'clubSessionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Activity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Activity>> create(Ref ref) {
    final argument = this.argument as String;
    return clubSessions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubSessionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubSessionsHash() => r'49b4acc286aeac3c97d935c57fceee404a2a2119';

final class ClubSessionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Activity>>, String> {
  ClubSessionsFamily._()
    : super(
        retry: null,
        name: r'clubSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClubSessionsProvider call(String clubId) =>
      ClubSessionsProvider._(argument: clubId, from: this);

  @override
  String toString() => r'clubSessionsProvider';
}

@ProviderFor(clubMembers)
final clubMembersProvider = ClubMembersFamily._();

final class ClubMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClubMember>>,
          List<ClubMember>,
          FutureOr<List<ClubMember>>
        >
    with $FutureModifier<List<ClubMember>>, $FutureProvider<List<ClubMember>> {
  ClubMembersProvider._({
    required ClubMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clubMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubMembersHash();

  @override
  String toString() {
    return r'clubMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ClubMember>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClubMember>> create(Ref ref) {
    final argument = this.argument as String;
    return clubMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubMembersHash() => r'd1578c70459dc3accbf9b1ae508d842dc116be29';

final class ClubMembersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ClubMember>>, String> {
  ClubMembersFamily._()
    : super(
        retry: null,
        name: r'clubMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClubMembersProvider call(String clubId) =>
      ClubMembersProvider._(argument: clubId, from: this);

  @override
  String toString() => r'clubMembersProvider';
}

@ProviderFor(clubRoles)
final clubRolesProvider = ClubRolesFamily._();

final class ClubRolesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClubRole>>,
          List<ClubRole>,
          FutureOr<List<ClubRole>>
        >
    with $FutureModifier<List<ClubRole>>, $FutureProvider<List<ClubRole>> {
  ClubRolesProvider._({
    required ClubRolesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clubRolesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubRolesHash();

  @override
  String toString() {
    return r'clubRolesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ClubRole>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClubRole>> create(Ref ref) {
    final argument = this.argument as String;
    return clubRoles(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubRolesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubRolesHash() => r'8dfb2140c6acccd1065c64e9228eb9dd06e408a8';

final class ClubRolesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ClubRole>>, String> {
  ClubRolesFamily._()
    : super(
        retry: null,
        name: r'clubRolesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClubRolesProvider call(String clubId) =>
      ClubRolesProvider._(argument: clubId, from: this);

  @override
  String toString() => r'clubRolesProvider';
}

@ProviderFor(joinRequests)
final joinRequestsProvider = JoinRequestsFamily._();

final class JoinRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<JoinRequest>>,
          List<JoinRequest>,
          FutureOr<List<JoinRequest>>
        >
    with
        $FutureModifier<List<JoinRequest>>,
        $FutureProvider<List<JoinRequest>> {
  JoinRequestsProvider._({
    required JoinRequestsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'joinRequestsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$joinRequestsHash();

  @override
  String toString() {
    return r'joinRequestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<JoinRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<JoinRequest>> create(Ref ref) {
    final argument = this.argument as String;
    return joinRequests(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is JoinRequestsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$joinRequestsHash() => r'a19f3786c4d02fea78edda92379b793caec1712e';

final class JoinRequestsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<JoinRequest>>, String> {
  JoinRequestsFamily._()
    : super(
        retry: null,
        name: r'joinRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  JoinRequestsProvider call(String clubId) =>
      JoinRequestsProvider._(argument: clubId, from: this);

  @override
  String toString() => r'joinRequestsProvider';
}

@ProviderFor(clubBans)
final clubBansProvider = ClubBansFamily._();

final class ClubBansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClubBan>>,
          List<ClubBan>,
          FutureOr<List<ClubBan>>
        >
    with $FutureModifier<List<ClubBan>>, $FutureProvider<List<ClubBan>> {
  ClubBansProvider._({
    required ClubBansFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clubBansProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubBansHash();

  @override
  String toString() {
    return r'clubBansProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ClubBan>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClubBan>> create(Ref ref) {
    final argument = this.argument as String;
    return clubBans(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubBansProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubBansHash() => r'53530cdedb34e2fce8cd03adbbab9f447fd27b1e';

final class ClubBansFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ClubBan>>, String> {
  ClubBansFamily._()
    : super(
        retry: null,
        name: r'clubBansProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClubBansProvider call(String clubId) =>
      ClubBansProvider._(argument: clubId, from: this);

  @override
  String toString() => r'clubBansProvider';
}

@ProviderFor(clubAudit)
final clubAuditProvider = ClubAuditFamily._();

final class ClubAuditProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AuditEntry>>,
          List<AuditEntry>,
          FutureOr<List<AuditEntry>>
        >
    with $FutureModifier<List<AuditEntry>>, $FutureProvider<List<AuditEntry>> {
  ClubAuditProvider._({
    required ClubAuditFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clubAuditProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubAuditHash();

  @override
  String toString() {
    return r'clubAuditProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AuditEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AuditEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return clubAudit(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubAuditProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubAuditHash() => r'b14f62b575e6f3d5dd15d333660639dd7851b590';

final class ClubAuditFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AuditEntry>>, String> {
  ClubAuditFamily._()
    : super(
        retry: null,
        name: r'clubAuditProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClubAuditProvider call(String clubId) =>
      ClubAuditProvider._(argument: clubId, from: this);

  @override
  String toString() => r'clubAuditProvider';
}

@ProviderFor(clubAnnouncements)
final clubAnnouncementsProvider = ClubAnnouncementsFamily._();

final class ClubAnnouncementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Announcement>>,
          List<Announcement>,
          FutureOr<List<Announcement>>
        >
    with
        $FutureModifier<List<Announcement>>,
        $FutureProvider<List<Announcement>> {
  ClubAnnouncementsProvider._({
    required ClubAnnouncementsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clubAnnouncementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubAnnouncementsHash();

  @override
  String toString() {
    return r'clubAnnouncementsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Announcement>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Announcement>> create(Ref ref) {
    final argument = this.argument as String;
    return clubAnnouncements(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubAnnouncementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubAnnouncementsHash() => r'9ab1bff0367251a8739bf5cb377a83c6f1bf13fc';

final class ClubAnnouncementsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Announcement>>, String> {
  ClubAnnouncementsFamily._()
    : super(
        retry: null,
        name: r'clubAnnouncementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClubAnnouncementsProvider call(String clubId) =>
      ClubAnnouncementsProvider._(argument: clubId, from: this);

  @override
  String toString() => r'clubAnnouncementsProvider';
}

@ProviderFor(groupChat)
final groupChatProvider = GroupChatFamily._();

final class GroupChatProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupMessage>>,
          List<GroupMessage>,
          Stream<List<GroupMessage>>
        >
    with
        $FutureModifier<List<GroupMessage>>,
        $StreamProvider<List<GroupMessage>> {
  GroupChatProvider._({
    required GroupChatFamily super.from,
    required ChatScope super.argument,
  }) : super(
         retry: null,
         name: r'groupChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupChatHash();

  @override
  String toString() {
    return r'groupChatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GroupMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GroupMessage>> create(Ref ref) {
    final argument = this.argument as ChatScope;
    return groupChat(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupChatHash() => r'a5eb98b0c7fa747b7fb8122910b9c75c028a5302';

final class GroupChatFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GroupMessage>>, ChatScope> {
  GroupChatFamily._()
    : super(
        retry: null,
        name: r'groupChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GroupChatProvider call(ChatScope scope) =>
      GroupChatProvider._(argument: scope, from: this);

  @override
  String toString() => r'groupChatProvider';
}

@ProviderFor(clubLeaderboard)
final clubLeaderboardProvider = ClubLeaderboardFamily._();

final class ClubLeaderboardProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClubLeaderboard>,
          ClubLeaderboard,
          FutureOr<ClubLeaderboard>
        >
    with $FutureModifier<ClubLeaderboard>, $FutureProvider<ClubLeaderboard> {
  ClubLeaderboardProvider._({
    required ClubLeaderboardFamily super.from,
    required (String, ClubSport) super.argument,
  }) : super(
         retry: null,
         name: r'clubLeaderboardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubLeaderboardHash();

  @override
  String toString() {
    return r'clubLeaderboardProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ClubLeaderboard> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClubLeaderboard> create(Ref ref) {
    final argument = this.argument as (String, ClubSport);
    return clubLeaderboard(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubLeaderboardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubLeaderboardHash() => r'06da3de87288e989ed73e58f0cccb7cd41e8c0a6';

final class ClubLeaderboardFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ClubLeaderboard>,
          (String, ClubSport)
        > {
  ClubLeaderboardFamily._()
    : super(
        retry: null,
        name: r'clubLeaderboardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClubLeaderboardProvider call(String clubId, ClubSport sport) =>
      ClubLeaderboardProvider._(argument: (clubId, sport), from: this);

  @override
  String toString() => r'clubLeaderboardProvider';
}

@ProviderFor(clubReward)
final clubRewardProvider = ClubRewardFamily._();

final class ClubRewardProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClubReward>,
          ClubReward,
          FutureOr<ClubReward>
        >
    with $FutureModifier<ClubReward>, $FutureProvider<ClubReward> {
  ClubRewardProvider._({
    required ClubRewardFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clubRewardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clubRewardHash();

  @override
  String toString() {
    return r'clubRewardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ClubReward> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ClubReward> create(Ref ref) {
    final argument = this.argument as String;
    return clubReward(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClubRewardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clubRewardHash() => r'e38c41d13d71180d8c2c5a7a43e91bb0c07d40ed';

final class ClubRewardFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ClubReward>, String> {
  ClubRewardFamily._()
    : super(
        retry: null,
        name: r'clubRewardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClubRewardProvider call(String clubId) =>
      ClubRewardProvider._(argument: clubId, from: this);

  @override
  String toString() => r'clubRewardProvider';
}

@ProviderFor(inviteCandidates)
final inviteCandidatesProvider = InviteCandidatesProvider._();

final class InviteCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InviteCandidate>>,
          List<InviteCandidate>,
          FutureOr<List<InviteCandidate>>
        >
    with
        $FutureModifier<List<InviteCandidate>>,
        $FutureProvider<List<InviteCandidate>> {
  InviteCandidatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inviteCandidatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inviteCandidatesHash();

  @$internal
  @override
  $FutureProviderElement<List<InviteCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InviteCandidate>> create(Ref ref) {
    return inviteCandidates(ref);
  }
}

String _$inviteCandidatesHash() => r'622ad6f2a0d3f457541a7e64cd41fc0cda5be22b';

@ProviderFor(team)
final teamProvider = TeamFamily._();

final class TeamProvider
    extends $FunctionalProvider<AsyncValue<Team>, Team, FutureOr<Team>>
    with $FutureModifier<Team>, $FutureProvider<Team> {
  TeamProvider._({
    required TeamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamHash();

  @override
  String toString() {
    return r'teamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Team> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Team> create(Ref ref) {
    final argument = this.argument as String;
    return team(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamHash() => r'e2b1bb17f122e2af4e187f4343efa5cdd806ff39';

final class TeamFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Team>, String> {
  TeamFamily._()
    : super(
        retry: null,
        name: r'teamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamProvider call(String id) => TeamProvider._(argument: id, from: this);

  @override
  String toString() => r'teamProvider';
}

@ProviderFor(teamSessions)
final teamSessionsProvider = TeamSessionsFamily._();

final class TeamSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamSession>>,
          List<TeamSession>,
          FutureOr<List<TeamSession>>
        >
    with
        $FutureModifier<List<TeamSession>>,
        $FutureProvider<List<TeamSession>> {
  TeamSessionsProvider._({
    required TeamSessionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamSessionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamSessionsHash();

  @override
  String toString() {
    return r'teamSessionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TeamSession>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeamSession>> create(Ref ref) {
    final argument = this.argument as String;
    return teamSessions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamSessionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamSessionsHash() => r'80a811d25cf12a9b733efa807e2ecdc1388f9382';

final class TeamSessionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TeamSession>>, String> {
  TeamSessionsFamily._()
    : super(
        retry: null,
        name: r'teamSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamSessionsProvider call(String teamId) =>
      TeamSessionsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamSessionsProvider';
}

@ProviderFor(teamResults)
final teamResultsProvider = TeamResultsFamily._();

final class TeamResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamResult>>,
          List<TeamResult>,
          FutureOr<List<TeamResult>>
        >
    with $FutureModifier<List<TeamResult>>, $FutureProvider<List<TeamResult>> {
  TeamResultsProvider._({
    required TeamResultsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamResultsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamResultsHash();

  @override
  String toString() {
    return r'teamResultsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TeamResult>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeamResult>> create(Ref ref) {
    final argument = this.argument as String;
    return teamResults(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamResultsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamResultsHash() => r'0d383669286ca300155d7654578bef4903726a50';

final class TeamResultsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TeamResult>>, String> {
  TeamResultsFamily._()
    : super(
        retry: null,
        name: r'teamResultsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamResultsProvider call(String teamId) =>
      TeamResultsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamResultsProvider';
}

@ProviderFor(teamMembers)
final teamMembersProvider = TeamMembersFamily._();

final class TeamMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TeamMember>>,
          List<TeamMember>,
          FutureOr<List<TeamMember>>
        >
    with $FutureModifier<List<TeamMember>>, $FutureProvider<List<TeamMember>> {
  TeamMembersProvider._({
    required TeamMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamMembersHash();

  @override
  String toString() {
    return r'teamMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TeamMember>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TeamMember>> create(Ref ref) {
    final argument = this.argument as String;
    return teamMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamMembersHash() => r'44c88b841dc1a4c42071d9529f69717a773a3e03';

final class TeamMembersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TeamMember>>, String> {
  TeamMembersFamily._()
    : super(
        retry: null,
        name: r'teamMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamMembersProvider call(String teamId) =>
      TeamMembersProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamMembersProvider';
}

@ProviderFor(nextFixtureId)
final nextFixtureIdProvider = NextFixtureIdFamily._();

final class NextFixtureIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  NextFixtureIdProvider._({
    required NextFixtureIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'nextFixtureIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nextFixtureIdHash();

  @override
  String toString() {
    return r'nextFixtureIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return nextFixtureId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NextFixtureIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nextFixtureIdHash() => r'49577329475eacee49cc0054ef966b2ee2103e50';

final class NextFixtureIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  NextFixtureIdFamily._()
    : super(
        retry: null,
        name: r'nextFixtureIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NextFixtureIdProvider call(String teamId) =>
      NextFixtureIdProvider._(argument: teamId, from: this);

  @override
  String toString() => r'nextFixtureIdProvider';
}

@ProviderFor(fixture)
final fixtureProvider = FixtureFamily._();

final class FixtureProvider
    extends $FunctionalProvider<AsyncValue<Fixture>, Fixture, FutureOr<Fixture>>
    with $FutureModifier<Fixture>, $FutureProvider<Fixture> {
  FixtureProvider._({
    required FixtureFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fixtureProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fixtureHash();

  @override
  String toString() {
    return r'fixtureProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Fixture> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Fixture> create(Ref ref) {
    final argument = this.argument as String;
    return fixture(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FixtureProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fixtureHash() => r'4320e564b0929d7b0453c53c7f50e3444d98aec4';

final class FixtureFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Fixture>, String> {
  FixtureFamily._()
    : super(
        retry: null,
        name: r'fixtureProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FixtureProvider call(String fixtureId) =>
      FixtureProvider._(argument: fixtureId, from: this);

  @override
  String toString() => r'fixtureProvider';
}

@ProviderFor(teamCandidates)
final teamCandidatesProvider = TeamCandidatesFamily._();

final class TeamCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InviteCandidate>>,
          List<InviteCandidate>,
          FutureOr<List<InviteCandidate>>
        >
    with
        $FutureModifier<List<InviteCandidate>>,
        $FutureProvider<List<InviteCandidate>> {
  TeamCandidatesProvider._({
    required TeamCandidatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'teamCandidatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$teamCandidatesHash();

  @override
  String toString() {
    return r'teamCandidatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<InviteCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InviteCandidate>> create(Ref ref) {
    final argument = this.argument as String;
    return teamCandidates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamCandidatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$teamCandidatesHash() => r'92167bdc892ac18f7d1fad2eee054439465fd3d1';

final class TeamCandidatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<InviteCandidate>>, String> {
  TeamCandidatesFamily._()
    : super(
        retry: null,
        name: r'teamCandidatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TeamCandidatesProvider call(String teamId) =>
      TeamCandidatesProvider._(argument: teamId, from: this);

  @override
  String toString() => r'teamCandidatesProvider';
}

/// The create-club answers, kept while moving between the four steps.

@ProviderFor(ClubDraftController)
final clubDraftControllerProvider = ClubDraftControllerProvider._();

/// The create-club answers, kept while moving between the four steps.
final class ClubDraftControllerProvider
    extends $NotifierProvider<ClubDraftController, ClubDraft> {
  /// The create-club answers, kept while moving between the four steps.
  ClubDraftControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clubDraftControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clubDraftControllerHash();

  @$internal
  @override
  ClubDraftController create() => ClubDraftController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClubDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClubDraft>(value),
    );
  }
}

String _$clubDraftControllerHash() =>
    r'4139dd4d1acb0912851837d9165506e9b10661d9';

/// The create-club answers, kept while moving between the four steps.

abstract class _$ClubDraftController extends $Notifier<ClubDraft> {
  ClubDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ClubDraft, ClubDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClubDraft, ClubDraft>,
              ClubDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The create-team answers, kept while moving between the three steps.

@ProviderFor(TeamDraftController)
final teamDraftControllerProvider = TeamDraftControllerProvider._();

/// The create-team answers, kept while moving between the three steps.
final class TeamDraftControllerProvider
    extends $NotifierProvider<TeamDraftController, TeamDraft> {
  /// The create-team answers, kept while moving between the three steps.
  TeamDraftControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamDraftControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamDraftControllerHash();

  @$internal
  @override
  TeamDraftController create() => TeamDraftController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamDraft>(value),
    );
  }
}

String _$teamDraftControllerHash() =>
    r'886728a91c7edb4a0760da37c686ffe4988087e6';

/// The create-team answers, kept while moving between the three steps.

abstract class _$TeamDraftController extends $Notifier<TeamDraft> {
  TeamDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TeamDraft, TeamDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TeamDraft, TeamDraft>,
              TeamDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
