# https://github.com/projectcalico/calico/blob/v3.26.4/cni-plugin/Dockerfile.amd64

ARG \
  VERSION=3.26.4 \
  HASH=481e52de684c049f3f7f7bac78f0f6f4ae424d643451adc9e3d3fa9d03fb6d57

FROM docker.io/calico/cni:v$VERSION AS upstream

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.22.5-alpine3.20 AS builder

WORKDIR /go/src/calico
ARG VERSION HASH
RUN --mount=type=cache,id=calico-gomodcache,target=/go/pkg/mod \
  --mount=type=tmpfs,target=/tmp \
  wget -O /tmp/src.tar.gz https://github.com/projectcalico/calico/archive/refs/tags/v$VERSION.tar.gz \
  && { printf '%s */tmp/src.tar.gz' "$HASH" | sha256sum -c -; } \
  && tar xf /tmp/src.tar.gz --strip-components=1 \
  && go mod download -x

ARG TARGETARCH
RUN --mount=type=cache,id=calico-gomodcache,target=/go/pkg/mod,ro \
  --mount=type=cache,id=calico-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=tmpfs,target=/tmp \
  --network=none \
  GOARCH=$TARGETARCH CGO_ENABLED=0 go build \
    -v -buildvcs=false \
    -ldflags "-s -w -X main.VERSION=v$VERSION" \
    -o /out/calico \
    ./cni-plugin/cmd/calico \
  && cd /out \
  && ln -s calico calico-ipam \
  && ln -s calico install

FROM --platform=$BUILDPLATFORM docker.io/library/alpine:3.20.1 AS binaries
COPY --from=upstream /licenses/ /out/licenses/
COPY --from=upstream /opt/cni/ /out/opt/cni/
ARG TARGETARCH
RUN set -e \
  && case $TARGETARCH in \
    amd64) alpineArch=x86_64 ;; \
    arm64) alpineArch=aarch64;; \
      arm) alpineArch=armv7;; \
        *) alpineArch=$TARGETARCH;; \
  esac \
  && apk add --no-cache binutils-$alpineArch \
  && rm /out/opt/cni/bin/install /out/opt/cni/bin/calico /out/opt/cni/bin/calico-ipam \
  && /usr/${alpineArch}-alpine-linux-musl*/bin/strip /out/opt/cni/bin/*

FROM scratch
COPY --from=binaries /out/ /
COPY --from=builder /out/ /opt/cni/bin/

ENV PATH=/opt/cni/bin
WORKDIR /opt/cni/bin
CMD ["/opt/cni/bin/install"]
