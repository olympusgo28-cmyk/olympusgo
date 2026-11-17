import http.server
import json
import logging
import os
import threading
import time

import cv2
import numpy as np
import pytest

from olympus_worker.api import Api, BadResult
from olympus_worker.metrics import OutOfTime
from olympus_worker.run import run_once
from olympus_worker.vendor.good_badminton.court import CourtMapper
from olympus_worker.video import analyse, corners_ok

CORNERS = [[0.25, 0.1], [0.75, 0.1], [0.9, 0.9], [0.1, 0.9]]


def write_clip(path, seconds=3, fps=10):
    writer = cv2.VideoWriter(str(path), cv2.VideoWriter_fourcc(*"mp4v"), fps, (320, 240))
    assert writer.isOpened()
    for _ in range(int(seconds * fps)):
        writer.write(np.full((240, 320, 3), 60, dtype=np.uint8))
    writer.release()


class FakeApi:
    def __init__(self, job, clip):
        self.job = job
        self.clip = clip
        self.finished = []
        self.answer = True

    def claim(self):
        job, self.job = self.job, None
        return job

    def download(self, url, path, deadline):
        with open(self.clip, "rb") as source, open(path, "wb") as out:
            out.write(source.read())

    def may_continue(self, job):
        return self.answer

    def finish(self, job, ok, seconds, result=None, code=None, frame=None):
        self.finished.append({"ok": ok, "result": result, "code": code, "frame": frame})


class FakePose:
    """One person, walking across the near half."""

    def __init__(self):
        self.calls = 0

    def feet(self, image):
        self.calls += 1
        return [(100 + self.calls * 2, 190)]


def job(kind, **extra):
    return {
        "job_id": "j1",
        "kind": kind,
        "token": "t",
        "clip_url": "http://x/clip",
        "max_seconds": 180,
        "timeout_seconds": 900,
        "corners": CORNERS,
        "side": "near",
        **extra,
    }


def test_nothing_queued(tmp_path):
    assert run_once(FakeApi(None, None), FakePose()) is False


def test_a_court_job_gives_length_and_a_jpeg(tmp_path):
    clip = tmp_path / "c.mp4"
    write_clip(clip)
    api = FakeApi(job("court"), clip)
    assert run_once(api, FakePose()) is True
    done = api.finished[0]
    assert done["ok"] is True
    assert done["result"]["seconds"] == pytest.approx(3, abs=0.2)
    assert done["frame"][:3] == b"\xff\xd8\xff"


def test_a_long_clip_is_stopped_by_its_real_length(tmp_path):
    clip = tmp_path / "c.mp4"
    write_clip(clip, seconds=3)
    api = FakeApi(job("court", max_seconds=1), clip)
    run_once(api, FakePose())
    assert api.finished[0]["code"] == "too_long"


def test_a_file_that_isnt_a_video(tmp_path):
    clip = tmp_path / "c.mp4"
    clip.write_bytes(b"not a video at all")
    api = FakeApi(job("court"), clip)
    run_once(api, FakePose())
    assert api.finished[0]["code"] == "bad_video"


def test_an_analysis_gives_a_report(tmp_path):
    clip = tmp_path / "c.mp4"
    write_clip(clip)
    api = FakeApi(job("analyse"), clip)
    run_once(api, FakePose())
    done = api.finished[0]
    assert done["ok"] is True
    assert set(done["result"]) == {"distance_m", "avg_speed_ms", "top_speed_ms", "moving_seconds", "heatmap"}
    assert done["frame"] is None


def test_a_withdrawal_stops_the_work(tmp_path):
    clip = tmp_path / "c.mp4"
    write_clip(clip, seconds=30)
    api = FakeApi(job("analyse"), clip)
    api.answer = False
    pose = FakePose()
    run_once(api, pose)
    assert api.finished == []
    assert pose.calls <= 60


def test_an_unexpected_error_is_a_failed_job_not_a_dead_worker(tmp_path):
    class Broken(FakePose):
        def feet(self, image):
            raise RuntimeError("secret detail")

    clip = tmp_path / "c.mp4"
    write_clip(clip)
    api = FakeApi(job("analyse"), clip)
    assert run_once(api, Broken()) is True
    assert api.finished[0]["code"] == "internal"


def test_logs_carry_no_urls_tokens_or_details(tmp_path, caplog):
    class Broken(FakePose):
        def feet(self, image):
            raise RuntimeError("secret detail")

    clip = tmp_path / "c.mp4"
    write_clip(clip)
    api = FakeApi(job("analyse", token="sekrit", clip_url="http://signed/url"), clip)
    with caplog.at_level(logging.INFO):
        run_once(api, Broken())
    assert "sekrit" not in caplog.text
    assert "signed" not in caplog.text
    assert "secret detail" not in caplog.text


def test_the_clip_is_gone_after_the_job(tmp_path, monkeypatch):
    seen = {}

    class Spy(FakeApi):
        def download(self, url, path, deadline):
            seen["path"] = path
            super().download(url, path, deadline)

    clip = tmp_path / "c.mp4"
    write_clip(clip)
    run_once(Spy(job("analyse"), clip), FakePose())
    assert not os.path.exists(seen["path"])


