# Autoscaled gateway

An nginx gateway runs two replicas. A HorizontalPodAutoscaler keeps it between 2 and 6 replicas and aims at 70% of the CPU request, and a PodDisruptionBudget lets only one pod be down at a time. This is the usual shape of an edge service, and it ties the size of each pod to the number of pods: change the request and the autoscaler answers. The autoscaler needs metrics-server, which `scripts/run.sh` installs when the cluster has none.

## What a cost optimizer must do

- Leave the replica count to the HPA. Never change spec.replicas or the HPA's bounds.
- Size the CPU request knowing the HPA scales on use divided by request. A smaller request means higher utilisation and possibly more replicas.
- Move at most one gateway pod at a time, and wait until it is Ready before moving the next.
- Move pods through the eviction API so the PodDisruptionBudget is respected. Never delete pods directly to get round it.

## Run it

```sh
scripts/run.sh autoscaled-gateway kind-scenarios
```
