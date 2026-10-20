# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 k0s authors

ARG BUILDER_IMAGE=docker.io/library/golang:1.26.6-alpine3.24@sha256:af8d6740070b8906d12eae1c3e3ea0957fb63f492051ea05e354c38ef9fe88df

ARG \
  VERSION=1.14.7 \
  GIT_COMMIT=427fc80ed9ca47f354585eb30a3f1332950856c4 \
  HASH=c3ecdf3ebaba0c453e3dc62643548dbece09999d589513f25ca00ca4eca89423

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base
ENV GOTOOLCHAIN=local GOTELEMETRY=off
WORKDIR /go/src/coredns


FROM build-base AS sources
ARG VERSION HASH
# Upstream pins older version of x/mod which reports some HIGH CVEs
# (CVE-2026-56864/CVE-2026-56865) thus bump it here
ARG XMOD_VERSION=v0.40.0
RUN --mount=type=tmpfs,target=/tmp \
  set -eu \
  && wget -qO /tmp/sources.tar.gz https://github.com/coredns/coredns/archive/refs/tags/v$VERSION.tar.gz \
  && { echo $HASH /tmp/sources.tar.gz | sha256sum -c -; } || { sha256sum /tmp/sources.tar.gz; exit 1; } \
  && tar xf /tmp/sources.tar.gz --strip-components=1
RUN go get golang.org/x/mod@$XMOD_VERSION \
  && go mod download


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
