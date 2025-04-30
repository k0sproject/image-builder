ARG \
  VERSION=0.7.2 \
  HASH=8febe4f15ee58fb6e3613a5b49f5cab2c166827a20e3b3a991184afd73df68fb \
  DEFAULT_BASEIMAGE=gcr.io/distroless/static-debian12:nonroot@sha256:c0f429e16b13e583da7e5a6ec20dd656d325d88e6819cafe0adb0828976529dc \
  RISCV_BASEIMAGE=ghcr.io/go-riscv/distroless/static-unstable:latest@sha256:af5b10695a340493ec1807c4ad97489dc1018044785fc09729dcf971a592ccf7

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.24.2-alpine3.21 AS build

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
COPY --from=build /go/src/kubernetes-sigs/metrics-server/metrics-server /
ENTRYPOINT ["/metrics-server"]
