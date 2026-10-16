#!/usr/bin/env bash
set -euo pipefail

version=v0.8.0
k8s_schemas=https://raw.githubusercontent.com/yannh/kubernetes-json-schema/8df8a883b68a24a104b4a9e43c1288090ae60b3b
crd_schemas=https://raw.githubusercontent.com/datreeio/CRDs-catalog/d373c2da9702bc9509a004db83e57263fe3bdfc1

root=$(cd "$(dirname "$0")/.." && pwd)
kubeconform="$root/.bin/kubeconform-$version"

if [ ! -x "$kubeconform" ]; then
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  arch=$(uname -m)
  case $arch in
    x86_64) arch=amd64 ;;
    aarch64) arch=arm64 ;;
  esac
  case "$os-$arch" in
    darwin-amd64) sum=71dbc87ac9f24099a62b93570e65aa06312ba6ac8aea63b7f86e9d999edf5a92 ;;
    darwin-arm64) sum=f84f4dfbebf4a6b0b230385fa065a39ea35e02608c2b50d025dcf64775a69d67 ;;
    linux-amd64) sum=9bc2bffbf71f261128533edaf912153948b7ff238f9a531ae6d34466ec287883 ;;
    linux-arm64) sum=1f53fc8e81258197a35e8603054162a5af1de8c5af13746c71ab680d9534ed87 ;;
    *) echo "kubeconform $version has no build for $os-$arch" >&2; exit 1 ;;
  esac
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL -o "$tmp/kubeconform.tar.gz" "https://github.com/yannh/kubeconform/releases/download/$version/kubeconform-$os-$arch.tar.gz"
  got=$( (sha256sum "$tmp/kubeconform.tar.gz" 2>/dev/null || shasum -a 256 "$tmp/kubeconform.tar.gz") | cut -d ' ' -f 1)
  if [ "$got" != "$sum" ]; then
    echo "the kubeconform download does not match its checksum" >&2
    exit 1
  fi
  tar -xzf "$tmp/kubeconform.tar.gz" -C "$tmp" kubeconform
  mkdir -p "$root/.bin"
  mv "$tmp/kubeconform" "$kubeconform"
fi

failed=0
fail() {
  echo "$1: $2" >&2
  failed=1
}

for dir in "$root"/scenarios/*/; do
  name=$(basename "$dir")
  meta="$dir/scenario.yaml"

  if [ ! -f "$meta" ]; then
    fail "$name" "scenario.yaml is missing"
    continue
  fi
  for key in name summary kubernetes exercises expected; do
    grep -q "^$key:" "$meta" || fail "$name" "scenario.yaml has no $key"
  done
  [ "$(sed -n 's/^name: *//p' "$meta")" = "$name" ] || fail "$name" "the name in scenario.yaml must be $name"
  [ -f "$dir/README.md" ] || fail "$name" "README.md is missing"
  if grep -rn 'image:' "$dir/manifests" | grep -v '@sha256:'; then
    fail "$name" "pin every image by digest (name:tag@sha256:...)"
  fi

  minor=$(sed -n 's/^kubernetes: *"\{0,1\}\(1\.[0-9]*\)"\{0,1\} *$/\1/p' "$meta")
  if [ -z "$minor" ]; then
    fail "$name" "kubernetes in scenario.yaml must look like \"1.29\""
    continue
  fi

  echo "$name (Kubernetes $minor)"
  "$kubeconform" -strict -summary -kubernetes-version "$minor.0" \
    -schema-location "$k8s_schemas/{{.NormalizedKubernetesVersion}}-standalone{{.StrictSuffix}}/{{.ResourceKind}}{{.KindSuffix}}.json" \
    -schema-location "$crd_schemas/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json" \
    "$dir/manifests" || failed=1
done

exit "$failed"
