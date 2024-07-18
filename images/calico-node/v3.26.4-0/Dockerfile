# https://github.com/projectcalico/calico/blob/v3.26.4/node/Dockerfile.amd64

ARG \
  VERSION=3.26.4 \
  HASH=481e52de684c049f3f7f7bac78f0f6f4ae424d643451adc9e3d3fa9d03fb6d57 \
  IPSET_VERSION=7.17 \
  IPSET_HASH=be49c9ff489dd6610cad6541e743c3384eac96e9f24707da7b3929d8f2ac64d8

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.22.5-alpine3.20 AS builder

ARG VERSION HASH
RUN wget https://github.com/projectcalico/calico/archive/refs/tags/v$VERSION.tar.gz \
  && { echo "$HASH *v$VERSION.tar.gz" | sha256sum -c -; } \
  && mkdir /go/calico && tar xf "v$VERSION.tar.gz" --strip-components=1 -C /go/calico \
  && rm -- "v$VERSION.tar.gz"

WORKDIR /go/calico
ARG TARGETARCH
RUN GOARCH=$TARGETARCH CGO_ENABLED=0 go build -buildvcs=false -v -o calico-node -ldflags "-s -w -X main.VERSION=v$VERSION" ./node/cmd/calico-node

FROM docker.io/library/alpine:3.19.2 AS ipset
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

FROM docker.io/calico/node:v$VERSION AS intermediate
COPY --from=builder /go/calico/calico-node /usr/bin/calico-node
COPY --from=ipset /usr/local/sbin/ipset /usr/sbin/ipset
COPY --from=ipset /src/ipset/ChangeLog /usr/share/doc/ipset/ChangeLog

FROM scratch
COPY --from=intermediate / /
ENV SVDIR=/etc/service/enabled
CMD ["start_runit"]
