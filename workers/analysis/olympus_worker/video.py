"""Reads a clip. Nothing here is written anywhere but the job's temp folder."""
import time

import cv2

from .metrics import ClipProblem, OutOfTime, Track, follow, report
from .vendor.good_badminton.court import CourtMapper, resolve_court_corners

# A hair under 0.1, so a 10 fps clip doesn't skip frames on rounding.
SAMPLE_GAP = 0.099
FRAME_MAX_WIDTH = 1280
FRAME_QUALITY = 70
# Checked every so often, so a withdrawal stops the work.
CHECK_EVERY_SAMPLES = 50


def _open(path):
    capture = cv2.VideoCapture(str(path))
    if not capture.isOpened():
        raise ClipProblem("bad_video")
    fps = capture.get(cv2.CAP_PROP_FPS)
    frames = capture.get(cv2.CAP_PROP_FRAME_COUNT)
    if fps <= 0 or frames <= 0:
        capture.release()
        raise ClipProblem("bad_video")
    return capture, fps, frames


def corners_ok(corners):
    """Clockwise on screen from far left, with the far end above the near end.
    Crossed or swapped corners would measure the wrong side without a word."""
    pairs = list(zip(corners, corners[1:] + corners[:1]))
    turns = [
        (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0])
        for (a, b), c in zip(pairs, corners[2:] + corners[:2])
    ]
    far = corners[0][1] + corners[1][1]
    near = corners[2][1] + corners[3][1]
    return all(t > 0 for t in turns) and far < near


def find_court(path, max_seconds):
    """The clip's length, a court frame as JPEG bytes, and the corners found."""
    capture, fps, frames = _open(path)
    try:
        seconds = frames / fps
        if seconds < 1:
            raise ClipProblem("bad_video")
        if seconds > max_seconds:
            raise ClipProblem("too_long")
        capture.set(cv2.CAP_PROP_POS_FRAMES, min(frames - 1, fps))
        ok, image = capture.read()
        if not ok:
            # The frame count in a file can be more than it really holds.
            capture.set(cv2.CAP_PROP_POS_FRAMES, 0)
            ok, image = capture.read()
        if not ok:
            raise ClipProblem("bad_video")
    finally:
        capture.release()

    height, width = image.shape[:2]
    corners, _, _ = resolve_court_corners(image)
    normal = None
    if corners:
        normal = [[round(x / width, 4), round(y / height, 4)] for x, y in corners]
        if not all(0 <= v <= 1 for point in normal for v in point) or not corners_ok(normal):
            normal = None

    if width > FRAME_MAX_WIDTH:
        image = cv2.resize(image, (FRAME_MAX_WIDTH, int(height * FRAME_MAX_WIDTH / width)))
    ok, jpeg = cv2.imencode(".jpg", image, [cv2.IMWRITE_JPEG_QUALITY, FRAME_QUALITY])
    if not ok:
        raise ClipProblem("bad_video")
    return seconds, jpeg.tobytes(), normal


def analyse(path, corners, side, pose, should_continue, deadline):
    """Measures the chosen side. Returns None if told to stop."""
    if not corners_ok(corners):
        raise ClipProblem("no_court")
    capture, _, _ = _open(path)
    try:
        mapper = None
        track = Track()
        next_sample = 0.0
        # By the clip's own clock, because a phone's frame rate isn't steady.
        while capture.grab():
            at = capture.get(cv2.CAP_PROP_POS_MSEC) / 1000
            if at < next_sample:
                continue
            next_sample = at + SAMPLE_GAP
            ok, image = capture.retrieve()
            if not ok:
                continue
            if mapper is None:
                # From the frame, which is already turned the right way up.
                height, width = image.shape[:2]
                mapper = CourtMapper([(x * width, y * height) for x, y in corners])
            feet = [tuple(float(v) for v in mapper.image_to_court(tuple(p))) for p in pose.feet(image)]
            follow(track, at, feet, side)
            if time.monotonic() > deadline:
                raise OutOfTime()
            if track.samples % CHECK_EVERY_SAMPLES == 0 and not should_continue():
                return None
    finally:
        capture.release()
    return report(track)
