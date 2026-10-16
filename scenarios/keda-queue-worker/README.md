# KEDA queue worker

A producer pushes 40 jobs onto a Redis list every two minutes. A worker takes the jobs one at a time and spends about 0.2 CPU-seconds on each, then waits 0.8 seconds as if it were calling another service. KEDA watches the list and scales the worker from zero up to six replicas, and back to zero a minute after the list is empty. Use swings from nothing to busy in seconds, which is how most queue workers look. The scenario needs KEDA, which `scripts/run.sh` installs when the cluster has none.

## What a cost optimizer must do

- Leave the worker's replica count to KEDA. Never change spec.replicas, the ScaledObject or the HPA that KEDA made.
- Size the worker from its busy periods. Idle minutes and time at zero replicas say nothing about how big a pod must be.
- A worker at zero has nothing to measure. That is not a reason to change its requests.
- Plan nodes for the burst that comes every two minutes, not for the quiet minute in between.

## Run it

```sh
scripts/run.sh keda-queue-worker kind-scenarios
```
