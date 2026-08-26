ARG \
  VERSION=v3.7.10 \
  REVISION=2a2349356c01b1b1f7ecddb0c17b30c97f5241e7 \
  BUILDER_IMAGE=docker.io/library/golang:1.26.6-alpine3.24@sha256:af8d6740070b8906d12eae1c3e3ea0957fb63f492051ea05e354c38ef9fe88df \
  DISTROLESS_BASEIMAGE=gcr.io/distroless/static-debian13:nonroot@sha256:f7f8f729987ad0fdf6b05eeeae94b26e6a0f613bdf46feea7fc40f7bd72953e6 \
  HPC_BASEIMAGE=mcr.microsoft.com/oss/v2/kubernetes/windows-host-process-containers-base-image:2.0.0@sha256:85d91507422525f89358038d0534e45375b19f360ffadaeb0119f7f86a294773

# Dependency override for CVE-2026-56864/CVE-2026-56865 (x/mod), still
# open in traefik v3.7.10. Raising it requires `go mod tidy`, which
# also nudges a handful of unrelated transitive dependencies, so drop
# the override again once upstream picks the version up.
ARG XMOD_VERSION=v0.40.0

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base
ENV GOTOOLCHAIN=local GOTELEMETRY=off
WORKDIR /go/src/traefik


FROM build-base AS sources
ARG REVISION
RUN apk add --no-cache git
RUN git -C .. -c advice.detachedHead=false clone --revision $REVISION --depth 1 https://github.com/traefik/traefik.git

ARG XMOD_VERSION
RUN set -eu \
  && go mod edit -require=golang.org/x/mod@$XMOD_VERSION \
  && go mod tidy \
  && got=$(go list -m golang.org/x/mod) \
  && [ "$got" = "golang.org/x/mod $XMOD_VERSION" ] || { echo "dependency override lost: got '$got', want 'golang.org/x/mod $XMOD_VERSION'"; exit 1; } \
  && go mod download


FROM sources AS binary
RUN apk add --no-cache make
ARG TARGETOS TARGETARCH SOURCE_DATE_EPOCH VERSION
RUN --mount=type=cache,id=traefik-gocache-$TARGETOS-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  `# https://github.com/traefik/traefik/blob/v3.7.8/Makefile#L59` \
  && make --touch generate-webui \
  && make binary \
    GOOS=$TARGETOS \
    GOARCH=$TARGETARCH \
    FLAGS='-mod=readonly -trimpath -buildvcs=false' \
    `# https://github.com/traefik/traefik/blob/v3.7.8/Makefile#L11` \
    DATE=$(date -u -d @$SOURCE_DATE_EPOCH '+%Y-%m-%d_%I:%M:%S%p') \
  && mkdir /out \
  && mv -v dist/$TARGETOS/$TARGETARCH/traefik /out/


FROM $DISTROLESS_BASEIMAGE AS final-linux
COPY --from=binary /out/traefik /traefik
ENTRYPOINT ["/traefik"]


FROM $HPC_BASEIMAGE AS final-windows
COPY --from=binary /out/traefik /traefik.exe
ENTRYPOINT ["traefik.exe"]


FROM final-$TARGETOS

ARG VERSION
LABEL org.opencontainers.image.title="Traefik for k0s" \
  org.opencontainers.image.vendor=k0sproject \
  org.opencontainers.image.source=https://github.com/k0sproject/image-builder \
  org.opencontainers.image.licenses=Apache-2.0 \
  org.opencontainers.image.url=https://traefik.io \
  org.opencontainers.image.version="$VERSION"
