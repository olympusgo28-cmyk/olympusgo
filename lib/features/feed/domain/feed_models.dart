class FeedStatus {
  const FeedStatus({
    required this.open,
    required this.canPost,
    required this.canDiscover,
    required this.maxSeconds,
    required this.maxMb,
  });

  factory FeedStatus.fromRow(Map<String, dynamic> r) => FeedStatus(
    open: r['open'] as bool,
    canPost: r['can_post'] as bool,
    canDiscover: r['can_discover'] as bool,
    maxSeconds: r['max_seconds'] as int,
    maxMb: r['max_mb'] as int,
  );

  final bool open;
  final bool canPost;

  /// Teens follow people. Only adults get Discover, and the server says so.
  final bool canDiscover;
  final int maxSeconds;
  final int maxMb;
}

enum PostStatus { waiting, checking, review, live, rejected, failed, removed }

PostStatus _status(String? s) => switch (s) {
  'waiting' => PostStatus.waiting,
  'checking' => PostStatus.checking,
  'review' => PostStatus.review,
  'live' || null => PostStatus.live,
  'failed' => PostStatus.failed,
  'removed' => PostStatus.removed,
  _ => PostStatus.rejected,
};

enum PostAudience {
  followers('followers', 'Followers'),
  public('public', 'Everyone');

  const PostAudience(this.id, this.label);
  final String id;
  final String label;
}

class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.caption,
    required this.sport,
    required this.seconds,
    required this.hasPoster,
    required this.likes,
    required this.liked,
    required this.mine,
    this.audience = PostAudience.followers,
    this.status = PostStatus.live,
    this.createdAt,
  });

  factory FeedPost.fromRow(Map<String, dynamic> r) => FeedPost(
    id: r['id'] as String,
    authorId: r['author_id'] as String,
    author: r['author'] as String? ?? 'Player',
    caption: r['caption'] as String? ?? '',
    sport: r['sport'] as String,
    seconds: (r['seconds'] as num).toInt(),
    hasPoster: r['poster'] as bool? ?? false,
    likes: (r['likes'] as num).toInt(),
    liked: r['liked'] as bool? ?? false,
    mine: r['mine'] as bool? ?? false,
    audience: r['audience'] == 'public'
        ? PostAudience.public
        : PostAudience.followers,
    status: _status(r['status'] as String?),
    createdAt: r['created_at'] == null
        ? null
        : DateTime.parse(r['created_at'] as String).toLocal(),
  );

  final String id;
  final String authorId;
  final String author;
  final String caption;
  final String sport;
  final int seconds;
  final bool hasPoster;
  final int likes;
  final bool liked;
  final bool mine;
  final PostAudience audience;
  final PostStatus status;
  final DateTime? createdAt;

  /// The answer is coming from the server.
  bool get working => status == PostStatus.checking;

  FeedPost copy({bool? liked, int? likes}) => FeedPost(
    id: id,
    authorId: authorId,
    author: author,
    caption: caption,
    sport: sport,
    seconds: seconds,
    hasPoster: hasPoster,
    likes: likes ?? this.likes,
    liked: liked ?? this.liked,
    mine: mine,
    audience: audience,
    status: status,
    createdAt: createdAt,
  );
}

/// What a post's author is told about where it stands.
(String, String?) postStatusLine(
  PostStatus status, {
  required bool uploading,
}) => switch (status) {
  PostStatus.waiting when uploading => ('Uploading', null),
  PostStatus.waiting => ('Upload didn’t finish', 'Delete it and post again.'),
  PostStatus.checking => ('Checking', 'This usually takes a few minutes.'),
  PostStatus.review => (
    'Waiting for review',
    'A person checks your first posts. It shows once they’ve said yes.',
  ),
  PostStatus.live => ('Live', null),
  PostStatus.rejected => (
    'Not posted',
    'This video didn’t pass our checks, so nobody can see it.',
  ),
  PostStatus.failed => (
    'We couldn’t check this',
    'Try again. It stays private until it passes.',
  ),
  PostStatus.removed => (
    'Taken down',
    'People reported this video, and we’re looking at it.',
  ),
};
