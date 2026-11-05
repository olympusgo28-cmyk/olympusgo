import io
import logging
import time

import cv2
import numpy as np
import pytest

from olympus_worker.api import FeedApi
from olympus_worker.metrics import ClipProblem, OutOfTime
from olympus_worker.moderate import run_feed_once, sample_frames


def write_clip(path, seconds=5, fps=10, width=1280):
    writer = cv2.VideoWriter(str(path), cv2.VideoWriter_fourcc(*"mp4v"), fps, (width, 720))
    assert writer.isOpened()
    for i in range(int(seconds * fps)):
        writer.write(np.full((720, width, 3), i % 255, dtype=np.uint8))
    writer.release()


class FakeApi:
    def __init__(self, clip, max_seconds=60, timeout=300):
        self.job = {
            "job_id": "job-1",
            "token": "secret-token",
            "timeout_seconds": timeout,
            "video_url": "http://signed/url",
            "frames_per_second": 1,
            "max_seconds": max_seconds,
        }
        self.clip = clip
        self.finished = []

    def claim(self):
        job, self.job = self.job, None
        return job

    def download(self, url, path, deadline):
        with open(self.clip, "rb") as source, open(path, "wb") as out:
            out.write(source.read())

    def finish(self, job, ok, seconds, result=None, code=None, frame=None):
        self.finished.append({"ok": ok, "frames": result, "code": code})


def later():
    return time.monotonic() + 60


def test_one_frame_a_second(tmp_path):
    clip = tmp_path / "a.mp4"
    write_clip(clip, seconds=5)
    frames = sample_frames(clip, 1, 60, later())
    assert 5 <= len(frames) <= 6
    assert all(f[:3] == b"\xff\xd8\xff" for f in frames)


def test_more_frames_a_second(tmp_path):
    clip = tmp_path / "a.mp4"
    write_clip(clip, seconds=2)
    assert len(sample_frames(clip, 2, 60, later())) in (4, 5)


def test_frames_are_small(tmp_path):
    clip = tmp_path / "a.mp4"
    write_clip(clip, seconds=1, width=1920)
    image = cv2.imdecode(np.frombuffer(sample_frames(clip, 1, 60, later())[0], np.uint8), cv2.IMREAD_COLOR)
    assert image.shape[1] == 640


def test_a_video_past_the_limit_fails_rather_than_going_part_checked(tmp_path):
    clip = tmp_path / "a.mp4"
    write_clip(clip, seconds=8)
    with pytest.raises(ClipProblem) as problem:
        sample_frames(clip, 1, 5, later())
    assert problem.value.code == "too_long"


def test_a_file_that_isnt_a_video(tmp_path):
    clip = tmp_path / "a.mp4"
    clip.write_bytes(b"not a video")
    with pytest.raises(ClipProblem):
        sample_frames(clip, 1, 60, later())


class _Capture:
    """Stands in for OpenCV, for files a test can't easily make."""

    def __init__(self, frames, msec=None, retrieve_ok=True, stamps=None):
        self.frames = frames
        self.msec = msec
        self.stamps = stamps
        self.retrieve_ok = retrieve_ok
        self.at = 0

    def grab(self):
        self.at += 1
        return self.at <= self.frames

    def get(self, _):
        if self.stamps is not None:
            return self.stamps[self.at - 1]
        return 0 if self.msec == 0 else (self.at - 1) * 100

    def retrieve(self):
        return self.retrieve_ok, np.zeros((10, 10, 3), dtype=np.uint8)

    def release(self):
        pass


def test_stopping_short_of_the_stated_end_fails(monkeypatch):
    capture = _Capture(frames=50)
    monkeypatch.setattr("olympus_worker.moderate._open", lambda _: (capture, 10, 100))
    with pytest.raises(ClipProblem) as problem:
        sample_frames("x", 1, 60, later())
    assert problem.value.code == "bad_video"


def test_a_little_short_of_the_stated_end_passes(monkeypatch):
    capture = _Capture(frames=95)
    monkeypatch.setattr("olympus_worker.moderate._open", lambda _: (capture, 10, 100))
    assert len(sample_frames("x", 1, 60, later())) == 10


