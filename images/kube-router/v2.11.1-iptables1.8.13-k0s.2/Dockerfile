ARG \
  KUBE_ROUTER_VERSION=v2.11.1 \
  KUBE_ROUTER_REVISION=61066dc66a535f94761f447a90874d0a6839d0d3 \
  # https://github.com/cloudnativelabs/kube-router/blob/v2.11.1/Makefile#L40 (v4.8.0)
  GOBGP_REVISION=10495227d00666041c98244088b73fa80a59f86c \
  ALPINE_IMAGE=docker.io/library/alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b \
  BUILDER_IMAGE=docker.io/library/golang:1.26.7-alpine3.24@sha256:28d89ee9cc0ff9fec75c82ca201e6bf7fdf9a679d4b7b24dfa04f2bb766bb468 \
  IPTABLES_VERSION=1.8.13 \
  IPTABLES_HASH=1afcd33da9e8f913ace6a2126788162e207e26f5d5e29c6573c0e581ffc58b99 \
  IPTABLES_WRAPPER_REVISION=bfef9e5087a198b50a4124bb9ce9d2c7c99025dd \
  IPSET_VERSION=7.24 \
  IPSET_HASH=fbe3424dff222c1cb5e5c34d38b64524b2217ce80226c14fdcbb13b29ea36112

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base
RUN apk add --no-interactive --no-cache git make
ENV GOTOOLCHAIN=local


FROM build-base AS build-gobgp

