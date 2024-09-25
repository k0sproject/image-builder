ARG KUBE_ROUTER_VERSION=v2.2.1
FROM docker.io/cloudnativelabs/kube-router:${KUBE_ROUTER_VERSION} AS binaries

FROM docker.io/library/golang:1.22.7-alpine3.19 AS build-gobgp
ARG KUBE_ROUTER_VERSION
RUN apk add --no-cache git make curl

# https://github.com/cloudnativelabs/kube-router/blob/v2.2.1/Makefile#L31
RUN git clone -b v3.29.0 https://github.com/osrg/gobgp.git /gobgp

RUN cd /gobgp && \
    go get -u google.golang.org/grpc@v1.58.3 && \
    go mod tidy && \
    CGO_ENABLED=0 go build -ldflags "-s -w" -o /usr/local/bin/gobgp /gobgp/cmd/gobgp

FROM docker.io/library/golang:1.22.7-alpine3.19 AS build-kube-router
ARG KUBE_ROUTER_VERSION
RUN apk add --no-cache git make curl

RUN git -c advice.detachedHead=false clone --branch ${KUBE_ROUTER_VERSION} https://github.com/cloudnativelabs/kube-router.git /kube-router

RUN cd /kube-router && \
    export GIT_COMMIT=$(git describe --tags --dirty) && \
    export BUILD_DATE=$(git log -1 --date=format:%Y-%m-%dT%H:%M:%S%z --format=%cd) && \
    CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/cloudnativelabs/kube-router/v2/pkg/version.Version=$GIT_COMMIT -X github.com/cloudnativelabs/kube-router/v2/pkg/version.BuildDate=$BUILD_DATE" \
    -o /usr/local/bin/kube-router /kube-router/cmd/kube-router

FROM docker.io/library/golang:1.22.7-alpine3.19 AS build-iptables-wrapper
ARG KUBE_ROUTER_VERSION
RUN apk add --no-cache git make curl

# https://github.com/cloudnativelabs/kube-router/blob/master/Dockerfile#L17
# This is the latest commit on the master branch.
ENV IPTABLES_WRAPPERS_VERSION=f6ef44b2c449cca8f005b32dea9a4b497202dbef
RUN git clone https://github.com/kubernetes-sigs/iptables-wrappers.git /iptables-wrappers
RUN cd /iptables-wrappers \
    && git checkout "${IPTABLES_WRAPPERS_VERSION}" \
    && make build \
    && test -x bin/iptables-wrapper \
    && test -x iptables-wrapper-installer.sh

FROM docker.io/library/alpine:3.18.9
ARG KUBE_ROUTER_VERSION
RUN apk add --no-cache \
    'iptables=~1.8.9' \
    'ip6tables=~1.8.9' \
    ipset \
    iproute2 \
    ipvsadm \
    conntrack-tools \
    curl \
    bash && \
    mkdir -p /var/lib/gobgp

COPY --from=build-kube-router /usr/local/bin/kube-router /usr/local/bin/
COPY --from=build-gobgp /usr/local/bin/gobgp /usr/local/bin/
COPY --from=build-iptables-wrapper /iptables-wrappers/bin/iptables-wrapper /
COPY --from=build-iptables-wrapper /iptables-wrappers/iptables-wrapper-installer.sh /
COPY --from=binaries /etc/motd-kube-router.sh /etc/motd-kube-router.sh

RUN echo "hosts: files dns" > /etc/nsswitch.conf

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/kube-router"]
