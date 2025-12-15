ARG BUILDER_IMAGE=docker.io/library/golang:1.25.5-alpine3.22

ARG \
  VERSION=1.13.2 \
  GIT_COMMIT=0233f3e7c600b730426628f2cf9c829d404a181f \
  HASH=8a9f8729476bdf265d5990dea86c314db778aec2f79d3d47e43607903f7d0b37

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
RUN apk add --no-cache ca-certificates-bundle libcap-setcap
RUN setcap cap_net_bind_service=+ep /coredns

FROM scratch
LABEL org.opencontainers.image.licenses="Apache-2.0" \
  org.opencontainers.image.source="https://github.com/coredns/coredns"
ARG VERSION

COPY --from=build /coredns /coredns
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
USER 65532:65532

EXPOSE 53 53/udp
ENTRYPOINT ["/coredns"]
