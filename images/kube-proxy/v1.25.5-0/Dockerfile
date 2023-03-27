FROM docker.io/library/golang:1.19 as binary

RUN mkdir -p /go/kubernetes && git clone -b v1.25.5 https://github.com/kubernetes/kubernetes.git /go/kubernetes

RUN mkdir -p /go/bin/ && cd /go/kubernetes && \
  sed -i -e 's/v0.3.1-0.20221206200815-1e63c2f08a10/v0.7.0/' go.mod && \
  go get -u golang.org/x/net@v0.7.0 && \
  go mod vendor && \
  CGO_ENABLED=0 go build -o /go/bin/kube-proxy -ldflags "-X k8s.io/component-base/version.gitVersion=v1.25.5" ./cmd/kube-proxy && /go/bin/kube-proxy --version

FROM debian:bullseye-slim as build

COPY files/package-utils.sh /
COPY files/stage-binaries-from-package.sh /
COPY files/stage-binary-and-deps.sh /

RUN mkdir -p /opt/stage && \
    /stage-binaries-from-package.sh /opt/stage conntrack \
    ebtables    \
    ipset       \
    iptables    \
    kmod && \
    /stage-binary-and-deps.sh /opt/stage /bin/dash \
    /bin/cat \
    /bin/chmod \
    /bin/grep \
    /bin/ln  \
    /bin/rm \
    /bin/sleep \
    /usr/bin/wc && \
    ln -sf /bin/dash /opt/stage/bin/sh

RUN ls -la /opt/stage/usr/sbin

FROM gcr.io/distroless/base

COPY files/iptables-wrapper-installer.sh /
COPY files/clean-distroless.sh /
COPY --from=build /opt/stage /
COPY --from=binary /go/bin/kube-proxy /usr/local/bin/kube-proxy

RUN echo "" >  /usr/sbin/iptables && /iptables-wrapper-installer.sh --no-sanity-check && /clean-distroless.sh

ENTRYPOINT ["/usr/local/bin/kube-proxy"]

