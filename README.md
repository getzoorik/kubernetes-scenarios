# Kubernetes scenarios

Ready-made Kubernetes situations you can start on a local kind cluster in a minute. Each one is a shape we have met in real clusters, and each one says what a cost optimizer must do about it.

Use them to try an optimizer, an autoscaler or your own scripts against something realistic, or to show a teammate a tricky case. If you meet a shape in a real cluster that is not here yet, please add it: see [CONTRIBUTING.md](CONTRIBUTING.md). The library is maintained by [Zoorik](https://zoorik.com).

## Scenarios

| Scenario | What it shows | Needs |
| --- | --- | --- |
| [autoscaled-gateway](scenarios/autoscaled-gateway) | Two replicas, a CPU autoscaler and a PodDisruptionBudget that allows one pod down | metrics-server |
| [keda-queue-worker](scenarios/keda-queue-worker) | A worker that KEDA scales from zero to six on the length of a Redis list | KEDA |
| [node-agent-daemonset](scenarios/node-agent-daemonset) | An agent on every node that must never be moved | Nothing |
| [over-requested-web-app](scenarios/over-requested-web-app) | A web app that asks for 4 CPU across two pods and uses about 0.2 | Nothing |
| [quorum-statefulset](scenarios/quorum-statefulset) | Three pods with a volume each, one down at a time | Nothing |
| [recreate-strategy](scenarios/recreate-strategy) | A rollout that stops every pod before new ones start | Nothing |
| [single-replica-database](scenarios/single-replica-database) | One Postgres pod with a ReadWriteOnce volume and no second copy | Nothing |
| [topology-spread](scenarios/topology-spread) | Three replicas spread evenly across nodes, and softly across zones | Nothing |

## Quick start

You need Docker with at least 4 CPUs and 8 GB of memory, [kind](https://kind.sigs.k8s.io) 0.33 or newer and kubectl. The two scenarios that need an add-on also need helm.

```sh
git clone https://github.com/getzoorik/kubernetes-scenarios
cd kubernetes-scenarios
kind create cluster --config kind/cluster.yaml
scripts/run.sh over-requested-web-app kind-scenarios
```

The cluster is called `scenarios`, so its kubectl context is `kind-scenarios`. It runs Kubernetes 1.36 on one control plane and three workers, one in each of the zones `zone-a`, `zone-b` and `zone-c`.

`scripts/run.sh` takes the scenario and the context, always both, so it only ever writes to the cluster you named. It installs any add-on the scenario needs, applies the manifests, waits until every workload is Ready, and then prints what is running and what a cost optimizer must do.

You can also apply a scenario yourself:

```sh
kubectl --context kind-scenarios apply -f scenarios/recreate-strategy/manifests
```

To clean up:

```sh
kubectl --context kind-scenarios delete namespace over-requested-web-app
kubectl --context kind-scenarios delete namespace -l app.kubernetes.io/part-of=kubernetes-scenarios
kind delete cluster --name scenarios
```

The first line removes one scenario, the second removes every scenario, and the third removes the cluster.

## How a scenario is laid out

```text
scenarios/<name>/
  scenario.yaml        what it is, what it needs, what must happen
  README.md            one paragraph and the expected behaviour
  manifests/           plain Kubernetes YAML, applied in file-name order
    00-namespace.yaml
    <workload>.yaml
```

Here is a `scenario.yaml`:

```yaml
name: autoscaled-gateway
summary: A gateway with two replicas, a CPU autoscaler and a PodDisruptionBudget that allows one pod down.
kubernetes: "1.23"
exercises:
  - a HorizontalPodAutoscaler that owns the replica count
  - a PodDisruptionBudget with maxUnavailable 1
expected:
  - Leave the replica count to the HPA. Never change spec.replicas or the HPA's bounds.
  - Move at most one gateway pod at a time, and wait until it is Ready before moving the next.
requires: [metrics-server]
```

| Field | What it holds |
| --- | --- |
| `name` | The folder name. It is also the namespace every object goes in. |
| `summary` | One sentence. |
| `kubernetes` | The oldest Kubernetes minor version the manifests work on, in quotes. `scripts/validate.sh` checks the manifests against it. |
| `exercises` | What the scenario puts in front of a tool, as a short list. |
| `expected` | What a cost optimizer must do, as a short list. Each item is something you can check on the cluster. |
| `requires` | Optional. The add-ons the scenario needs, on one line, such as `[keda]` or `[metrics-server]`. `scripts/run.sh` installs them. |

The manifests follow three rules:

- Every object lives in the scenario's own namespace, which `00-namespace.yaml` creates with the label `app.kubernetes.io/part-of: kubernetes-scenarios`.
- Requests are small, so a scenario fits the kind cluster on a 4-CPU machine.
- Images are public and pinned by tag and digest.

## Checks

`scripts/validate.sh` checks that every `scenario.yaml` has its fields and that every image is pinned by digest. It then checks every manifest against the scenario's Kubernetes version, using kubeconform v0.8.0 and, for KEDA objects, the schemas in the CRDs catalog. The first run downloads kubeconform into `.bin/` and verifies its checksum.

CI runs `scripts/validate.sh` on every pull request and on `main`. It then starts the cluster from `kind/cluster.yaml` and runs every scenario with `scripts/run.sh`, add-ons included, until every workload is Ready.

## Licence

Apache-2.0, see [LICENSE](LICENSE). Copyright 2026 Zoorik Private Limited.