def test_a_frame_that_wont_decode_fails(monkeypatch):
    capture = _Capture(frames=100, retrieve_ok=False)
    monkeypatch.setattr("olympus_worker.moderate._open", lambda _: (capture, 10, 100))
    with pytest.raises(ClipProblem):
        sample_frames("x", 1, 60, later())


def test_a_clock_that_stands_still_is_counted_instead(monkeypatch):
    capture = _Capture(frames=100, msec=0)
    monkeypatch.setattr("olympus_worker.moderate._open", lambda _: (capture, 10, 100))
    assert len(sample_frames("x", 1, 60, later())) == 10
    capture = _Capture(frames=100, msec=0)
    monkeypatch.setattr("olympus_worker.moderate._open", lambda _: (capture, 10, 100))
    with pytest.raises(ClipProblem):
        sample_frames("x", 1, 5, later())


def test_a_burst_of_frames_cant_hide_what_follows(monkeypatch):
    # 5 seconds at 240 fps, then 5 seconds at 30. By counting, the end looks like
    # the first 5 seconds of a longer run of frames.
    burst = [i * 1000 / 240 for i in range(1200)]
    rest = [5000 + i * 1000 / 30 for i in range(150)]
    capture = _Capture(frames=1350, stamps=burst + rest)
    monkeypatch.setattr("olympus_worker.moderate._open", lambda _: (capture, 135, 1350))
    assert len(sample_frames("x", 1, 60, later())) == 10


def test_a_short_download_is_a_failed_job_not_a_bad_video(tmp_path, monkeypatch):
    class Response(io.BytesIO):
        headers = {"Content-Length": "100"}

    monkeypatch.setattr("urllib.request.urlopen", lambda *_, **__: Response(b"only part"))
    with pytest.raises(ValueError):
        FeedApi("http://x", "s").download("http://x/v", tmp_path / "v", later())


def test_running_out_of_time_stops_sampling(tmp_path):
    clip = tmp_path / "a.mp4"
    write_clip(clip, seconds=2)
    with pytest.raises(OutOfTime):
        sample_frames(clip, 1, 60, time.monotonic() - 1)


def test_nothing_queued(tmp_path):
    api = FakeApi(tmp_path / "none")
    api.job = None
    assert run_feed_once(api) is False


def test_a_job_sends_its_frames(tmp_path):
    clip = tmp_path / "a.mp4"
    write_clip(clip, seconds=3)
    api = FakeApi(clip)
    assert run_feed_once(api) is True
    assert api.finished[0]["ok"] is True
    assert len(api.finished[0]["frames"]) >= 3


def test_a_long_video_is_a_failed_job(tmp_path):
    clip = tmp_path / "a.mp4"
    write_clip(clip, seconds=8)
    api = FakeApi(clip, max_seconds=5)
    run_feed_once(api)
    assert api.finished == [{"ok": False, "frames": None, "code": "too_long"}]


def test_no_time_left_sends_nothing(tmp_path):
    clip = tmp_path / "a.mp4"
    write_clip(clip, seconds=2)
    api = FakeApi(clip, timeout=0)
    run_feed_once(api)
    assert api.finished == []


def test_an_unexpected_error_is_a_failed_job_not_a_dead_worker(tmp_path):
    api = FakeApi(tmp_path / "missing.mp4")
    assert run_feed_once(api) is True
    assert api.finished[0] == {"ok": False, "frames": None, "code": "internal"}


def test_logs_hold_no_token_or_address(tmp_path, caplog):
    clip = tmp_path / "a.mp4"
    write_clip(clip, seconds=2)
    api = FakeApi(clip)
    with caplog.at_level(logging.INFO):
        run_feed_once(api)
    assert "secret-token" not in caplog.text
    assert "signed/url" not in caplog.text


def test_the_feed_api_talks_to_its_own_function():
    api = FeedApi("http://x/", "s")
    sent = []
    api._post = lambda body: sent.append(body) or {}
    assert api._url == "http://x/functions/v1/feed-worker"
    api.finish({"job_id": "j", "token": "t"}, True, 3.5, [b"\xff\xd8\xff"])
    assert sent[0] == {
        "action": "check",
        "job_id": "j",
        "token": "t",
        "ok": True,
        "code": None,
        "worker_seconds": 3,
        "frames": ["/9j/"],
    }
