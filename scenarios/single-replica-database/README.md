# Single-replica database

A Postgres database runs as a one-replica Deployment with a 1 GiB ReadWriteOnce volume. There is no second copy, so every restart is downtime, and the volume attaches to one node at a time. On kind the volume lives on one node's disk; on a cloud it lives in one zone. The Deployment uses the Recreate strategy, because a new pod on another node could not attach the volume while the old pod still holds it. The database trusts every connection, which is fine on a local kind cluster and nowhere else.

## What a cost optimizer must do

- Treat any move or rollout of this pod as downtime. There is no second replica.
- Only place it where its volume can attach. On kind that is the volume's node, on a cloud the volume's zone.
- Never delete or recreate the PersistentVolumeClaim. The data lives there.
- Size memory from its busiest period. Running out of memory here is an outage.

## Run it

```sh
scripts/run.sh single-replica-database kind-scenarios
```
