#!/usr/bin/env sh

set -eu

if [ $# -eq 0 ] || [ "$1" = -h ] || [ "$1" = --help ]; then
  cat <<EOF
Usage: ${0##*/} [BUILDX_FLAGS] CONTEXT_DIR

Small helper to build images with additional build contexts locally.

EXAMPLES

    ${0##*/} --progress=plain --tag calico-cni --load images/calico-cni/v3.26.4-0

    ${0##*/} --progress=plain \\
      --platform linux/amd64,linux/arm64,linux/arm/v7 \\
      --tag ttl.sh/calico-node --push \\
      images/calico-node/v3.26.4-0
EOF
  exit
fi

dir=$(CDPATH='' cd -- "$(eval echo "\$$#")" && pwd -P)

for ctx in "$dir"/build-contexts/*; do
  set -- --build-context="${ctx##*/}=$ctx" "$@"
done

exec docker buildx build "$@"
