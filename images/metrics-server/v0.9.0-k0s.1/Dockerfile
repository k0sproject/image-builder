ARG \
  VERSION=v0.9.0+k0s.0 \
  REVISION=2a7c4b2c7d46552ff47f4aeaa3a735c582587ecd \
  BUILDER_IMAGE=docker.io/library/golang:1.26.6-alpine3.24@sha256:af8d6740070b8906d12eae1c3e3ea0957fb63f492051ea05e354c38ef9fe88df \
  DISTROLESS_BASEIMAGE=gcr.io/distroless/static-debian13:nonroot@sha256:d5f030ca7c5793784e9ea4178a116da360250411d13921a5af27c6cb5a5949bf

# Dependency overrides for advisories still open upstream:
# GHSA-gcjh-h69q-9w9g (cel-go), CVE-2026-56852 (x/text) and
# GHSA-hrxh-6v49-42gf (grpc). Raising them requires `go mod tidy`,
# which also nudges a handful of unrelated transitive dependencies,
# so drop each override again once upstream picks the version up.
ARG \
  CELGO_VERSION=v0.29.0 \
  XTEXT_VERSION=v0.39.0 \
  GRPC_VERSION=v1.82.1


FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base
ENV GOTOOLCHAIN=local GOTELEMETRY=off
WORKDIR /go/src/metrics-server


FROM build-base AS sources
ARG REVISION
RUN apk add --no-cache git
RUN git -C .. -c advice.detachedHead=false clone --revision $REVISION https://github.com/kubernetes-sigs/metrics-server.git

ARG CELGO_VERSION XTEXT_VERSION GRPC_VERSION
RUN set -eu \
  && go mod edit \
    -require=github.com/google/cel-go@$CELGO_VERSION \
    -require=golang.org/x/text@$XTEXT_VERSION \
    -require=google.golang.org/grpc@$GRPC_VERSION \
  && go mod tidy \
  && for want in \
    "github.com/google/cel-go $CELGO_VERSION" \
    "golang.org/x/text $XTEXT_VERSION" \
    "google.golang.org/grpc $GRPC_VERSION"; \
  do \
    got=$(go list -m "${want% *}"); \
    [ "$got" = "$want" ] || { echo "dependency override lost: got '$got', want '$want'"; exit 1; }; \
  done \
  && go mod download


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
