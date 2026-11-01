"""Talks to the analysis-worker function. Holds only the fleet secret."""
import base64
import http.client
import json
import time
import urllib.error
import urllib.request

from .metrics import OutOfTime

MAX_BYTES = 250 * 1024 * 1024
TIMEOUT_SECONDS = 60


class BadResult(Exception):
    """The server won't take this result, so sending it again can't help."""


class Api:
    def __init__(self, url, secret):
        self._url = url.rstrip("/") + "/functions/v1/analysis-worker"
        self._secret = secret

    def _post(self, body):
        request = urllib.request.Request(
            self._url,
            data=json.dumps(body).encode(),
            headers={"content-type": "application/json", "x-worker-secret": self._secret},
        )
        try:
            with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            detail = error.read()
            if error.code == 400 or b"Bad result" in detail:
                raise BadResult() from None
            # Otherwise 403 means the job is over or isn't ours. Nothing more to do.
            if error.code == 403:
                return {"status": "refused"}
            raise

    def claim(self):
        return self._post({"action": "claim"}).get("job")

    def may_continue(self, job):
        try:
            answer = self._post({"action": "continue", "job_id": job["job_id"], "token": job["token"]})
        except (OSError, ValueError, http.client.HTTPException):
            # A dropped call isn't a no. The next check asks again, and the
            # result is refused anyway if the job has ended.
            return True
        return answer.get("continue") is True

    def finish(self, job, ok, seconds, result=None, code=None, frame=None):
        body = {
            "action": "result",
            "job_id": job["job_id"],
            "kind": job["kind"],
            "token": job["token"],
            "ok": ok,
            "result": result,
            "code": code,
            "worker_seconds": int(seconds),
        }
        if frame is not None:
            body["frame"] = base64.b64encode(frame).decode()
        return self._post(body)

    def download(self, url, path, deadline):
        with urllib.request.urlopen(url, timeout=TIMEOUT_SECONDS) as response, open(path, "wb") as out:
            copied = 0
            while chunk := response.read(1024 * 1024):
                copied += len(chunk)
                if copied > MAX_BYTES:
                    raise ValueError("clip too big")
                if time.monotonic() > deadline:
                    raise OutOfTime()
                out.write(chunk)
