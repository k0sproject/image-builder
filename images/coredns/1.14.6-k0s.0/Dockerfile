# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 k0s authors

ARG BUILDER_IMAGE=docker.io/library/golang:1.26.4-alpine3.24@sha256:3ad57304ad93bbec8548a0437ad9e06a455660655d9af011d58b993f6f615648

ARG \
  VERSION=1.14.6 \
  GIT_COMMIT=424d125775cd70fa90dfc80bf0e52cc9a9aeb574 \
  HASH=44af24bd9ab0b9f85a9feaa3132de72e9e4a0629452d41b3e2f49aa2028233af

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base
ENV GOTOOLCHAIN=local GOTELEMETRY=off
WORKDIR /go/src/coredns


FROM build-base AS sources
ARG VERSION HASH
RUN --mount=type=tmpfs,target=/tmp \
  set -eu \
  && wget -qO /tmp/sources.tar.gz https://github.com/coredns/coredns/archive/refs/tags/v$VERSION.tar.gz \
  && { echo $HASH /tmp/sources.tar.gz | sha256sum -c -; } || { sha256sum /tmp/sources.tar.gz; exit 1; } \
  && tar xf /tmp/sources.tar.gz --strip-components=1
RUN go mod download


FROM build-base AS build
RUN apk add --no-cache libcap-setcap
ARG TARGETARCH GIT_COMMIT
RUN --mount=from=sources,source=/go/src/coredns,target=/go/src/coredns,ro \
  --mount=from=sources,source=/go/pkg/mod,target=/go/pkg/mod,ro \
  --mount=type=cache,id=coredns-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=tmpfs,target=/tmp \
  --network=none \
  CGO_ENABLED=0 \
  GOARCH=$TARGETARCH \
  go build -mod=readonly -trimpath -buildvcs=false \
    -ldflags="-s -w -X github.com/coredns/coredns/coremain.GitCommit=$GIT_COMMIT" \
    -o /coredns \
  && setcap cap_net_bind_service=+ep /coredns


FROM build-base AS baselayout
ARG SOURCE_DATE_EPOCH
RUN apk add --no-cache ca-certificates-bundle


FROM scratch
LABEL org.opencontainers.image.licenses="Apache-2.0" \
  org.opencontainers.image.source="https://github.com/coredns/coredns"
ARG VERSION

COPY --from=baselayout /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /coredns /coredns
USER 65532:65532

EXPOSE 53 53/udp
ENTRYPOINT ["/coredns"]
