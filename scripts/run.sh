#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: scripts/run.sh <scenario> <kube-context>" >&2
  echo "example: scripts/run.sh over-requested-web-app kind-scenarios" >&2
  exit 2
fi

name=$1
context=$2
root=$(cd "$(dirname "$0")/.." && pwd)
dir="$root/scenarios/$name"

if [ ! -f "$dir/scenario.yaml" ]; then
  echo "there is no scenario called $name in scenarios/" >&2
  exit 2
fi

k() {
  kubectl --context "$context" "$@"
}

requires=$(sed -n 's/^requires: *\[\(.*\)\] *$/\1/p' "$dir/scenario.yaml" | tr ',' ' ')
for addon in $requires; do
  case $addon in
    keda)
      if ! k get crd scaledobjects.keda.sh >/dev/null 2>&1; then
        echo "Installing KEDA, which $name needs"
        helm upgrade --install keda keda --repo https://kedacore.github.io/charts --version 2.21.0 \
          --namespace keda --create-namespace --wait --kube-context "$context"
      fi
      ;;
    metrics-server)
      if ! k get apiservice v1beta1.metrics.k8s.io >/dev/null 2>&1; then
        echo "Installing metrics-server, which $name needs"
        helm upgrade --install metrics-server metrics-server --repo https://kubernetes-sigs.github.io/metrics-server/ --version 3.14.0 \
          --namespace kube-system --set 'args={--kubelet-insecure-tls}' --wait --kube-context "$context"
      fi
      ;;
    *)
      echo "$name requires $addon, and scripts/run.sh does not know how to install it" >&2
      exit 1
      ;;
  esac
done

k apply --namespace "$name" -f "$dir/manifests"

for workload in $(k get deployments,statefulsets,daemonsets --namespace "$name" -o name); do
  if ! k rollout status "$workload" --namespace "$name" --timeout=300s; then
    k get pods --namespace "$name" -o wide
    k get events --namespace "$name" --sort-by=.lastTimestamp
    exit 1
  fi
done

echo
k get all,pvc,pdb --namespace "$name" -o wide
echo
awk '/^expected:/ { show = 1; print "What a cost optimizer must do:"; next } /^[^ ]/ { show = 0 } show' "$dir/scenario.yaml"
