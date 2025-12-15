ARG \
  VERSION=0.33.0 \
  HASH=8a878be9465b961638ec6f4ca8d13117518970e4beef966627b4714727fd2afe \
  DEFAULT_BASEIMAGE=gcr.io/distroless/static-debian12:nonroot@sha256:627d6c5a23ad24e6bdff827f16c7b60e0289029b0c79e9f7ccd54ae3279fb45f \
  RISCV_BASEIMAGE=ghcr.io/go-riscv/distroless/static-unstable:latest@sha256:5e72edcb29594d42b660606e03207722f5dcb605dd74b6da92533758656d7610

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.24.5-alpine3.22 AS build
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
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/kubernetes-sigs/apiserver-network-proxy"
COPY --from=build /go/src/kubernetes-sigs/apiserver-network-proxy/agent /proxy-agent
ENTRYPOINT ["/proxy-agent"]
