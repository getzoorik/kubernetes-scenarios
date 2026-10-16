# Contributing

Thanks for adding to the library. The most useful thing you can send is a new scenario: a shape you met in a real cluster that is not here yet. A fix to a scenario that does not behave as its README says is just as welcome.

The general guide for every getzoorik repository is the org's [contributing guide](https://github.com/getzoorik/.github/blob/main/CONTRIBUTING.md). This page covers scenarios.

## Add a scenario

1. Start from a shape you met in a real cluster. Leave out anything that could identify the cluster or its owner, such as names, registries, hostnames and figures only one company would have.
2. Copy the scenario closest to it, for example `cp -r scenarios/recreate-strategy scenarios/<new-name>`. Use lowercase words and hyphens, and name what the scenario is.
3. Edit `scenario.yaml`. The fields are described in the [README](README.md#how-a-scenario-is-laid-out).
4. Edit the manifests:
   - Put every object in a namespace named like the folder, and keep `00-namespace.yaml` with its label.
   - Keep requests small. The whole scenario must fit the kind cluster in `kind/cluster.yaml` on a machine with 4 CPUs. If the real case was bigger, scale it down, keep its shape, and say so in the README.
   - Use public images pinned by tag and digest. `docker buildx imagetools inspect <image>:<tag>` prints the digest.
   - Leave out secrets, keys and tokens, even fake ones.
   - Write plain YAML. No Helm, Kustomize or other templating.
5. Write `README.md`: one paragraph on the situation, then "What a cost optimizer must do" with the same list as `expected`.
6. Check it:

   ```sh
   scripts/validate.sh
   kind create cluster --config kind/cluster.yaml
   scripts/run.sh <new-name> kind-scenarios
   ```

7. Open a pull request. Say, in general terms, where you met the shape and what tools tend to get wrong about it. CI runs both checks again.

## Writing the expected behaviour

- Say what must happen, not how one tool does it.
- Keep each item short and checkable. Someone looking at the cluster after an optimizer ran should be able to say yes or no.
- Three or four items are usually enough. If you need ten, it is probably two scenarios.

## A scenario that needs an add-on

List the add-on in `requires`, for example `requires: [keda]`. If `scripts/run.sh` cannot install it yet, add a case for it there with a pinned chart version. The add-on's CRD schemas must be in the [CRDs catalog](https://github.com/datreeio/CRDs-catalog) so `scripts/validate.sh` can check its objects.

## Changing a scenario

People test against these scenarios, so keep each one stable. Change a scenario's shape only when it is wrong. A different shape is usually a new scenario.

## Licence, conduct and security

You do not need to sign off your commits or sign a contributor agreement. What you send is licensed under Apache-2.0, as section 5 of the [license](LICENSE) says.

Everyone here follows our [Code of Conduct](https://github.com/getzoorik/.github/blob/main/CODE_OF_CONDUCT.md). To report a problem, write to [founders@zoorik.com](mailto:founders@zoorik.com).

Found a security problem? Do not open an issue. Report it privately from the repository's **Security** tab with **Report a vulnerability**, or write to [founders@zoorik.com](mailto:founders@zoorik.com). The [security policy](https://github.com/getzoorik/.github/blob/main/SECURITY.md) has the details.
