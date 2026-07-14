ARG \
  VERSION=v0.9.0+k0s.0 \
  REVISION=2a7c4b2c7d46552ff47f4aeaa3a735c582587ecd \
  BUILDER_IMAGE=docker.io/library/golang:1.26.5-alpine3.24@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2 \
  DISTROLESS_BASEIMAGE=gcr.io/distroless/static-debian13:nonroot@sha256:d5f030ca7c5793784e9ea4178a116da360250411d13921a5af27c6cb5a5949bf


FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base
ENV GOTOOLCHAIN=local GOTELEMETRY=off
WORKDIR /go/src/metrics-server


FROM build-base AS sources
ARG REVISION
RUN apk add --no-cache git
RUN git -C .. -c advice.detachedHead=false clone --revision $REVISION https://github.com/kubernetes-sigs/metrics-server.git
RUN go mod download


FROM build-base AS build
ARG TARGETARCH VERSION
RUN --mount=from=sources,source=/go/src/metrics-server,target=/go/src/metrics-server,ro \
  --mount=from=sources,source=/go/pkg/mod,target=/go/pkg/mod,ro \
  --mount=type=cache,id=metrics-server-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=tmpfs,target=/tmp \
  --network=none \
  CGO_ENABLED=0 \
  GOARCH=$TARGETARCH \
  go build -mod=readonly -trimpath -buildvcs=false \
    -ldflags="-s -w -X k8s.io/client-go/pkg/version.gitVersion=$VERSION" \
    -o /metrics-server \
    ./cmd/metrics-server


FROM $DISTROLESS_BASEIMAGE
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/kubernetes-sigs/metrics-server"
COPY --from=build /metrics-server /
ENTRYPOINT ["/metrics-server"]
