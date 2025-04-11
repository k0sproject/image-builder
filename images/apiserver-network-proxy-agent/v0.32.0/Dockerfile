ARG \
  VERSION=0.32.0 \
  HASH=03f34ace31742fbc483ac579aacc7cc86eb2c77c3a05a692ceba1c5dbd8c1ab0 \
  DEFAULT_BASEIMAGE=gcr.io/distroless/static-debian12:nonroot@sha256:c0f429e16b13e583da7e5a6ec20dd656d325d88e6819cafe0adb0828976529dc \
  RISCV_BASEIMAGE=ghcr.io/go-riscv/distroless/static-unstable:latest@sha256:af5b10695a340493ec1807c4ad97489dc1018044785fc09729dcf971a592ccf7

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.24.2-alpine3.21 AS build
ENV CGO_ENABLED=0 GOTELEMETRY=off
WORKDIR /go/src/kubernetes-sigs/apiserver-network-proxy

ARG VERSION HASH
RUN --mount=type=cache,id=konnectivity-go-modcache,target=/go/pkg/mod \
  --mount=type=tmpfs,target=/tmp \
  set -e \
  && wget -qO /tmp/src.tar.gz https://github.com/kubernetes-sigs/apiserver-network-proxy/archive/refs/tags/v$VERSION.tar.gz \
  && { printf '%s */tmp/src.tar.gz' "$HASH" | sha256sum -c -; } \
  && tar xf /tmp/src.tar.gz --strip-components=1 \
  && go mod download -x

ARG TARGETARCH
ENV GOARCH=$TARGETARCH
RUN --mount=type=cache,id=konnectivity-go-modcache,target=/go/pkg/mod,ro \
  --mount=type=cache,id=konnectivity-agent-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=tmpfs,target=/tmp \
  --network=none \
  go build \
  -v -mod=readonly -trimpath -buildvcs=false \
  -ldflags "-s -w" \
  ./cmd/agent

FROM $DEFAULT_BASEIMAGE AS final-amd64
FROM $DEFAULT_BASEIMAGE AS final-arm64
FROM $DEFAULT_BASEIMAGE AS final-arm
FROM $RISCV_BASEIMAGE   AS final-riscv64

FROM final-$TARGETARCH
COPY --from=build /go/src/kubernetes-sigs/apiserver-network-proxy/agent /proxy-agent
ENTRYPOINT ["/proxy-agent"]
