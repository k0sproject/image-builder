FROM docker.io/library/golang:1.21.10-alpine3.19 as binary

RUN apk add --no-cache cmd:make cmd:bash cmd:rsync

# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.28.md#source-code
ARG \
  VERSION=1.28.10 \
  HASH=7930797f68229f1ca6e0992abd7a2d5408e81683065a8b75120281b3252b6f735ae802ed763dad8d04e25896c266c0fe4c55318868c14cb5422133c83b445ef1

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


# https://github.com/kubernetes/release/blob/18a45b24a34ea6b14665ff10a95ca8f389b4e2b1/images/build/distroless-iptables/distroless-bookworm/Dockerfile#L18-L70
FROM docker.io/library/debian:bookworm-slim@sha256:804194b909ef23fb995d9412c9378fb3505fe2427b70f3cc425339e48a828fca as build

COPY files/stage-binary-and-deps.sh /
COPY files/stage-binaries-from-package.sh /
COPY files/package-utils.sh /


RUN apt-get -y update && \
    apt-get -y dist-upgrade && \
    apt-get -y install bash curl && \
    mkdir -p /opt/stage && \
    /stage-binaries-from-package.sh /opt/stage conntrack \
    ebtables    \
    ipset       \
    iptables    \
    `#nftables` \
    kmod        && \
    `# below binaries and dash are used by iptables-wrapper-installer.sh` \
    /stage-binary-and-deps.sh /opt/stage /bin/dash \
    /bin/cat \
    /bin/chmod \
    /bin/grep \
    /bin/ln  \
    /bin/rm \
    /bin/sleep \
    /usr/bin/wc && \
    ln -sf /bin/dash /opt/stage/bin/sh

# We need to use distroless:base here as tzdata, glibc and some other base packages
# are required
FROM gcr.io/distroless/base-debian12@sha256:786007f631d22e8a1a5084c5b177352d9dcac24b1e8c815187750f70b24a9fc6 as intermediate

COPY files/clean-distroless.sh /clean-distroless.sh
COPY files/iptables-wrapper-installer.sh /iptables-wrapper-installer.sh
COPY --from=build /opt/stage /
COPY --from=binary /go/kubernetes/_output/local/bin/linux/*/kube-proxy /usr/local/bin/kube-proxy
# iptables-wrapper-installer needs to know that iptables exists before doing all its magic
RUN echo "" >  /usr/sbin/iptables && \
    /iptables-wrapper-installer.sh && \
    /clean-distroless.sh

FROM scratch
COPY --from=intermediate / /

ENTRYPOINT ["/usr/local/bin/kube-proxy"]
