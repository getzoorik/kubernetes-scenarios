# Topology spread

An API runs three replicas with two spread rules. The hard rule keeps the replica counts on any two nodes within one of each other. The soft rule prefers spreading across zones. The cluster in `kind/cluster.yaml` has three workers in three zones, so each worker gets one replica. The hard rule sets `nodeTaintsPolicy: Honor`, so tainted nodes such as the kind control plane do not count. Without it, a tainted node counts as a node with no replicas, and a moved pod can stay Pending even though other nodes have room.

## What a cost optimizer must do

- Check every move against the hard rule before evicting. The nodes left must take the pod without any two of them differing by more than one replica.
- A plan step that leaves a replica Pending is a failed plan.
- Emptying one worker is allowed. Its replica moves to another worker, leaving two and one, which is within the rule.
- The zone rule is soft. It ranks where pods go but never blocks a move.

## Run it

```sh
scripts/run.sh topology-spread kind-scenarios
```
