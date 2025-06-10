# https://github.com/projectcalico/calico/blob/v3.28.1/kube-controllers/Dockerfile.amd64

ARG \
  VERSION=3.28.2 \
  HASH=f02a0e99e060850bd9050d4c94d37df899911a5e357e1d26e1b5b79a923bb389

FROM docker.io/library/golang:1.22.7-alpine3.20 as builder

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
COPY --from=builder /out/ /
USER 999
ENTRYPOINT ["/usr/bin/kube-controllers"]
