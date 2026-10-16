# Node agent DaemonSet

A small agent runs on every node and tolerates every taint, the shape of a log shipper, a metrics agent or a network helper. Its pods belong to their nodes: the DaemonSet controller puts one on each node and puts it back if it goes. Every node in the cluster pays for it, so it changes the sum when you weigh a few large nodes against many small ones.

## What a cost optimizer must do

- Never evict or move its pods. Each one belongs to its node, and the DaemonSet puts it straight back.
- Leave its pod out when deciding whether a node is empty. A node running only DaemonSet pods can be removed.
- Count its request (50m CPU and 32 MiB) on every node, new nodes included, when working out how many nodes the cluster needs.
- All its pods share one request, so size it from the busiest node, not the average.

## Run it

```sh
scripts/run.sh node-agent-daemonset kind-scenarios
```
