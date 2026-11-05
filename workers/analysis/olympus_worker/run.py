"""Claims a job, does it, reports back. The clip lives in a temp folder only for
the length of the job. Logs carry job ids and error names, nothing else."""
import logging
import os
import tempfile
import time

from .api import BadResult
from .metrics import ClipProblem, OutOfTime
from .video import analyse, find_court

log = logging.getLogger("olympus_worker")
IDLE_SECONDS = 5
# Left over from the job's time limit, to send the answer.
SEND_MARGIN_SECONDS = 30
SEND_TRIES = 4
SEND_WAIT_SECONDS = 2


def settle(api, job, ok, seconds, result=None, code=None, frame=None):
    """Sends the answer, a few times if it has to: a finished report took
    minutes to make."""
    for attempt in range(SEND_TRIES):
        try:
            api.finish(job, ok, seconds, result, code, frame)
            return
        except BadResult:
            log.warning("job %s: result refused", job["job_id"])
            if ok:
                settle(api, job, False, seconds, code="internal")
            return
        except Exception as error:
            log.warning("job %s: send failed: %s", job["job_id"], type(error).__name__)
            time.sleep(SEND_WAIT_SECONDS * (attempt + 1))
    log.warning("job %s: gave up sending", job["job_id"])


def run_once(api, pose):
    """Does one job. False when the queue is empty."""
    job = api.claim()
    if job is None:
        return False
    started = time.monotonic()
    deadline = started + job["timeout_seconds"] - SEND_MARGIN_SECONDS
    spent = lambda: time.monotonic() - started  # noqa: E731
    try:
        with tempfile.TemporaryDirectory(prefix="clip-") as folder:
            path = os.path.join(folder, "clip")
            api.download(job["clip_url"], path, deadline)
            if job["kind"] == "court":
                seconds, frame, corners = find_court(path, job["max_seconds"])
                settle(api, job, True, spent(), {"seconds": seconds, "corners": corners}, frame=frame)
            else:
                result = analyse(
                    path, job["corners"], job["side"], pose, lambda: api.may_continue(job), deadline
                )
                if result is None:
                    log.info("job %s stopped", job["job_id"])
                    return True
                settle(api, job, True, spent(), result)
        log.info("job %s done", job["job_id"])
    except OutOfTime:
        log.info("job %s out of time", job["job_id"])
    except ClipProblem as problem:
        log.info("job %s failed: %s", job["job_id"], problem.code)
        settle(api, job, False, spent(), code=problem.code)
    except Exception as error:  # A bad job must not stop the worker.
        log.warning("job %s failed: %s", job["job_id"], type(error).__name__)
        settle(api, job, False, spent(), code="internal")
    return True


def run_forever(api, pose):
    while True:
        try:
            if not run_once(api, pose):
                time.sleep(IDLE_SECONDS)
        except Exception as error:  # The API being down isn't a reason to stop.
            log.warning("worker loop: %s", type(error).__name__)
            time.sleep(IDLE_SECONDS)
