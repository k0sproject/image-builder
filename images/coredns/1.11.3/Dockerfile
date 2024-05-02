ARG BUILDER_IMAGE=docker.io/library/golang:1.22.2-alpine3.19

ARG \
  VERSION=1.11.3 \
  GIT_COMMIT=a7ed346585e30b99317d36e4d007b7b19a228ea5 \
  HASH=b64e0c5970000595a0682e9a87ebbad5ef0db790c1b6efbba6e341211bdf3299

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE as sources
ARG VERSION HASH
RUN --mount=type=tmpfs,target=/tmp \
  set -euo pipefail \
  && wget -O /tmp/src.tar.gz https://github.com/coredns/coredns/archive/refs/tags/v${VERSION}.tar.gz \
  && { echo "$HASH" /tmp/src.tar.gz | sha256sum -c -; } \
  && tar xf /tmp/src.tar.gz -C /go/src \
  && mv /go/src/coredns-"$VERSION" /go/src/coredns

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE as build
WORKDIR /go/src/coredns
ARG VERSION GIT_COMMIT TARGETARCH
ENV GOTOOLCHAIN=local CGO_ENABLED=0 GOARCH="$TARGETARCH"
RUN --mount=from=sources,source=/go/src/coredns,target=/go/src/coredns \
  --mount=type=cache,id=coredns-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=cache,id=coredns-go-mod-$VERSION,target=/go/pkg/mod \
  --mount=type=tmpfs,target=/tmp \
  go build -o /coredns -ldflags="-s -w -X github.com/coredns/coredns/coremain.GitCommit=$GIT_COMMIT"

FROM scratch
ARG VERSION

COPY --from=build /coredns /coredns
COPY --from=gcr.io/distroless/static-debian12@sha256:41972110a1c1a5c0b6adb283e8aa092c43c31f7c5d79b8656fbffff2c3e61f05 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 53 53/udp
ENTRYPOINT ["/coredns"]
