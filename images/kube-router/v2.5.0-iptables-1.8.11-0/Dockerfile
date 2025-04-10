ARG KUBE_ROUTER_VERSION=v2.5.0

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.24.2-alpine3.21 AS build-base
RUN apk add --no-interactive --no-cache git make curl
ENV GOTOOLCHAIN=local

FROM build-base AS build-gobgp

# https://github.com/cloudnativelabs/kube-router/blob/v2.5.0/Makefile#L31
RUN --mount=type=cache,id=kube-router-gomodcache,target=/go/pkg/mod \
  git -c advice.detachedHead=false clone -b v3.29.0 https://github.com/osrg/gobgp.git /gobgp \
  && go -C /gobgp mod download

ARG TARGETARCH
RUN --mount=type=cache,id=kube-router-gomodcache,target=/go/pkg/mod \
  --mount=type=cache,id=gobgp-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  GOARCH="$TARGETARCH" CGO_ENABLED=0 go -C /gobgp build -ldflags "-s -w" -trimpath -buildvcs=false -o /usr/local/bin/gobgp /gobgp/cmd/gobgp

FROM build-base AS build-kube-router
ARG KUBE_ROUTER_VERSION

RUN --mount=type=cache,id=kube-router-gomodcache,target=/go/pkg/mod \
  git -c advice.detachedHead=false clone --branch ${KUBE_ROUTER_VERSION} https://github.com/cloudnativelabs/kube-router.git /kube-router \
  && go -C /kube-router mod download

ARG TARGETARCH
RUN --mount=type=cache,id=kube-router-gomodcache,target=/go/pkg/mod \
  --mount=type=cache,id=kube-router-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  cd /kube-router \
  && export GIT_COMMIT=$(git describe --tags --dirty) \
  && export BUILD_DATE=$(git log -1 --date=format:%Y-%m-%dT%H:%M:%S%z --format=%cd) \
  && GOARCH="$TARGETARCH" CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/cloudnativelabs/kube-router/v2/pkg/version.Version=$GIT_COMMIT -X github.com/cloudnativelabs/kube-router/v2/pkg/version.BuildDate=$BUILD_DATE" \
    -trimpath -buildvcs=false -o /usr/local/bin/kube-router /kube-router/cmd/kube-router

FROM build-base AS build-iptables-wrapper

ARG IPTABLES_WRAPPER_VERSION=06cad2ec6cb5ed0945b383fb185424c0a67f55eb
ARG IPTABLES_WRAPPER_HASH=fde9ccd22b337fd297180cd21938c0a82030187fc29aabb6800472295d62752a

RUN set -euo pipefail \
  && wget -qO iptables-wrapper.tar.gz "https://github.com/kubernetes-sigs/iptables-wrappers/archive/$IPTABLES_WRAPPER_VERSION.tar.gz" \
  && { echo "${IPTABLES_WRAPPER_HASH} *iptables-wrapper.tar.gz" | sha256sum -c -; } \
  && mkdir -p /go/iptables-wrapper \
  && tar xf iptables-wrapper.tar.gz --strip-components=1 -C /go/iptables-wrapper \
  && rm iptables-wrapper.tar.gz

ARG TARGETARCH
RUN --mount=type=tmpfs,target=/go/iptables-wrapper/bin \
  --mount=type=cache,id=iptables-wrapper-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  du -sh /root/.cache/go-build \
  && GOARCH="$TARGETARCH" make -C /go/iptables-wrapper build \
  && mv /go/iptables-wrapper/bin/iptables-wrapper /go/iptables-wrapper

FROM docker.io/library/alpine:3.21.3
RUN --mount=from=build-iptables-wrapper,source=/go/iptables-wrapper,target=/run/stage/iptables-wrapper,ro \
  apk add --no-cache \
    'iptables=~1.8.11' \
    'ip6tables=~1.8.11' \
    'libcrypto3=~3.3.3-r0' \
    'libssl3=~3.3.3-r0' \
    ipset \
    iproute2 \
    ipvsadm \
    conntrack-tools \
    curl \
    bash \
  && mkdir -p /var/lib/gobgp \
  && (cd /run/stage/iptables-wrapper && ./iptables-wrapper-installer.sh --no-sanity-check --no-cleanup)

COPY --from=build-kube-router /usr/local/bin/kube-router /usr/local/bin/
COPY --from=build-kube-router /kube-router/build/image-assets/motd-kube-router.sh /etc/
COPY --from=build-gobgp /usr/local/bin/gobgp /usr/local/bin/

RUN echo "hosts: files dns" > /etc/nsswitch.conf

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/kube-router"]
