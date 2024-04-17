FROM docker.io/library/golang:1.21.9-alpine3.19 as binary

RUN apk add --no-cache cmd:make cmd:bash cmd:rsync

# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.28.md#source-code
ARG \
  VERSION=1.28.9 \
  HASH=ba7ae8b833ebc21f384dd36e5efe61b12c082342314097542da0326fc19a4d54a3cd84848be60c85bf3675718eb213216d503ca8f088084e2d77b92cc1848c6a

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
FROM docker.io/library/debian:bookworm-slim@sha256:3d5df92588469a4c503adbead0e4129ef3f88e223954011c2169073897547cac as build

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
FROM gcr.io/distroless/base-debian12@sha256:611d30d7f6d9992c37b1e1a212eefdf1f7c671deb56db3707e24eb01da8c4c2a as intermediate

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
