ARG \
  VERSION=0.8.1 \
  HASH=7e18fb3f2001efea6a6958dc11a5597cace11302b9a840e18309c8e8a461bd71 \
  DEFAULT_BASEIMAGE=gcr.io/distroless/static-debian12:nonroot@sha256:cba10d7abd3e203428e86f5b2d7fd5eb7d8987c387864ae4996cf97191b33764 \
  RISCV_BASEIMAGE=ghcr.io/go-riscv/distroless/static-unstable:nonroot-riscv64@sha256:e469c1aed8cc36a249b45648377c636404962f945ea24920ad747fd9e9b66046

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.25.7-alpine3.23 AS build

WORKDIR /go/src/kubernetes-sigs/metrics-server
ARG VERSION HASH
RUN --mount=type=tmpfs,target=/tmp \
  set -e \
  && wget -qO /tmp/src.tar.gz https://github.com/kubernetes-sigs/metrics-server/archive/refs/tags/v$VERSION.tar.gz \
  && { printf '%s */tmp/src.tar.gz' "$HASH" | sha256sum -c -; } \
  && tar xf /tmp/src.tar.gz --strip-components=1 \
  && go mod download -x

ARG TARGETARCH
RUN --mount=type=cache,id=metrics-server-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=tmpfs,target=/tmp \
  --network=none \
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
