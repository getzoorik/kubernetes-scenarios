# Over-requested web app

Two pods serve a small page, and each burns about a tenth of a CPU. Each pod asks for 1 CPU and 512 MiB of memory, so the app holds 2 CPU and 1 GiB while it uses about 0.2 CPU and a few MiB. We met this shape in a real cluster: a web app asking for 4 CPU and using about 0.2, with every node it ran on paid for at the asked size. Splitting the 4 CPU over two pods keeps each pod small enough for a kind node on a 4-CPU machine.

## What a cost optimizer must do

- Lower each pod's CPU request to near its use (about 0.1 CPU) plus headroom, far below 1 CPU.
- Lower each pod's memory request to near its use plus headroom, far below 512 MiB.
- Keep two replicas. Only the size of each pod is wrong.
- Once the requests are small, both pods fit on one node, so a plan may free the other.

## Run it

```sh
scripts/run.sh over-requested-web-app kind-scenarios
```
