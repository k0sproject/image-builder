ARG KUBE_ROUTER_VERSION=v1.6.0
FROM docker.io/cloudnativelabs/kube-router:${KUBE_ROUTER_VERSION} as binaries

FROM docker.io/library/golang:1.20.8-alpine3.18 as build
ARG KUBE_ROUTER_VERSION
RUN apk add --no-cache git

RUN git clone -b v3.21.0 https://github.com/osrg/gobgp.git /gobgp

RUN cd /gobgp && go get -u golang.org/x/net@v0.7.0 && \
    go mod tidy && \
    CGO_ENABLED=0 go build -ldflags "-s -w" -o /usr/local/bin/gobgp /gobgp/cmd/gobgp

RUN git clone -b ${KUBE_ROUTER_VERSION} https://github.com/cloudnativelabs/kube-router.git /kube-router

RUN cd /kube-router && \
    export GIT_COMMIT=$(git describe --tags --dirty) && \
    export BUILD_DATE="2023-07-17T00:00:00+0000" && \
    go get -u golang.org/x/net@v0.7.0 && \
    go get -u github.com/docker/distribution@v2.8.2 && \
    go get -u github.com/docker/docker@v20.10.25 && \
    go mod tidy && \
    CGO_ENABLED=0 go build -ldflags "-s -w -X github.com/cloudnativelabs/kube-router/pkg/version.Version=$GIT_COMMIT -X github.com/cloudnativelabs/kube-router/pkg/version.BuildDate=$BUILD_DATE" \
     -o /usr/local/bin/kube-router /kube-router/cmd/kube-router


FROM alpine:3.18
ARG KUBE_ROUTER_VERSION
RUN apk add --no-cache \
      'iptables=1.8.9-r2' \
      'ip6tables=1.8.9-r2' \
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
