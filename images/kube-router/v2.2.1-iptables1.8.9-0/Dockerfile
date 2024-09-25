ARG KUBE_ROUTER_VERSION=v2.1.3
FROM docker.io/cloudnativelabs/kube-router:${KUBE_ROUTER_VERSION} as binaries

FROM docker.io/library/golang:1.21.11-alpine3.19 as build
ARG KUBE_ROUTER_VERSION
RUN apk add --no-cache git make curl

# https://github.com/cloudnativelabs/kube-router/blob/master/Makefile#L29
RUN git clone -b v3.23.0 https://github.com/osrg/gobgp.git /gobgp

RUN cd /gobgp && \
    go get -u google.golang.org/grpc@v1.58.3 && \
    go mod tidy && \
    CGO_ENABLED=0 go build -ldflags "-s -w" -o /usr/local/bin/gobgp /gobgp/cmd/gobgp

RUN git -c advice.detachedHead=false clone --branch ${KUBE_ROUTER_VERSION} https://github.com/cloudnativelabs/kube-router.git /kube-router

RUN curl -L https://github.com/cloudnativelabs/kube-router/commit/a1125f6e185ca97456b9d280886595e624d24a7a.patch | git -C /kube-router apply

RUN cd /kube-router && \
    export GIT_COMMIT=$(git describe --tags --dirty) && \
    export BUILD_DATE=$(git log -1 --date=format:%Y-%m-%dT%H:%M:%S%z --format=%cd) && \
    go get -u google.golang.org/grpc@v1.58.3 && \
    go mod tidy && \
    CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/cloudnativelabs/kube-router/v2/pkg/version.Version=$GIT_COMMIT -X github.com/cloudnativelabs/kube-router/v2/pkg/version.BuildDate=$BUILD_DATE" \
    -o /usr/local/bin/kube-router /kube-router/cmd/kube-router

# https://github.com/cloudnativelabs/kube-router/blob/master/Dockerfile#L17
# This is the latest commit on the master branch.
ENV IPTABLES_WRAPPERS_VERSION=f6ef44b2c449cca8f005b32dea9a4b497202dbef
RUN git clone https://github.com/kubernetes-sigs/iptables-wrappers.git /iptables-wrappers
RUN cd /iptables-wrappers \
    && git checkout "${IPTABLES_WRAPPERS_VERSION}" \
    && make build \
    && test -x bin/iptables-wrapper \
    && test -x iptables-wrapper-installer.sh

FROM docker.io/library/alpine:3.18.7
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

COPY --from=build /usr/local/bin/kube-router /usr/local/bin/
COPY --from=build /usr/local/bin/gobgp /usr/local/bin/
COPY --from=build /iptables-wrappers/bin/iptables-wrapper /
COPY --from=build /iptables-wrappers/iptables-wrapper-installer.sh /
COPY --from=binaries /etc/motd-kube-router.sh /etc/motd-kube-router.sh

RUN echo "hosts: files dns" > /etc/nsswitch.conf

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/kube-router"]
