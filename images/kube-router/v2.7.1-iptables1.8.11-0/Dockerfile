ARG \
  KUBE_ROUTER_VERSION=v2.7.1 \
  # https://github.com/cloudnativelabs/kube-router/blob/v2.7.1/Makefile#L34
  GOBGP_VERSION=v4.2.0 \
  ALPINE_IMAGE=docker.io/library/alpine:3.23.3 \
  BUILDER_IMAGE=docker.io/library/golang:1.25.7-alpine3.23 \
  IPTABLES_VERSION=1.8.11 \
  IPTABLES_HASH=d87303d55ef8c92bcad4dd3f978b26d272013642b029425775f5bad1009fe7b2 \
  IPTABLES_WRAPPER_VERSION=06cad2ec6cb5ed0945b383fb185424c0a67f55eb \
  IPTABLES_WRAPPER_HASH=fde9ccd22b337fd297180cd21938c0a82030187fc29aabb6800472295d62752a \
  IPSET_VERSION=7.24 \
  IPSET_HASH=fbe3424dff222c1cb5e5c34d38b64524b2217ce80226c14fdcbb13b29ea36112

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base
RUN apk add --no-interactive --no-cache git make
ENV GOTOOLCHAIN=local


FROM build-base AS build-gobgp

ARG GOBGP_VERSION
WORKDIR /go/src/gobgp
RUN git -C .. -c advice.detachedHead=false clone -b $GOBGP_VERSION https://github.com/osrg/gobgp.git
RUN go mod download

ARG TARGETARCH
RUN --mount=type=cache,id=kube-router-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  GOARCH="$TARGETARCH" CGO_ENABLED=0 go build -mod=readonly -trimpath -buildvcs=false -ldflags "-s -w" ./cmd/gobgp


FROM build-base AS build-kube-router

ARG KUBE_ROUTER_VERSION
WORKDIR /go/src/kube-router
RUN git -C .. -c advice.detachedHead=false clone --branch $KUBE_ROUTER_VERSION https://github.com/cloudnativelabs/kube-router.git
RUN go mod download

ARG TARGETARCH
RUN --mount=type=cache,id=kube-router-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  export GIT_COMMIT=$(git describe --tags --dirty) \
  && export BUILD_DATE=$(git log -1 --date=format:%Y-%m-%dT%H:%M:%S%z --format=%cd) \
  && GOARCH="$TARGETARCH" CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/cloudnativelabs/kube-router/v2/pkg/version.Version=$GIT_COMMIT -X github.com/cloudnativelabs/kube-router/v2/pkg/version.BuildDate=$BUILD_DATE" \
    -trimpath -buildvcs=false ./cmd/kube-router


FROM build-base AS build-iptables-wrapper

ARG IPTABLES_WRAPPER_VERSION IPTABLES_WRAPPER_HASH
WORKDIR /go/src/iptables-wrapper
RUN --mount=type=tmpfs,target=/tmp \
  set -euo pipefail \
  && wget -qO /tmp/sources.tar.gz "https://github.com/kubernetes-sigs/iptables-wrappers/archive/$IPTABLES_WRAPPER_VERSION.tar.gz" \
  && { echo $IPTABLES_WRAPPER_HASH /tmp/sources.tar.gz | sha256sum -c -; } \
  && mkdir -p /go/iptables-wrapper \
  && tar xf /tmp/sources.tar.gz --strip-components=1

ARG TARGETARCH
RUN --mount=type=tmpfs,target=/go/src/iptables-wrapper/bin \
  --mount=type=cache,id=kube-router-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  du -sh /root/.cache/go-build \
  && GOARCH="$TARGETARCH" make build \
  && mv bin/iptables-wrapper .


FROM $ALPINE_IMAGE AS build-iptables

RUN apk add --no-interactive --no-cache \
    build-base curl pkgconf \
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
RUN ipset -h


FROM $ALPINE_IMAGE
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/cloudnativelabs/kube-router"
RUN apk add --no-interactive --no-cache \
    iproute2 \
    ipvsadm \
    conntrack-tools \
    curl \
    bash \
  && mkdir -p /var/lib/gobgp
RUN --mount=from=build-iptables,source=/usr/local,target=/run/stage/iptables,ro \
  --mount=from=build-iptables-wrapper,source=/go/src/iptables-wrapper,target=/run/stage/iptables-wrapper,ro \
  --network=none \
  cp -a /run/stage/iptables/sbin/xtables-* /run/stage/iptables/sbin/iptables* /run/stage/iptables/sbin/ip6tables* /sbin/ \
  && (cd /run/stage/iptables-wrapper && ./iptables-wrapper-installer.sh --no-sanity-check --no-cleanup)

RUN --mount=from=build-ipset,source=/,target=/run/stage/ipset,ro \
  --network=none \
  cp -a /run/stage/ipset/usr/local/sbin/ipset /usr/sbin/ipset \
  && mkdir -p /usr/share/doc/ipset \
  && cp -a /run/stage/ipset/src/ipset/ChangeLog /usr/share/doc/ipset/ChangeLog

COPY --from=build-gobgp /go/src/gobgp/gobgp /usr/local/bin/
RUN --mount=from=build-kube-router,source=/go/src/kube-router,target=/run/stage/kube-router,ro \
  --network=none \
  cp -a /run/stage/kube-router/kube-router /usr/local/bin/ \
  && cp -a /run/stage/kube-router/build/image-assets/motd-kube-router.sh /etc/ \
  && echo "hosts: files dns" > /etc/nsswitch.conf

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/kube-router"]
