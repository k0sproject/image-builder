ARG \
  VERSION=0.7.1 \
  HASH=b185f8bbb76a3e95c5cd70958e34da5c95d637aab3d29ec0d04e943576d18247

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.22.5-alpine3.20 AS build

WORKDIR /go/src/kubernetes-sigs/metrics-server
ARG VERSION HASH
RUN --mount=source=patches,target=/run/patches,ro \
  --mount=type=cache,id=metrics-server-go-modcache,target=/go/pkg/mod \
  --mount=type=tmpfs,target=/tmp \
  set -e \
  && apk add --no-cache patch \
  && wget -O /tmp/src.tar.gz https://github.com/kubernetes-sigs/metrics-server/archive/refs/tags/v$VERSION.tar.gz \
  && { printf '%s */tmp/src.tar.gz' "$HASH" | sha256sum -c -; } \
  && tar xf /tmp/src.tar.gz --strip-components=1 \
  && for p in /run/patches/*; do patch -p1 <"$p"; done \
  && go mod download -x

ARG TARGETARCH
RUN --mount=type=cache,id=metrics-server-go-modcache,target=/go/pkg/mod \
  --mount=type=cache,id=metrics-server-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=tmpfs,target=/tmp \
  --network=none \
  GOARCH=$TARGETARCH CGO_ENABLED=0 go build \
    -v -mod=readonly -trimpath -buildvcs=false \
    -ldflags "-s -w -X k8s.io/client-go/pkg/version.gitVersion=v$VERSION+k0s.0" \
    ./cmd/metrics-server

FROM gcr.io/distroless/static-debian12:nonroot@sha256:8dd8d3ca2cf283383304fd45a5c9c74d5f2cd9da8d3b077d720e264880077c65
COPY --from=build /go/src/kubernetes-sigs/metrics-server/metrics-server /
ENTRYPOINT ["/metrics-server"]
