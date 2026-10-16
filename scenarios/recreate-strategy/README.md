# Recreate strategy

An app that cannot run old and new versions side by side, for example one that changes a database schema when it starts, uses the Recreate strategy. Its two replicas serve as usual while nothing changes. A rollout, though, stops both pods before it starts new ones, so every change to the pod template is a short outage. Moving one pod is different: the Deployment only replaces the pod that went. There is no PodDisruptionBudget, which is common for apps like this.

## What a cost optimizer must do

- A change to the pod template, new requests included, stops both replicas at once. Make it only when that outage is allowed.
- Evicting one pod to move it is safe. The Deployment replaces only that pod while the other one serves.
- Nothing stops both pods being evicted together, and that is an outage too. Move them one at a time.

## Run it

```sh
scripts/run.sh recreate-strategy kind-scenarios
```
