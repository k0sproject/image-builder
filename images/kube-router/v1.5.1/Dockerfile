FROM docker.io/cloudnativelabs/kube-router:v1.5.1 as binaries

FROM alpine:3.17

RUN apk add --no-cache \
      iptables \
      ip6tables \
      ipset \
      iproute2 \
      ipvsadm \
      conntrack-tools \
      curl \
      bash && \
    mkdir -p /var/lib/gobgp

COPY --from=binaries /usr/local/bin/kube-router /usr/local/bin/gobgp /usr/local/bin/
COPY --from=binaries /etc/motd-kube-router.sh /etc/motd-kube-router.sh

RUN wget -O /iptables-wrapper-installer.sh https://raw.githubusercontent.com/cloudnativelabs/kube-router/v1.5.1/build/image-assets/iptables-wrapper-installer.sh && \
    chmod +x /iptables-wrapper-installer.sh && \
    /iptables-wrapper-installer.sh --no-sanity-check

RUN echo "hosts: files dns" > /etc/nsswitch.conf

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/kube-router"]
