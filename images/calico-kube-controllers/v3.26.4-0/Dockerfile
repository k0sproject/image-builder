# https://github.com/projectcalico/calico/blob/v3.26.4/kube-controllers/Dockerfile.amd64

ARG \
  VERSION=3.26.4 \
  HASH=481e52de684c049f3f7f7bac78f0f6f4ae424d643451adc9e3d3fa9d03fb6d57

FROM --platform=$BUILDPLATFORM docker.io/library/golang:1.22.5-alpine3.20 AS builder

WORKDIR /go/src/calico
ARG VERSION HASH
RUN --mount=type=cache,id=calico-gomodcache,target=/go/pkg/mod \
  --mount=type=tmpfs,target=/tmp \
  wget -O /tmp/src.tar.gz https://github.com/projectcalico/calico/archive/refs/tags/v$VERSION.tar.gz \
  && { printf '%s */tmp/src.tar.gz' "$HASH" | sha256sum -c -; } \
  && tar xf /tmp/src.tar.gz --strip-components=1 \
  && go mod download -x

RUN mkdir -p /out/licenses && cp -a kube-controllers/LICENSE /out/licenses/
RUN mkdir -p /out/status && touch /out/status/status.json && chown 999 /out/status/status.json

ARG TARGETARCH
RUN --mount=type=cache,id=calico-gomodcache,target=/go/pkg/mod,ro \
  --mount=type=cache,id=calico-gocache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=tmpfs,target=/tmp \
  --network=none \
  GOARCH=$TARGETARCH CGO_ENABLED=0 go build \
    -v -buildvcs=false \
    -ldflags "-s -w -X main.VERSION=v$VERSION" \
    -o /out/usr/bin/kube-controllers \
    ./kube-controllers/cmd/kube-controllers \
  && GOARCH=$TARGETARCH CGO_ENABLED=0 go build \
    -v -buildvcs=false \
    -ldflags "-s -w -X main.VERSION=v$VERSION" \
    -o /out/usr/bin/check-status \
    ./kube-controllers/cmd/check-status

FROM scratch
COPY --from=builder /out/ /
USER 999
ENTRYPOINT ["/usr/bin/kube-controllers"]
