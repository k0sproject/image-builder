ARG \
  VERSION=0.7.2 \
  HASH=8febe4f15ee58fb6e3613a5b49f5cab2c166827a20e3b3a991184afd73df68fb \
  DEFAULT_BASEIMAGE=gcr.io/distroless/static-debian12:nonroot@sha256:a9329520abc449e3b14d5bc3a6ffae065bdde0f02667fa10880c49b35c109fd1 \
  RISCV_BASEIMAGE=ghcr.io/go-riscv/distroless/static-unstable:latest@sha256:0bd27d7ab1f1863abecdebe207870375364fddc1d0ae87179ef176403d04e27b

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.25.7-alpine3.23 AS build

WORKDIR /go/src/kubernetes-sigs/metrics-server
ARG VERSION HASH
RUN --mount=type=cache,id=metrics-server-go-modcache,target=/go/pkg/mod \
  --mount=type=tmpfs,target=/tmp \
  set -e \
  && apk add --no-cache patch \
  && wget -O /tmp/src.tar.gz https://github.com/kubernetes-sigs/metrics-server/archive/refs/tags/v$VERSION.tar.gz \
  && { printf '%s */tmp/src.tar.gz' "$HASH" | sha256sum -c -; } \
  && tar xf /tmp/src.tar.gz --strip-components=1

ARG TARGETARCH
RUN --mount=type=cache,id=metrics-server-go-modcache,target=/go/pkg/mod \
  --mount=type=cache,id=metrics-server-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=tmpfs,target=/tmp \
  GOARCH=$TARGETARCH CGO_ENABLED=0 go build \
  -v -mod=readonly -trimpath -buildvcs=false \
  -ldflags "-s -w -X k8s.io/client-go/pkg/version.gitVersion=v$VERSION+k0s.0" \
  ./cmd/metrics-server

FROM $DEFAULT_BASEIMAGE AS final-amd64
FROM $DEFAULT_BASEIMAGE AS final-arm64
FROM $DEFAULT_BASEIMAGE AS final-arm
FROM $RISCV_BASEIMAGE   AS final-riscv64

FROM final-$TARGETARCH
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/kubernetes-sigs/metrics-server"
COPY --from=build /go/src/kubernetes-sigs/metrics-server/metrics-server /
ENTRYPOINT ["/metrics-server"]
