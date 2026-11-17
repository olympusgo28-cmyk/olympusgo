import 'dart:typed_data';
import 'dart:ui' show Offset;

/// The wording a parent agrees to. Must match `video.consent_version`.
const clipConsentVersion = 'v1';

/// Where the corners start when nothing was found: a court seen from behind
/// one baseline. Far left, far right, near right, near left.
const defaultCorners = [
  Offset(0.3, 0.25),
  Offset(0.7, 0.25),
  Offset(0.95, 0.85),
  Offset(0.05, 0.85),
];

/// Clockwise on screen from far left, with the far end above the near end. The
/// worker checks the same, because crossed corners would measure the wrong side.
bool cornersOk(List<Offset> c) {
  for (var i = 0; i < 4; i++) {
    final a = c[i], b = c[(i + 1) % 4], d = c[(i + 2) % 4];
    final turn = (b.dx - a.dx) * (d.dy - b.dy) - (b.dy - a.dy) * (d.dx - b.dx);
    if (turn <= 0) return false;
  }
  return c[0].dy + c[1].dy < c[2].dy + c[3].dy;
}

class AnalysisStatus {
  const AnalysisStatus({
    required this.open,
    required this.childrenOpen,
    required this.maxSeconds,
    required this.maxMb,
  });

  factory AnalysisStatus.fromRow(Map<String, dynamic> r) => AnalysisStatus(
    open: r['open'] as bool,
    childrenOpen: r['children_open'] as bool,
    maxSeconds: r['max_seconds'] as int,
    maxMb: r['max_mb'] as int,
  );

  final bool open;
  final bool childrenOpen;
  final int maxSeconds;
  final int maxMb;
}

enum ClipStatus {
  waiting,
  uploaded,
  courtReady,
  queued,
  done,
  failed,
  withdrawn,
}

ClipStatus _status(String s) => switch (s) {
  'waiting' => ClipStatus.waiting,
  'uploaded' => ClipStatus.uploaded,
  'court_ready' => ClipStatus.courtReady,
  'queued' => ClipStatus.queued,
  'done' => ClipStatus.done,
  'withdrawn' => ClipStatus.withdrawn,
  _ => ClipStatus.failed,
};

class ClipReport {
  const ClipReport({
    required this.distanceM,
    required this.avgSpeedMs,
    required this.topSpeedMs,
    required this.movingSeconds,
    required this.heatmap,
  });

  factory ClipReport.fromRow(Map<String, dynamic> r) => ClipReport(
    distanceM: (r['distance_m'] as num).toDouble(),
    avgSpeedMs: (r['avg_speed_ms'] as num).toDouble(),
    topSpeedMs: (r['top_speed_ms'] as num).toDouble(),
    movingSeconds: (r['moving_seconds'] as num).toDouble(),
    heatmap: [
      for (final row in r['heatmap'] as List)
        [for (final v in row as List) (v as num).toDouble()],
    ],
  );

  final double distanceM;
  final double avgSpeedMs;
  final double topSpeedMs;
  final double movingSeconds;

  /// 13 rows down the court, 6 across: the share of time in each square.
  final List<List<double>> heatmap;
}

class AnalysisClip {
  const AnalysisClip({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.purgeAt,
    this.errorCode,
    this.seconds = 0,
    this.side,
    this.corners,
    this.fileGone = false,
    this.canExtend = false,
    this.forChild = false,
    this.child,
    this.framePath,
    this.report,
    this.addedByMe = true,
  });

  factory AnalysisClip.fromRow(Map<String, dynamic> r) {
    final corners = r['corners'] as List?;
    final report = r['report'] as Map?;
    return AnalysisClip(
      id: r['id'] as String,
      status: _status(r['status'] as String),
      errorCode: r['error_code'] as String?,
      seconds: (r['seconds'] as num?)?.toInt() ?? 0,
      side: r['side'] as String?,
      corners: corners == null
          ? null
          : [
              for (final p in corners)
                Offset(
                  ((p as List)[0] as num).toDouble(),
                  (p[1] as num).toDouble(),
                ),
            ],
      createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
      purgeAt: DateTime.parse(r['purge_at'] as String).toLocal(),
      fileGone: r['file_gone'] as bool? ?? false,
      canExtend: r['can_extend'] as bool? ?? false,
      forChild: r['for_child'] as bool? ?? false,
      child: r['child'] as String?,
      framePath: r['frame'] as String?,
      addedByMe: r['added_by_me'] as bool? ?? true,
      report: report == null
          ? null
          : ClipReport.fromRow(report.cast<String, dynamic>()),
    );
  }

  final String id;
  final ClipStatus status;
  final String? errorCode;
  final int seconds;
  final String? side;
  final List<Offset>? corners;
  final DateTime createdAt;
  final DateTime purgeAt;
  final bool fileGone;
  final bool canExtend;
  final bool forChild;
  final String? child;
  final String? framePath;
  final ClipReport? report;

  /// A second linked parent can read a clip, but not mark its court.
  final bool addedByMe;

  /// The answer is coming, from the server or the parent who added the clip.
  bool get working =>
      status == ClipStatus.uploaded ||
      status == ClipStatus.queued ||
      (!addedByMe &&
          (status == ClipStatus.waiting || status == ClipStatus.courtReady));

  AnalysisClip copy({
    ClipStatus? status,
    String? side,
    List<Offset>? corners,
    bool? fileGone,
    bool? canExtend,
    DateTime? purgeAt,
    String? framePath,
    ClipReport? report,
  }) => AnalysisClip(
    id: id,
    status: status ?? this.status,
    createdAt: createdAt,
    purgeAt: purgeAt ?? this.purgeAt,
    errorCode: errorCode,
    seconds: seconds,
    side: side ?? this.side,
    corners: corners ?? this.corners,
    fileGone: fileGone ?? this.fileGone,
    canExtend: canExtend ?? this.canExtend,
    forChild: forChild,
    child: child,
    framePath: framePath ?? this.framePath,
    report: report ?? this.report,
    addedByMe: addedByMe,
  );
}

/// The court still used for marking the corners.
class ClipFrame {
  const ClipFrame({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// A file the player chose, on the phone.
class PickedClip {
  const PickedClip({
    required this.path,
    required this.ext,
    required this.bytes,
  });

  final String path;
  final String ext;
  final int bytes;
}

/// What to tell the player when a clip failed.
(String, String) clipFailure(String? code) => switch (code) {
  'doubles' => (
    'Singles only for now',
    'We saw more than two players. Add a clip of a singles game.',
  ),
  'too_long' => (
    'This clip is too long',
    'Trim it to under the limit and add it again.',
  ),
  'no_court' => (
    'We couldn’t find the court',
    'Film from behind a baseline with all four corners in the frame.',
  ),
  'no_player' => (
    'We couldn’t follow the player',
    'Keep the phone still, with the player in the frame for the whole game.',
  ),
  'bad_video' => (
    'We couldn’t read this clip',
    'Add it again as an MP4 or MOV file.',
  ),
  'not_allowed' => (
    'This clip can’t be analysed',
    'It wasn’t analysed, so there’s no report.',
  ),
  _ => (
    'Something went wrong on our side',
    'Add the clip again, or try later.',
  ),
};
