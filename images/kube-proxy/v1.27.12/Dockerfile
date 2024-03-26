FROM docker.io/library/golang:1.21.8-alpine3.18 as binary

RUN apk add --no-cache cmd:make cmd:bash cmd:rsync

# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.27.md#source-code
ARG \
  VERSION=1.27.12 \
  HASH=f177e1a45a9d273955d9dffeb801f2e964bb1f88bd1e494bf0cf5c9bbf5112480338ec27d8b5eab407cd87ac461f6df499b1a1ba5f94fae3a4121318cd99b4dc

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

FROM docker.io/library/debian:bullseye-slim as build

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

FROM gcr.io/distroless/base@sha256:280852156756ea3f39f9e774a30346f2e756244e1f432aea3061c4ac85d90a66

COPY files/iptables-wrapper-installer.sh /
COPY files/clean-distroless.sh /
COPY --from=build /opt/stage /
COPY --from=binary /go/kubernetes/_output/local/bin/linux/*/kube-proxy /usr/local/bin/kube-proxy

RUN echo "" >  /usr/sbin/iptables && /iptables-wrapper-installer.sh --no-sanity-check && /clean-distroless.sh

ENTRYPOINT ["/usr/local/bin/kube-proxy"]
