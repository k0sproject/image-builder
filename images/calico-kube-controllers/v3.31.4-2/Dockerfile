# https://github.com/projectcalico/calico/blob/v3.31.4/kube-controllers/Dockerfile

ARG \
  VERSION=3.31.4 \
  HASH=5a718ead156533a1f9260f6c234d68953707aebefa7af781e8c62690b8e69acf \
  GIT_REVISION=6d8c39b0ef01cdf92960e08f704c7198ffe42eac

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.25.8-alpine3.23 AS builder

ARG VERSION HASH
WORKDIR /go/src/calico
RUN --mount=type=tmpfs,target=/tmp \
  set -euo pipefail \
  && wget -qO /tmp/sources.tar.gz https://github.com/projectcalico/calico/archive/refs/tags/v$VERSION.tar.gz \
  && { echo $HASH /tmp/sources.tar.gz | sha256sum -c -; } \
  && tar xf /tmp/sources.tar.gz --strip-components=1 \
  && find . -type f -exec stat -c '%Y' {} \; | sort -n -u | tail -1 >/tmp/source-date-epoch \
  && read -r SOURCE_DATE_EPOCH </tmp/source-date-epoch \
  && touch -d "@$SOURCE_DATE_EPOCH" /tmp/source-date-epoch \
  && mv -T /tmp/source-date-epoch .source-date-epoch
RUN go mod download

ARG TARGETARCH GIT_REVISION
RUN --mount=type=cache,id=calico-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  read -r SOURCE_DATE_EPOCH <.source-date-epoch \
  && export SOURCE_DATE_EPOCH \
  && export GOARCH=$TARGETARCH \
  && export CGO_ENABLED=0 \
  && LDFLAGS='-s -w' \
  && LDFLAGS="$LDFLAGS -X main.VERSION=v$VERSION" \
  && LDFLAGS="$LDFLAGS -X github.com/projectcalico/calico/pkg/buildinfo.Version=v$VERSION" \
  && `# https://github.com/projectcalico/calico/blob/v3.31.4/lib.Makefile#L224` \
  && LDFLAGS="$LDFLAGS -X github.com/projectcalico/calico/pkg/buildinfo.BuildDate=$(date -u -d @$SOURCE_DATE_EPOCH +'%FT%T%z')" \
  && LDFLAGS="$LDFLAGS -X github.com/projectcalico/calico/pkg/buildinfo.GitRevision=$GIT_REVISION" \
  && go build \
    -mod=readonly -trimpath -buildvcs=false \
    -ldflags "$LDFLAGS" \
    -o /out/usr/bin/ \
    ./kube-controllers/cmd/kube-controllers \
    ./kube-controllers/cmd/check-status \
    ./kube-controllers/cmd/wrapper

RUN mkdir /out/licenses && cp -a LICENSE.md /out/licenses/
RUN mkdir /out/status && touch /out/status/status.json && chown 999 /out/status/status.json

FROM scratch
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/projectcalico/calico"
COPY --from=builder /out/ /
USER 999
ENTRYPOINT ["/usr/bin/wrapper", "/usr/bin/kube-controllers"]