ARG GOBGP_REVISION
WORKDIR /go/src/gobgp
RUN --mount=source=patches/gobgp,target=/run/patches,ro \
  git -C .. -c advice.detachedHead=false clone --revision "$GOBGP_REVISION" https://github.com/osrg/gobgp.git \
  && git apply /run/patches/*.patch
RUN go mod download

ARG TARGETARCH
RUN --mount=type=cache,id=kube-router-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  GOARCH="$TARGETARCH" CGO_ENABLED=0 go build -mod=readonly -trimpath -buildvcs=false -ldflags "-s -w" ./cmd/gobgp


FROM build-base AS build-kube-router

ARG KUBE_ROUTER_REVISION
WORKDIR /go/src/kube-router
RUN git -C .. -c advice.detachedHead=false clone --revision "$KUBE_ROUTER_REVISION" https://github.com/cloudnativelabs/kube-router.git
RUN go mod download

ARG KUBE_ROUTER_VERSION TARGETARCH
RUN --mount=type=cache,id=kube-router-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  BUILD_DATE=$(git log -1 --date=format:%Y-%m-%dT%H:%M:%S%z --format=%cd) \
  && GOARCH="$TARGETARCH" CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/cloudnativelabs/kube-router/v2/pkg/version.Version=$KUBE_ROUTER_VERSION -X github.com/cloudnativelabs/kube-router/v2/pkg/version.BuildDate=$BUILD_DATE" \
    -trimpath -buildvcs=false ./cmd/kube-router


FROM build-base AS build-iptables-wrappers

ARG IPTABLES_WRAPPER_REVISION
WORKDIR /go/src/iptables-wrappers
RUN git -C .. -c advice.detachedHead=false clone --revision "$IPTABLES_WRAPPER_REVISION" https://github.com/kubernetes-sigs/iptables-wrappers
RUN go mod download

ARG TARGETARCH
RUN --mount=type=tmpfs,target=/go/src/iptables-wrappers/bin \
  --mount=type=cache,id=kube-router-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  du -sh /root/.cache/go-build \
  && GOARCH="$TARGETARCH" make build \
  && mv bin/iptables-wrapper .


FROM $ALPINE_IMAGE AS build-iptables

RUN apk add --no-interactive --no-cache \
  build-base pkgconf \
  linux-headers \
  libmnl-dev libmnl-static \
  libnftnl-dev

ARG IPTABLES_VERSION IPTABLES_HASH
WORKDIR /src/iptables
RUN --mount=type=tmpfs,target=/tmp \
  wget -qO /tmp/sources.tar.gz https://www.netfilter.org/projects/iptables/files/iptables-$IPTABLES_VERSION.tar.xz \
  && { echo $IPTABLES_HASH /tmp/sources.tar.gz | sha256sum -c -; } \
  && tar xf /tmp/sources.tar.gz --strip-components=1

# -D__UAPI_DEF_ETHHDR is required to build on musl.
# If this CFLAG isn't defined, itpables will define it in include/xtables.h
# and will have a conflict with musl, which defines it in
# /usr/include/netinet/if_ether.h
RUN --network=none \
  CFLAGS="-Os -D__UAPI_DEF_ETHHDR=0" ./configure --sysconfdir=/etc --enable-static --disable-shared --without-kernel --disable-devel

RUN --network=none \
  make -j$(nproc) LDFLAGS=-all-static
RUN --network=none \
  make -j$(nproc) install \
  && strip /usr/local/sbin/xtables-*


FROM $ALPINE_IMAGE AS build-ipset
RUN apk add --no-interactive --no-cache \
  build-base pkgconf \
  libmnl-dev libmnl-static


ARG IPSET_VERSION IPSET_HASH
WORKDIR /src/ipset
RUN --mount=type=tmpfs,target=/tmp \
  wget -qO /tmp/sources.tar.gz https://ipset.netfilter.org/ipset-$IPSET_VERSION.tar.bz2 \
  && { echo $IPSET_HASH /tmp/sources.tar.gz | sha256sum -c -; } \
  && tar xf /tmp/sources.tar.gz --strip-components=1

RUN --network=none \
  printf '#!/usr/bin/env sh\nexec cc -static "$@"\n' >/src/cc-static && chmod +x /src/cc-static \
  && CC=/src/cc-static CFLAGS=-static LDFLAGS=-static ./configure --enable-static --disable-shared --with-kmod=no \
  && make \
  && strip src/ipset \
  && make install
# Just a sanity check that it's not segfaulting
RUN --network=none ipset -h


FROM $ALPINE_IMAGE AS build-baselayout
RUN  mkdir -p -- /opt/stage/etc/apk \
  && cp -a /etc/apk/repositories /etc/apk/keys /opt/stage/etc/apk \
  && apk add --no-interactive --root /opt/stage --initdb \
    alpine-release \
    ca-certificates-bundle \
    busybox \
    iproute2 \
    conntrack-tools \
    nftables \
  && rm -r /opt/stage/etc/apk/repositories /opt/stage/var/cache


FROM scratch
LABEL org.opencontainers.image.licenses="Apache-2.0" \
  org.opencontainers.image.source="https://github.com/cloudnativelabs/kube-router"
COPY --from=build-baselayout /opt/stage /
RUN --mount=from=build-iptables,source=/usr/local,target=/run/stage/iptables,ro \
  --mount=from=build-iptables-wrappers,source=/go/src/iptables-wrappers,target=/run/stage/iptables-wrappers,ro \
  --network=none \
  cp -a /run/stage/iptables/sbin/xtables-* /run/stage/iptables/sbin/iptables* /run/stage/iptables/sbin/ip6tables* /usr/sbin/ \
  && cp -a /run/stage/iptables-wrappers/iptables-wrapper /usr/sbin/iptables-wrapper \
  && /usr/sbin/iptables-wrapper install
RUN --mount=from=build-ipset,source=/,target=/run/stage/ipset,ro \
  --network=none \
  cp -a /run/stage/ipset/usr/local/sbin/ipset /usr/sbin/ipset \
  && mkdir -p /usr/share/doc/ipset \
  && cp -a /run/stage/ipset/src/ipset/ChangeLog /usr/share/doc/ipset/ChangeLog

COPY --from=build-gobgp /go/src/gobgp/gobgp /usr/local/bin/
COPY --from=build-kube-router /go/src/kube-router/kube-router /usr/local/bin/

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/kube-router"]
