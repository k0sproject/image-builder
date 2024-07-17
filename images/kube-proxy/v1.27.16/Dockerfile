FROM docker.io/library/golang:1.21.11-alpine3.19 as binary

RUN apk add --no-cache cmd:make cmd:bash cmd:rsync

# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.27.md#source-code
ARG \
  VERSION=1.27.15 \
  HASH=6b5b5182e88c613a5e8452aa0d2446a3772e49533b471bfebf85edb5ed1f7f63e87a1e211d969706aedb1a1a0677ffbd8a37cd6df8a8df8fb3d1bc912fb37b64

RUN wget https://dl.k8s.io/v${VERSION}/kubernetes-src.tar.gz && \
  { echo "${HASH} *kubernetes-src.tar.gz" | sha512sum -c -; } && \
  mkdir -p /go/kubernetes && \
  tar xf kubernetes-src.tar.gz -C /go/kubernetes && \
  rm kubernetes-src.tar.gz

RUN --network=none \
  make -C /go/kubernetes \
  WHAT=cmd/kube-proxy \
  FORCE_HOST_GO=y \
  KUBE_STATIC_OVERRIDES=kube-proxy \
  KUBE_VERBOSE=9

FROM docker.io/library/debian:bullseye-slim@sha256:0e75382930ceb533e2f438071307708e79dc86d9b8e433cc6dd1a96872f2651d as build

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

FROM gcr.io/distroless/base@sha256:786007f631d22e8a1a5084c5b177352d9dcac24b1e8c815187750f70b24a9fc6

COPY files/iptables-wrapper-installer.sh /
COPY files/clean-distroless.sh /
COPY --from=build /opt/stage /
COPY --from=binary /go/kubernetes/_output/local/bin/linux/*/kube-proxy /usr/local/bin/kube-proxy

RUN echo "" >  /usr/sbin/iptables && /iptables-wrapper-installer.sh --no-sanity-check && /clean-distroless.sh

ENTRYPOINT ["/usr/local/bin/kube-proxy"]
