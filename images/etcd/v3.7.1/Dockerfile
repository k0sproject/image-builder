# SPDX-FileCopyrightText: 2026 k0s authors
# SPDX-License-Identifier: Apache-2.0

# The upstream etcd image is distroless and has no shell, but k0smotron drives
# etcd through shell init/entrypoint scripts. So take the upstream binaries and
# put them on Alpine, which provides bash and the busybox userland.

ARG \
  ETCD_IMAGE=gcr.io/etcd-development/etcd:v3.7.1 \
  BASEIMAGE=docker.io/library/alpine:3.23

FROM $ETCD_IMAGE AS upstream

FROM $BASEIMAGE
LABEL org.opencontainers.image.title="etcd" \
  org.opencontainers.image.vendor=k0sproject \
  org.opencontainers.image.source=https://github.com/k0sproject/image-builder \
  org.opencontainers.image.licenses=Apache-2.0 \
  org.opencontainers.image.url=https://github.com/etcd-io/etcd \
  org.opencontainers.image.version=v3.7.1

RUN apk add --no-cache bash

COPY --from=upstream /usr/local/bin/etcd /usr/local/bin/etcdctl /usr/local/bin/etcdutl /usr/local/bin/

# uid/gid 1001 keeps parity with the previous bitnami based image, matching the
# fsGroup k0smotron sets on the etcd pods.
RUN addgroup -g 1001 etcd && adduser -D -H -u 1001 -G etcd etcd
USER 1001:1001

EXPOSE 2379 2380
ENTRYPOINT ["/usr/local/bin/etcd"]
