# https://github.com/projectcalico/calico/blob/v3.28.1/node/Dockerfile.amd64

ARG \
  VERSION=3.28.1 \
  HASH=c56f1530e7ded9d5b4afb9d83a7a24da6d2959ef7ad38521813f1c2bf138182d \
  IPSET_VERSION=7.17 \
  IPSET_HASH=be49c9ff489dd6610cad6541e743c3384eac96e9f24707da7b3929d8f2ac64d8 \
  # https://github.com/projectcalico/calico/blob/v3.28.1/metadata.mk#L29
  BIRD_VERSION=v0.3.3-211-g9111ec3c \
  BUILDER_IMAGE=docker.io/library/golang:1.22.5-alpine3.20

FROM $BUILDER_IMAGE AS builder

ARG VERSION HASH
RUN wget https://github.com/projectcalico/calico/archive/refs/tags/v$VERSION.tar.gz \
  && { echo "$HASH *v$VERSION.tar.gz" | sha256sum -c -; } \
  && mkdir /go/calico && tar xf "v$VERSION.tar.gz" --strip-components=1 -C /go/calico \
  && rm -- "v$VERSION.tar.gz"

WORKDIR /go/calico
RUN CGO_ENABLED=0 go build -buildvcs=false -v -o calico-node -ldflags "-s -w -X main.VERSION=v$VERSION" ./node/cmd/calico-node && \
  CGO_ENABLED=0 go build -buildvcs=false -v -o mountns -ldflags "-s -w -X main.VERSION=v$VERSION" ./node/cmd/mountns && chmod u+s mountns


FROM docker.io/library/alpine:3.20 AS ipset
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

# TODO We should build bird bins from source
FROM docker.io/calico/bird:$BIRD_VERSION-$TARGETARCH$TARGETVARIANT AS bird

# Build the image based on alpine
FROM docker.io/library/alpine:3.20
ARG TARGETARCH

RUN apk add --no-cache bash ip6tables iputils iproute2 conntrack-tools runit ca-certificates

# Copy the calico-node binary from the builder image
COPY --from=builder /go/calico/calico-node /usr/bin/calico-node
COPY --from=builder /go/calico/mountns /usr/bin/mountns

COPY --from=ipset /usr/local/sbin/ipset /usr/sbin/ipset
COPY --from=ipset /src/ipset/ChangeLog /usr/share/doc/ipset/ChangeLog

# Copy the config etc filesystem from builder
COPY --from=builder /go/calico/node/filesystem/ /
COPY --from=builder /go/calico/confd/etc/ /etc/

COPY --from=bird /bird* /usr/bin/

# Change permissions to make confd templates and output available in /etc/calico
# to all container users.
RUN chgrp -R 0 /etc/calico && \
    chmod -R g=u /etc/calico


ENV SVDIR=/etc/service/enabled
CMD ["start_runit"]
