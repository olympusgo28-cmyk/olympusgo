import 'package:freezed_annotation/freezed_annotation.dart';

part 'guardian_models.freezed.dart';

/// What the signed-in player may do. The app reads this to decide what to
/// show. The database enforces the same answers separately, so a screen
/// getting this wrong cannot open anything up.
@freezed
abstract class Restrictions with _$Restrictions {
  const factory Restrictions({
    @Default('adult') String audience,
    @Default(false) bool restricted,
    @Default(false) bool suspended,
    @Default(false) bool pendingParent,
    @Default(true) bool canScan,
    @Default(true) bool canChat,
    @Default(true) bool canDiscover,
    @Default(true) bool canShop,
    @Default(true) bool canHost,
  }) = _Restrictions;

  factory Restrictions.fromRow(Map<String, dynamic> r) => Restrictions(
    audience: r['audience'] as String,
    restricted: r['restricted'] as bool,
    suspended: r['suspended'] as bool? ?? false,
    pendingParent: r['pending_parent'] as bool,
    canScan: r['can_scan'] as bool,
    canChat: r['can_chat'] as bool,
    canDiscover: r['can_discover'] as bool,
    canShop: r['can_shop'] as bool,
    canHost: r['can_host'] as bool,
  );

  const Restrictions._();

  bool get isUnder13 => audience == 'child';
  bool get isMinor => audience != 'adult';
}

/// A code the child shows a parent.
@freezed
abstract class ParentCode with _$ParentCode {
  const factory ParentCode({
    required String code,
    required DateTime expiresAt,
  }) = _ParentCode;
}

enum LinkStatus { pending, approved }

/// One side of a parent link: a child for a parent, a parent for a child.
@freezed
abstract class GuardianLink with _$GuardianLink {
  const factory GuardianLink({
    required String linkId,
    required String name,
    required LinkStatus status,
    String? childId,
    String? avatarUrl,
  }) = _GuardianLink;

  factory GuardianLink.fromRow(Map<String, dynamic> r) => GuardianLink(
    linkId: r['link_id'] as String,
    name: r['name'] as String,
    status: LinkStatus.values.byName(r['status'] as String),
    childId: r['child_id'] as String?,
    avatarUrl: r['avatar_url'] as String?,
  );
}

/// The result of a parent typing a code: who the link is for.
@freezed
abstract class PendingLink with _$PendingLink {
  const factory PendingLink({
    required String linkId,
    required String childName,
  }) = _PendingLink;
}

/// Something a child posted, for their parent to review.
@freezed
abstract class ChildPost with _$ChildPost {
  const factory ChildPost({
    required String kind,
    required String id,
    required String body,
    required DateTime createdAt,
  }) = _ChildPost;

  factory ChildPost.fromRow(Map<String, dynamic> r) => ChildPost(
    kind: r['kind'] as String,
    id: r['id'] as String,
    body: r['body'] as String? ?? '',
    createdAt: DateTime.parse(r['created_at'] as String),
  );

  const ChildPost._();

  String get kindLabel => switch (kind) {
    'chat' => 'Group chat',
    'club_review' => 'Club review',
    _ => 'Product review',
  };
}

/// A group a child asked to join, waiting for their parent.
@freezed
abstract class GroupRequest with _$GroupRequest {
  const factory GroupRequest({
    required String clubId,
    required String name,
    @Default('') String area,
    @Default('club') String kind,
  }) = _GroupRequest;

  factory GroupRequest.fromRow(Map<String, dynamic> r) => GroupRequest(
    clubId: r['club_id'] as String,
    name: r['name'] as String,
    area: r['area'] as String? ?? '',
    kind: r['kind'] as String? ?? 'club',
  );
}
