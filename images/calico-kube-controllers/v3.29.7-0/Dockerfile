# https://github.com/projectcalico/calico/blob/v3.29.1/kube-controllers/Dockerfile

ARG \
  VERSION=3.29.6 \
  HASH=927e35d130d0413399735dc401e8448c783794cb8bb9e169ccdc7b00f516a698

FROM docker.io/library/golang:1.24.7-alpine3.21 AS builder

ARG VERSION HASH
RUN wget https://github.com/projectcalico/calico/archive/refs/tags/v$VERSION.tar.gz \
  && { echo "$HASH *v$VERSION.tar.gz" | sha256sum -c -; } \
  && mkdir /go/calico && tar xf "v$VERSION.tar.gz" --strip-components=1 -C /go/calico \
  && rm -- "v$VERSION.tar.gz"

WORKDIR /go/calico
RUN mkdir -p /out/usr/bin \
  && CGO_ENABLED=0 go build \
    -v -buildvcs=false \
    -ldflags "-s -w -X main.VERSION=v$VERSION" \
    -o /out/usr/bin/kube-controllers \
    ./kube-controllers/cmd/kube-controllers \
  && CGO_ENABLED=0 go build \
    -v -buildvcs=false \
    -ldflags "-s -w -X main.VERSION=v$VERSION" \
    -o /out/usr/bin/check-status \
    ./kube-controllers/cmd/check-status

RUN mkdir /out/licenses && cp -a kube-controllers/LICENSE /out/licenses/
RUN mkdir /out/status && touch /out/status/status.json && chown 999 /out/status/status.json

FROM scratch
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/projectcalico/calico"
COPY --from=builder /out/ /
USER 999
ENTRYPOINT ["/usr/bin/kube-controllers"]
