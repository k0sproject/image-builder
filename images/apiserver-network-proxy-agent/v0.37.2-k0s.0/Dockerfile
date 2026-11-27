# SPDX-FileCopyrightText: 2026 k0s authors
# SPDX-License-Identifier: Apache-2.0

ARG \
  VERSION=0.37.2 \
  HASH=1c78dbf8990e4c49e95e31ba3a382add296a3b5d7b1ed83436b3aa8dbb7db1a0 \
  BUILDIMAGE=docker.io/library/golang:1.27.4-alpine3.24 \
  DISTROLESS_BASEIMAGE=gcr.io/distroless/static-debian13:nonroot@sha256:8ce6dd87e9823c5b48dcfb2c8604714ccb351ce59607327bcc4957448da279b5 \
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
