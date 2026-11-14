FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN apt-get update && apt-get install -y --no-install-recommends libglib2.0-0 libgomp1 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# Without its dependencies, because it would pull in a second, GUI build of OpenCV.
RUN pip install --no-cache-dir --no-deps rtmlib==0.0.16
RUN useradd --create-home worker
USER worker
COPY --chown=worker:worker . .

FROM base AS test
RUN pip install --no-cache-dir --user pytest==8.3.5
RUN python -m pytest -q tests && touch /home/worker/tested

# Models are in the image, checked by hash, so nothing downloads at run time.
FROM base AS release
# Copied so the tests have to pass: a builder skips a stage nothing needs.
COPY --from=test /home/worker/tested /home/worker/tested
COPY --chown=worker:worker models.sha256 /home/worker/models.sha256
RUN python -c "from rtmlib import Body; Body(mode='balanced', backend='onnxruntime', device='cpu')" \
  && cd /home/worker/.cache/rtmlib/hub/checkpoints && sha256sum -c /home/worker/models.sha256
CMD ["python", "-m", "olympus_worker"]
