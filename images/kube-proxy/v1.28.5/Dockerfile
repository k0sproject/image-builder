FROM docker.io/library/golang:1.20.12-alpine3.18 as binary

RUN apk add --no-cache cmd:make cmd:bash cmd:rsync

# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.28.md#source-code
ARG \
  VERSION=1.28.5 \
  HASH=18f493ac18499c4e0e50b72bc3f01670e849d02f8b4bc70b9deefbbabb6119314105196d51d4fdcd9de2c66054ffacbcceb41ad19581e3d2a2d893ef2d97201d

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


# https://github.com/kubernetes/release/blob/2fc3173c599fcd6b1835df46ce56398046616e8c/images/build/distroless-iptables/distroless/Dockerfile#L18-L69
FROM docker.io/library/debian:bookworm-slim as build

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
FROM gcr.io/distroless/base-debian12 as intermediate

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
