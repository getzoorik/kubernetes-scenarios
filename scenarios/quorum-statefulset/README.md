# Quorum StatefulSet

Three pods form a quorum, the shape of etcd, ZooKeeper or a Kafka controller set. Each pod has a stable name, quorum-0 to quorum-2, and its own 64 MiB volume, and each starts only after the one before it is Ready. A PodDisruptionBudget lets one pod be down at a time, because losing two of three would lose the quorum. Each pod writes its name to its volume and serves it, so you can see that a moved pod kept its data.

## What a cost optimizer must do

- Move one pod at a time, and wait until it is Ready again before moving the next.
- Each pod comes back with the same name and the same volume. Only place it where that volume can attach.
- Never delete the PersistentVolumeClaims (data-quorum-0, data-quorum-1, data-quorum-2) to free a node.
- A request change rolls the pods one at a time from quorum-2 down to quorum-0. That is slow by design, not stuck.

## Run it

```sh
scripts/run.sh quorum-statefulset kind-scenarios
```
