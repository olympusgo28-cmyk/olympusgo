import glob
import logging
import os
import shutil
import signal
import sys
import tempfile

from .api import Api
from .pose import Pose
from .run import run_forever

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
# Stopping unwinds the job, so its temp folder goes with it.
signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
# A crash can't unwind, so a restarted container clears what was left.
for folder in glob.glob(os.path.join(tempfile.gettempdir(), "clip-*")):
    shutil.rmtree(folder, ignore_errors=True)
run_forever(Api(os.environ["OLYMPUS_URL"], os.environ["ANALYSIS_WORKER_SECRET"]), Pose())
