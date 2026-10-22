ARG \
  VERSION=0.7.2 \
  HASH=8febe4f15ee58fb6e3613a5b49f5cab2c166827a20e3b3a991184afd73df68fb \
  DEFAULT_BASEIMAGE=gcr.io/distroless/static-debian13:nonroot@sha256:d62067879de890a1def9da0e7766b7d20810a5e5555cef8506b752437d7a3e88

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.26.10-alpine3.23 AS build

WORKDIR /go/src/kubernetes-sigs/metrics-server
ARG VERSION HASH
RUN --mount=type=cache,id=metrics-server-go-modcache,target=/go/pkg/mod \
  --mount=type=tmpfs,target=/tmp \
  set -e \
  && apk add --no-cache patch \
  && wget -O /tmp/src.tar.gz https://github.com/kubernetes-sigs/metrics-server/archive/refs/tags/v$VERSION.tar.gz \
  && { printf '%s */tmp/src.tar.gz' "$HASH" | sha256sum -c -; } \
  && tar xf /tmp/src.tar.gz --strip-components=1 \
  && sed -Ei 's#^(package main)$#//go:debug tls3des=0\n\n\1#g' cmd/metrics-server/metrics-server.go

ARG TARGETARCH
RUN --mount=type=cache,id=metrics-server-go-modcache,target=/go/pkg/mod \
  --mount=type=cache,id=metrics-server-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=tmpfs,target=/tmp \
  GOARCH=$TARGETARCH CGO_ENABLED=0 go build \
  -v -mod=readonly -trimpath -buildvcs=false \
  -ldflags "-s -w -X k8s.io/client-go/pkg/version.gitVersion=v$VERSION+k0s.2" \
  ./cmd/metrics-server

FROM $DEFAULT_BASEIMAGE
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/kubernetes-sigs/metrics-server"
COPY --from=build /go/src/kubernetes-sigs/metrics-server/metrics-server /
ENTRYPOINT ["/metrics-server"]
