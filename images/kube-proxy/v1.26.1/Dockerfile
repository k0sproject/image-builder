FROM registry.k8s.io/kube-proxy:v1.26.1 as binary

FROM debian:bullseye-slim as build

COPY package-utils.sh /
COPY stage-binaries-from-package.sh /
COPY stage-binary-and-deps.sh /

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

COPY iptables-wrapper-installer.sh /
COPY clean-distroless.sh /
COPY --from=build /opt/stage /
COPY --from=binary /usr/local/bin/kube-proxy /usr/local/bin/kube-proxy

RUN echo "" >  /usr/sbin/iptables && /iptables-wrapper-installer.sh && /clean-distroless.sh

ENTRYPOINT ["/usr/local/bin/kube-proxy"]

