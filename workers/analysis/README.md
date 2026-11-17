# Analysis worker

Claims jobs from the `analysis-worker` Edge Function, reads the clip, and sends back numbers. It runs anywhere that can reach the project, and needs no open port.

```bash
docker build --target test -t olympus-worker-test workers/analysis
```

```bash
docker build --target release -t olympus-worker workers/analysis
```

```bash
docker run --rm -e OLYMPUS_URL=http://host.docker.internal:54321 -e ANALYSIS_WORKER_SECRET=local-analysis-secret olympus-worker
```

It needs `OLYMPUS_URL` and `ANALYSIS_WORKER_SECRET`, and never the service-role key. On a local stack, serve the functions with `ANALYSIS_PUBLIC_URL=http://host.docker.internal:54321`, so signed URLs reach the container.

The clip stays in a temp folder for the length of the job. Logs carry job ids and error names only. Only the chosen side of the court is measured. See `NOTICE` for what's reused and why Ultralytics isn't.

The numbers are unproven until they've been checked on real tripod clips.
