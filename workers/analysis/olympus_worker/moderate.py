"""Samples a post's frames for the feed checks. The checks themselves run in the
feed-worker function, so this holds no provider key. Frames stay in memory and
the video in the job's temp folder. Logs carry job ids and error names only."""
import logging
import os
import tempfile
import time

import cv2

from .metrics import ClipProblem, OutOfTime
from .run import SEND_MARGIN_SECONDS, settle
from .video import _open

log = logging.getLogger("olympus_worker")
IDLE_SECONDS = 2
FRAME_MAX_WIDTH = 640
FRAME_QUALITY = 70


def _jpeg(image):
    height, width = image.shape[:2]
    if width > FRAME_MAX_WIDTH:
        image = cv2.resize(image, (FRAME_MAX_WIDTH, round(height * FRAME_MAX_WIDTH / width)))
    ok, encoded = cv2.imencode(".jpg", image, [cv2.IMWRITE_JPEG_QUALITY, FRAME_QUALITY])
    if not ok:
        raise ClipProblem("bad_video")
    return encoded.tobytes()


def sample_frames(path, per_second, max_seconds, deadline):
    """A frame every 1 / per_second seconds, by the video's own clock. Stated
    lengths can lie, so the frames themselves are counted: a video that runs on
    past the limit fails, because the end of it would go unchecked."""
    capture, _, _ = _open(path)
    frames = []
    next_at = 0.0
    gap = 1 / per_second
    try:
        while capture.grab():
            if time.monotonic() > deadline:
                raise OutOfTime()
            at = capture.get(cv2.CAP_PROP_POS_MSEC) / 1000
            if at > max_seconds:
                raise ClipProblem("too_long")
            if at + 1e-3 < next_at:
                continue
            ok, image = capture.retrieve()
            if ok:
                frames.append(_jpeg(image))
                next_at = at + gap
    finally:
        capture.release()
    if not frames:
        raise ClipProblem("bad_video")
    return frames


def run_feed_once(api):
    """Checks one post. False when the queue is empty."""
    job = api.claim()
    if job is None:
        return False
    started = time.monotonic()
    deadline = started + job["timeout_seconds"] - SEND_MARGIN_SECONDS
    spent = lambda: time.monotonic() - started  # noqa: E731
    try:
        with tempfile.TemporaryDirectory(prefix="clip-") as folder:
            path = os.path.join(folder, "clip")
            api.download(job["video_url"], path, deadline)
            frames = sample_frames(path, job["frames_per_second"], job["max_seconds"], deadline)
        settle(api, job, True, spent(), frames)
        log.info("job %s done", job["job_id"])
    except OutOfTime:
        # The sweep times the job out, and it goes round again.
        log.info("job %s out of time", job["job_id"])
    except ClipProblem as problem:
        log.info("job %s failed: %s", job["job_id"], problem.code)
        settle(api, job, False, spent(), code=problem.code)
    except Exception as error:  # A bad job must not stop the worker.
        log.warning("job %s failed: %s", job["job_id"], type(error).__name__)
        settle(api, job, False, spent(), code="internal")
    return True


def run_feed_forever(api):
    while True:
        try:
            if not run_feed_once(api):
                time.sleep(IDLE_SECONDS)
        except Exception as error:  # The API being down isn't a reason to stop.
            log.warning("worker loop: %s", type(error).__name__)
            time.sleep(IDLE_SECONDS)
