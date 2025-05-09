ARG BUILDER_IMAGE=docker.io/library/golang:1.24.2-alpine3.21

ARG \
  VERSION=1.12.1 \
  GIT_COMMIT=707c7c10acd52cb94e959e76ae233d9b76af0854 \
  HASH=665b2096611b960572b40ad7e943e9c6cca58da5f3885e148868578b15fbf8ef

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS sources
ARG VERSION HASH
RUN --mount=type=tmpfs,target=/tmp \
  set -euo pipefail \
  && wget -O /tmp/src.tar.gz https://github.com/coredns/coredns/archive/refs/tags/v${VERSION}.tar.gz \
  && { echo "$HASH" /tmp/src.tar.gz | sha256sum -c -; } \
  && tar xf /tmp/src.tar.gz -C /go/src \
  && mv /go/src/coredns-"$VERSION" /go/src/coredns

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build
WORKDIR /go/src/coredns
ARG VERSION GIT_COMMIT TARGETARCH
ENV GOTOOLCHAIN=local CGO_ENABLED=0 GOARCH="$TARGETARCH"
RUN --mount=from=sources,source=/go/src/coredns,target=/go/src/coredns \
  --mount=type=cache,id=coredns-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=cache,id=coredns-go-mod-$VERSION,target=/go/pkg/mod \
  --mount=type=tmpfs,target=/tmp \
  go build -o /coredns -ldflags="-s -w -X github.com/coredns/coredns/coremain.GitCommit=$GIT_COMMIT"
RUN apk add --no-cache ca-certificates-bundle

FROM scratch
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/coredns/coredns"
ARG VERSION

COPY --from=build /coredns /coredns
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 53 53/udp
ENTRYPOINT ["/coredns"]
