FROM docker.io/library/golang:1.20.3-alpine3.17 as binary

RUN apk add --no-cache cmd:make cmd:bash cmd:rsync

ARG \
  VERSION=1.27.2 \
  HASH=b9be38a5506071a362864661b369c71b0a02e66df0a77a2afc68040fa9634751a189e3c6c94771aee3e17b50a73228ad992a08f31cf4b322ebd7003e7676d381

RUN wget https://dl.k8s.io/v${VERSION}/kubernetes-src.tar.gz && \
  { echo "${HASH} *kubernetes-src.tar.gz" | sha512sum -c -; } && \
  mkdir -p /go/kubernetes && \
  tar xf kubernetes-src.tar.gz -C /go/kubernetes && \
  rm kubernetes-src.tar.gz

RUN make -C /go/kubernetes \
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

FROM gcr.io/distroless/base

COPY files/iptables-wrapper-installer.sh /
COPY files/clean-distroless.sh /
COPY --from=build /opt/stage /
COPY --from=binary /go/kubernetes/_output/local/bin/linux/*/kube-proxy /usr/local/bin/kube-proxy

RUN echo "" >  /usr/sbin/iptables && /iptables-wrapper-installer.sh --no-sanity-check && /clean-distroless.sh

ENTRYPOINT ["/usr/local/bin/kube-proxy"]