def test_the_clip_is_gone_after_a_failed_job_too(tmp_path):
    seen = {}

    class Spy(FakeApi):
        def download(self, url, path, deadline):
            seen["path"] = path
            super().download(url, path, deadline)

    class Broken(FakePose):
        def feet(self, image):
            raise RuntimeError("no")

    clip = tmp_path / "c.mp4"
    write_clip(clip)
    run_once(Spy(job("analyse"), clip), Broken())
    assert not os.path.exists(seen["path"])


def test_a_clip_under_a_second_is_a_bad_video(tmp_path):
    clip = tmp_path / "c.mp4"
    write_clip(clip, seconds=0.5)
    api = FakeApi(job("court"), clip)
    run_once(api, FakePose())
    assert api.finished[0]["code"] == "bad_video"


def test_crossed_corners_are_refused(tmp_path):
    clip = tmp_path / "c.mp4"
    write_clip(clip)
    crossed = [CORNERS[1], CORNERS[0], CORNERS[2], CORNERS[3]]
    api = FakeApi(job("analyse", corners=crossed), clip)
    run_once(api, FakePose())
    assert api.finished[0]["code"] == "no_court"


def test_which_corners_are_good():
    assert corners_ok(CORNERS)
    assert not corners_ok(CORNERS[2:] + CORNERS[:2])
    assert not corners_ok(list(reversed(CORNERS)))


def test_the_far_end_of_the_picture_maps_to_the_far_end_of_the_court():
    mapper = CourtMapper([(x * 320, y * 240) for x, y in CORNERS])
    assert mapper.image_to_court((160, 30))[1] < 6.7
    assert mapper.image_to_court((160, 210))[1] > 6.7


def test_past_its_time_a_job_stops(tmp_path):
    clip = tmp_path / "c.mp4"
    write_clip(clip)
    with pytest.raises(OutOfTime):
        analyse(clip, CORNERS, "near", FakePose(), lambda: True, time.monotonic() - 1)
    api = FakeApi(job("analyse", timeout_seconds=1), clip)
    run_once(api, FakePose())
    assert api.finished == []


def test_a_refused_report_becomes_a_failure_not_a_stuck_job(tmp_path):
    class Refusing(FakeApi):
        def finish(self, job, ok, seconds, result=None, code=None, frame=None):
            super().finish(job, ok, seconds, result, code, frame)
            if ok:
                raise BadResult()

    clip = tmp_path / "c.mp4"
    write_clip(clip)
    api = Refusing(job("analyse"), clip)
    run_once(api, FakePose())
    assert [f["code"] for f in api.finished] == [None, "internal"]


def test_a_report_refused_on_the_last_try_still_fails_the_job(tmp_path, monkeypatch):
    monkeypatch.setattr("olympus_worker.run.SEND_WAIT_SECONDS", 0)

    class Late(FakeApi):
        def finish(self, job, ok, seconds, result=None, code=None, frame=None):
            super().finish(job, ok, seconds, result, code, frame)
            if ok and len(self.finished) < 4:
                raise OSError("dropped")
            if ok:
                raise BadResult()

    clip = tmp_path / "c.mp4"
    write_clip(clip)
    api = Late(job("analyse"), clip)
    run_once(api, FakePose())
    assert api.finished[-1]["code"] == "internal"


def test_a_dropped_answer_is_sent_again(tmp_path, monkeypatch):
    monkeypatch.setattr("olympus_worker.run.SEND_WAIT_SECONDS", 0)

    class Dropping(FakeApi):
        def finish(self, job, ok, seconds, result=None, code=None, frame=None):
            super().finish(job, ok, seconds, result, code, frame)
            if len(self.finished) < 3:
                raise OSError("dropped")

    clip = tmp_path / "c.mp4"
    write_clip(clip)
    api = Dropping(job("analyse"), clip)
    run_once(api, FakePose())
    assert len(api.finished) == 3
    assert all(f["ok"] for f in api.finished)


def serve(status, body):
    class Handler(http.server.BaseHTTPRequestHandler):
        def do_POST(self):
            self.rfile.read(int(self.headers["content-length"]))
            self.send_response(status)
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass

    server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server, Api(f"http://127.0.0.1:{server.server_port}", "s")


def test_the_api_tells_a_bad_result_from_a_job_thats_over():
    server, api = serve(403, json.dumps({"error": "Bad result."}).encode())
    with pytest.raises(BadResult):
        api.finish(job("analyse"), True, 1, {})
    server.shutdown()
    server, api = serve(403, json.dumps({"error": "Bad token."}).encode())
    assert api.finish(job("analyse"), True, 1, {}) == {"status": "refused"}
    assert api.may_continue(job("analyse")) is False
    server.shutdown()


def test_a_dropped_check_isnt_a_stop():
    server, api = serve(500, b"")
    assert api.may_continue(job("analyse")) is True
    server.shutdown()
