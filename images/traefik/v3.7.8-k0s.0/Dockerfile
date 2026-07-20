ARG \
  VERSION=v3.7.8 \
  REVISION=4a87f05acfa2beb0211cee6e2ad4d002289752b5 \
  BUILDER_IMAGE=docker.io/library/golang:1.26.5-alpine3.24@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2 \
  DISTROLESS_BASEIMAGE=gcr.io/distroless/static-debian13:nonroot@sha256:f7f8f729987ad0fdf6b05eeeae94b26e6a0f613bdf46feea7fc40f7bd72953e6 \
  HPC_BASEIMAGE=mcr.microsoft.com/oss/v2/kubernetes/windows-host-process-containers-base-image:2.0.0@sha256:85d91507422525f89358038d0534e45375b19f360ffadaeb0119f7f86a294773

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base
ENV GOTOOLCHAIN=local GOTELEMETRY=off
WORKDIR /go/src/traefik


FROM build-base AS sources
ARG REVISION
RUN apk add --no-cache git
RUN git -C .. -c advice.detachedHead=false clone --revision $REVISION --depth 1 https://github.com/traefik/traefik.git
RUN go mod download


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
