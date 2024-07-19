# https://github.com/projectcalico/calico/blob/v3.26.4/node/Dockerfile.amd64

ARG \
  VERSION=3.26.4 \
  HASH=481e52de684c049f3f7f7bac78f0f6f4ae424d643451adc9e3d3fa9d03fb6d57 \
  IPSET_VERSION=7.17 \
  IPSET_HASH=be49c9ff489dd6610cad6541e743c3384eac96e9f24707da7b3929d8f2ac64d8

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.22.5-alpine3.20 AS builder

WORKDIR /go/src/calico
ARG VERSION HASH
RUN --mount=type=cache,id=calico-gomodcache,target=/go/pkg/mod \
  --mount=type=tmpfs,target=/tmp \
  --mount=from=patches,target=/run/patches,ro \
  set -e \
  && apk add --no-cache patch \
  && wget -O /tmp/src.tar.gz https://github.com/projectcalico/calico/archive/refs/tags/v$VERSION.tar.gz \
  && { printf '%s */tmp/src.tar.gz' "$HASH" | sha256sum -c -; } \
  && tar xf /tmp/src.tar.gz --strip-components=1 \
  && for p in /run/patches/*; do \
    echo Applying "${p##*/}" >&2; \
    patch -p1 <"$p"; \
  done \
  && go mod download -x

ARG TARGETARCH
RUN --mount=type=cache,id=calico-gomodcache,target=/go/pkg/mod,ro \
  --mount=type=cache,id=calico-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=tmpfs,target=/tmp \
  --network=none \
  GOARCH=$TARGETARCH CGO_ENABLED=0 go build \
    -v -buildvcs=false \
    -ldflags "-s -w -X github.com/projectcalico/calico/node/pkg/lifecycle/startup.VERSION=v$VERSION+k0s.0" \
    -o /out/calico-node \
    ./node/cmd/calico-node

FROM docker.io/library/alpine:3.19.2 AS ipset
RUN apk add --no-cache \
  build-base pkgconf curl \
  libmnl-dev libmnl-static

ARG IPSET_VERSION IPSET_HASH
RUN curl -sSLo ipset.tar.bz2 "http://ipset.netfilter.org/ipset-$IPSET_VERSION.tar.bz2" \
  && { echo "$IPSET_HASH *ipset.tar.bz2" | sha256sum -c -; } \
  && mkdir -p /src/ipset && tar xf "ipset.tar.bz2" --strip-components=1 -C /src/ipset \
  && rm -- "ipset.tar.bz2"

WORKDIR /src/ipset
RUN printf '#!/usr/bin/env sh\nexec cc -static "$@"\n' >/src/cc-static && chmod +x /src/cc-static
RUN CC=/src/cc-static CFLAGS=-static LDFLAGS=-static ./configure --enable-static --disable-shared --with-kmod=no
RUN make -j && strip src/ipset
RUN make install

FROM docker.io/calico/node:v$VERSION AS intermediate
COPY --from=builder /out/calico-node /usr/bin/calico-node
COPY --from=ipset /usr/local/sbin/ipset /usr/sbin/ipset
COPY --from=ipset /src/ipset/ChangeLog /usr/share/doc/ipset/ChangeLog

FROM scratch
COPY --from=intermediate / /
ENV SVDIR=/etc/service/enabled
CMD ["start_runit"]
