# https://github.com/projectcalico/calico/blob/v3.28.5/node/Dockerfile.amd64

ARG \
  VERSION=3.28.5 \
  HASH=c3ca0752eac5cab50dc9ae5bc2e3c2f8eea2d9030c1f9846d2e8563c8a8aec2c \
  IPSET_VERSION=7.17 \
  IPSET_HASH=be49c9ff489dd6610cad6541e743c3384eac96e9f24707da7b3929d8f2ac64d8 \
  # https://github.com/projectcalico/calico/blob/v3.28.5/metadata.mk#L29
  BIRD_VERSION=v0.3.3-208-g1e2ff99d \
  BUILDER_IMAGE=docker.io/library/golang:1.23.11-alpine3.22 \
  IPTABLES_WRAPPERS_VERSION=f6ef44b2c449cca8f005b32dea9a4b497202dbef \
  IPTABLES_VERSION=1.8.9


FROM $BUILDER_IMAGE AS builder

ARG VERSION HASH
RUN wget https://github.com/projectcalico/calico/archive/refs/tags/v$VERSION.tar.gz \
  && { echo "$HASH *v$VERSION.tar.gz" | sha256sum -c -; } \
  && mkdir /go/calico && tar xf "v$VERSION.tar.gz" --strip-components=1 -C /go/calico \
  && rm -- "v$VERSION.tar.gz"

WORKDIR /go/calico
RUN CGO_ENABLED=0 go build -buildvcs=false -v -o calico-node -ldflags "-s -w -X main.VERSION=v$VERSION" ./node/cmd/calico-node && \
  CGO_ENABLED=0 go build -buildvcs=false -v -o mountns -ldflags "-s -w -X main.VERSION=v$VERSION" ./node/cmd/mountns && chmod u+s mountns

# For currently unknown reason, compiling in alpine 3.20 creates binary
# which always segfaults. So we need to compile in alpine 3.19 still.
FROM docker.io/library/alpine:3.19 AS ipset
RUN apk add --no-cache \
  build-base pkgconf curl \
  libmnl-dev libmnl-static

ARG IPSET_VERSION IPSET_HASH
RUN curl -sSLo ipset.tar.bz2 "http://ipset.netfilter.org/ipset-$IPSET_VERSION.tar.bz2" \
  && { echo "$IPSET_HASH *ipset.tar.bz2" | sha256sum -c -; } \
  && mkdir -p /src/ipset && tar xf "ipset.tar.bz2" --strip-components=1 -C /src/ipset \
  && rm -- "ipset.tar.bz2"

WORKDIR /src/ipset
RUN printf '#!/usr/bin/env sh\nexec cc -static "$@"\n' >/src/cc-static && chmod +x /src/cc-static
RUN CC=/src/cc-static CFLAGS=-static LDFLAGS=-static ./configure --enable-static --disable-shared --with-kmod=no
RUN make && strip src/ipset
RUN make install
# Just a sanity check that it's not segfaulting
RUN ipset -h

# TODO We should build bird bins from source
FROM docker.io/calico/bird:$BIRD_VERSION-$TARGETARCH$TARGETVARIANT AS bird

# Build iptables
FROM docker.io/library/alpine:3.20 AS iptables
ARG IPTABLES_VERSION

RUN apk add build-base curl pkgconf \
	linux-headers \
	libmnl-dev libmnl-static \
	libnftnl-dev

RUN curl --proto '=https' --tlsv1.2 -L https://www.netfilter.org/projects/iptables/files/iptables-$IPTABLES_VERSION.tar.xz \
	| tar -C / -Jx

ARG TARGET_OS
RUN cd /iptables-$IPTABLES_VERSION && \
  CFLAGS="-Os" ./configure --sysconfdir=/etc --enable-static --disable-shared --without-kernel --disable-devel

RUN make -j$(nproc) -C /iptables-$IPTABLES_VERSION LDFLAGS=-all-static
RUN make -j$(nproc) -C /iptables-$IPTABLES_VERSION install

RUN strip /usr/local/sbin/xtables-legacy-multi
RUN strip /usr/local/sbin/xtables-nft-multi
RUN scanelf -Rn /usr/local && file /usr/local/sbin/*

FROM $BUILDER_IMAGE AS iptables-wrapper
ARG IPTABLES_WRAPPERS_VERSION
RUN apk add --no-cache git make
RUN git clone https://github.com/kubernetes-sigs/iptables-wrappers.git /iptables-wrappers
RUN cd /iptables-wrappers \
    && git checkout "${IPTABLES_WRAPPERS_VERSION}" \
    && make build \
    && test -x bin/iptables-wrapper \
    && test -x iptables-wrapper-installer.sh

# Build the image based on alpine
FROM docker.io/library/alpine:3.20
ARG TARGETARCH

RUN apk add --no-cache bash iputils iproute2 conntrack-tools runit ca-certificates

# Copy the calico-node binary from the builder image
COPY --from=builder /go/calico/calico-node /usr/bin/calico-node
COPY --from=builder /go/calico/mountns /usr/bin/mountns

COPY --from=ipset /usr/local/sbin/ipset /usr/sbin/ipset
COPY --from=ipset /src/ipset/ChangeLog /usr/share/doc/ipset/ChangeLog

# Copy the config etc filesystem from builder
COPY --from=builder /go/calico/node/filesystem/ /
COPY --from=builder /go/calico/confd/etc/ /etc/

# Change permissions to make confd templates and output available in /etc/calico
# to all container users.
RUN chgrp -R 0 /etc/calico && \
    chmod -R g=u /etc/calico

COPY --from=bird /bird* /usr/bin/

# Copy iptables and wrappers
COPY --from=iptables /usr/local/sbin/xtables-* /sbin/
COPY --from=iptables /usr/local/sbin/iptables* /sbin/
COPY --from=iptables /usr/local/sbin/ip6tables* /sbin/
COPY --from=iptables-wrapper /iptables-wrappers/bin/iptables-wrapper /
COPY --from=iptables-wrapper /iptables-wrappers/iptables-wrapper-installer.sh /

RUN /iptables-wrapper-installer.sh --no-sanity-check

RUN echo "hosts: files dns" > /etc/nsswitch.conf

ENV SVDIR=/etc/service/enabled
CMD ["start_runit"]
