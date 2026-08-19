# SPDX-FileCopyrightText: 2026 k0s authors
# SPDX-License-Identifier: Apache-2.0

ARG \
  VERSION=0.36.0 \
  HASH=28e7766158efd496cef5d75155b38a8883a59aff8282bef65a5a7e5e6e6f8481 \
  BUILDIMAGE=docker.io/library/golang:1.26.6-alpine3.23 \
  DISTROLESS_BASEIMAGE=gcr.io/distroless/static-debian13:nonroot@sha256:963fa6c544fe5ce420f1f54fb88b6fb01479f054c8056d0f74cc2c6000df5240 \
  WINDOWS_VERSION=

FROM --platform=$BUILDPLATFORM $BUILDIMAGE AS sources
ENV CGO_ENABLED=0 GOTELEMETRY=off
WORKDIR /go/src/kubernetes-sigs/apiserver-network-proxy

ARG VERSION HASH
RUN --mount=type=cache,id=konnectivity-go-modcache,target=/go/pkg/mod \
  --mount=type=tmpfs,target=/tmp \
  set -e \
  && wget -qO /tmp/src.tar.gz https://github.com/kubernetes-sigs/apiserver-network-proxy/archive/refs/tags/v$VERSION.tar.gz \
  && { echo $HASH /tmp/src.tar.gz | sha256sum -c -; } || { sha256sum /tmp/src.tar.gz; exit 1; } \
  && tar xf /tmp/src.tar.gz --strip-components=1
ARG XNET_VERSION=v0.56.0 XTEXT_VERSION=v0.39.0 GRPC_VERSION=v1.82.1
RUN --mount=type=cache,id=konnectivity-go-modcache,target=/go/pkg/mod \
  set -eu \
  && for spec in \
    "golang.org/x/net $XNET_VERSION" \
    "golang.org/x/text $XTEXT_VERSION" \
    "google.golang.org/grpc $GRPC_VERSION" \
  ; do \
    pkg=$(echo "$spec" | cut -d' ' -f1); \
    want=$(echo "$spec" | cut -d' ' -f2); \
    have=$(go list -m -f '{{.Version}}' "$pkg"); \
    newer=$(printf '%s\n%s\n' "${have#v}" "${want#v}" | sort -t. -k1,1n -k2,2n -k3,3n | tail -n1); \
    if [ "$newer" = "${have#v}" ] && [ "$have" != "$want" ]; then \
      echo "ERROR: $pkg is already $have (>= $want) -- remove this pin from the Dockerfile" >&2; \
      exit 1; \
    fi; \
  done \
  && go get \
  golang.org/x/net@$XNET_VERSION \
  golang.org/x/text@$XTEXT_VERSION \
  google.golang.org/grpc@$GRPC_VERSION \
  && go mod tidy
RUN go mod download


FROM sources AS binary
ARG TARGETOS TARGETARCH SOURCE_DATE_EPOCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH
RUN --mount=type=cache,id=konnectivity-agent-go-cache-$TARGETOS-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  go build \
  -mod=readonly -trimpath -buildvcs=false \
  -o /out/proxy-agent \
   -ldflags "-s -w" \
  ./cmd/agent


FROM $DISTROLESS_BASEIMAGE AS final-linux
COPY --from=binary /out/proxy-agent /
ENTRYPOINT ["/proxy-agent"]


FROM mcr.microsoft.com/windows/nanoserver:ltsc$WINDOWS_VERSION AS final-windows
COPY --from=binary /out/proxy-agent /proxy-agent.exe
ENTRYPOINT ["proxy-agent.exe"]


FROM final-$TARGETOS
ARG VERSION
LABEL org.opencontainers.image.title="konnectivity-agent for k0s" \
  org.opencontainers.image.vendor=k0sproject \
  org.opencontainers.image.source=https://github.com/k0sproject/image-builder \
  org.opencontainers.image.licenses=Apache-2.0 \
  org.opencontainers.image.url=https://github.com/kubernetes-sigs/apiserver-network-proxy \
  org.opencontainers.image.version="v$VERSION"
