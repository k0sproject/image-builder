ARG KUBE_ROUTER_VERSION=v2.2.1
FROM docker.io/cloudnativelabs/kube-router:${KUBE_ROUTER_VERSION} AS binaries

FROM docker.io/library/golang:1.23.4-alpine3.20 AS build-base
RUN apk add --no-interactive --no-cache git make curl

FROM build-base AS build-gobgp

# https://github.com/cloudnativelabs/kube-router/blob/v2.2.1/Makefile#L31
RUN git -c advice.detachedHead=false clone -b v3.29.0 https://github.com/osrg/gobgp.git /gobgp

RUN cd /gobgp && \
    go get -u google.golang.org/grpc@v1.58.3 && \
    go mod tidy && \
    CGO_ENABLED=0 go build -ldflags "-s -w" -o /usr/local/bin/gobgp /gobgp/cmd/gobgp

FROM build-base AS build-kube-router
ARG KUBE_ROUTER_VERSION

RUN git -c advice.detachedHead=false clone --branch ${KUBE_ROUTER_VERSION} https://github.com/cloudnativelabs/kube-router.git /kube-router

RUN cd /kube-router && \
    export GIT_COMMIT=$(git describe --tags --dirty) && \
    export BUILD_DATE=$(git log -1 --date=format:%Y-%m-%dT%H:%M:%S%z --format=%cd) && \
    CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/cloudnativelabs/kube-router/v2/pkg/version.Version=$GIT_COMMIT -X github.com/cloudnativelabs/kube-router/v2/pkg/version.BuildDate=$BUILD_DATE" \
    -o /usr/local/bin/kube-router /kube-router/cmd/kube-router

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
  --mount=type=cache,id=iptables-wrapper-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  du -sh /root/.cache/go-build \
  && GOARCH="$TARGETARCH" make -C /go/iptables-wrapper build \
  && mv /go/iptables-wrapper/bin/iptables-wrapper /go/iptables-wrapper

FROM docker.io/library/alpine:3.18.9
RUN --mount=from=build-iptables-wrapper,source=/go/iptables-wrapper,target=/run/stage/iptables-wrapper,ro \
  apk add --no-cache \
    'iptables=~1.8.9' \
    'ip6tables=~1.8.9' \
    'libcrypto3=~3.1.7-r1' \
    'libssl3=~3.1.7-r1' \
    ipset \
    iproute2 \
    ipvsadm \
    conntrack-tools \
    curl \
    bash \
  && mkdir -p /var/lib/gobgp \
  && (cd /run/stage/iptables-wrapper && ./iptables-wrapper-installer.sh --no-sanity-check --no-cleanup)

COPY --from=build-kube-router /usr/local/bin/kube-router /usr/local/bin/
COPY --from=build-gobgp /usr/local/bin/gobgp /usr/local/bin/
COPY --from=binaries /etc/motd-kube-router.sh /etc/motd-kube-router.sh

RUN echo "hosts: files dns" > /etc/nsswitch.conf

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/kube-router"]
