ARG KUBE_ROUTER_VERSION=v2.0.1
FROM docker.io/cloudnativelabs/kube-router:${KUBE_ROUTER_VERSION} as binaries

FROM docker.io/library/golang:1.21.6-alpine3.19 as build
ARG KUBE_ROUTER_VERSION
RUN apk add --no-cache git

RUN git clone -b v3.22.0 https://github.com/osrg/gobgp.git /gobgp

RUN cd /gobgp && \
    go get -u google.golang.org/grpc@v1.58.3 && \
    go mod tidy && \
    CGO_ENABLED=0 go build -ldflags "-s -w" -o /usr/local/bin/gobgp /gobgp/cmd/gobgp

RUN git -c advice.detachedHead=false clone -b ${KUBE_ROUTER_VERSION} https://github.com/cloudnativelabs/kube-router.git /kube-router

RUN cd /kube-router && \
    export GIT_COMMIT=$(git describe --tags --dirty) && \
    export BUILD_DATE=$(git log -1 --date=format:%Y-%m-%dT%H:%M:%S%z --format=%cd) && \
    go get -u google.golang.org/grpc@v1.58.3 && \
    go mod tidy && \
    CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/cloudnativelabs/kube-router/v2/pkg/version.Version=$GIT_COMMIT -X github.com/cloudnativelabs/kube-router/v2/pkg/version.BuildDate=$BUILD_DATE" \
     -o /usr/local/bin/kube-router /kube-router/cmd/kube-router


FROM docker.io/library/alpine:3.19.0
ARG KUBE_ROUTER_VERSION
RUN apk add --no-cache \
      'iptables=~1.8.10' \
      'ip6tables=~1.8.10' \
      ipset \
      iproute2 \
      ipvsadm \
      conntrack-tools \
      curl \
      bash && \
    mkdir -p /var/lib/gobgp

COPY --from=build /usr/local/bin/kube-router /usr/local/bin/
COPY --from=build /usr/local/bin/gobgp /usr/local/bin/
COPY --from=binaries /etc/motd-kube-router.sh /etc/motd-kube-router.sh

RUN wget -O /iptables-wrapper-installer.sh https://raw.githubusercontent.com/cloudnativelabs/kube-router/$KUBE_ROUTER_VERSION/build/image-assets/iptables-wrapper-installer.sh && \
    chmod +x /iptables-wrapper-installer.sh && \
    /iptables-wrapper-installer.sh --no-sanity-check

RUN echo "hosts: files dns" > /etc/nsswitch.conf

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/kube-router"]
