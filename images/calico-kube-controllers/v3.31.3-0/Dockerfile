# https://github.com/projectcalico/calico/blob/v3.29.1/kube-controllers/Dockerfile

ARG \
  VERSION=3.31.3 \
  HASH=d130227adf56f5ae30ea22d8ef05974fbf4428360d4120f99f6bd3b1fa99d0d9

FROM docker.io/library/golang:1.25.5-alpine3.23 AS builder

ARG VERSION HASH
RUN --mount=from=patches,target=/run/patches,ro \
  set -e \
  && apk add --no-cache patch \
  && wget https://github.com/projectcalico/calico/archive/refs/tags/v$VERSION.tar.gz \
  && { echo "$HASH *v$VERSION.tar.gz" | sha256sum -c -; } \
  && mkdir /go/calico && tar xf "v$VERSION.tar.gz" --strip-components=1 -C /go/calico \
  && rm -- "v$VERSION.tar.gz" \
  && cd /go/calico \
  && for p in /run/patches/*; do \
    echo Applying "$p" >&2; \
    patch -p1 <"$p"; \
  done

WORKDIR /go/calico
RUN mkdir -p /out/usr/bin \
  && CGO_ENABLED=0 go build \
    -v -buildvcs=false \
    -ldflags "-s -w -X main.VERSION=v$VERSION+k0s.0" \
    -o /out/usr/bin/kube-controllers \
    ./kube-controllers/cmd/kube-controllers \
  && CGO_ENABLED=0 go build \
    -v -buildvcs=false \
    -ldflags "-s -w -X main.VERSION=v$VERSION+k0s.0" \
    -o /out/usr/bin/check-status \
    ./kube-controllers/cmd/check-status

RUN mkdir /out/licenses && cp -a LICENSE.md /out/licenses/
RUN mkdir /out/status && touch /out/status/status.json && chown 999 /out/status/status.json

FROM scratch
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/projectcalico/calico"
COPY --from=builder /out/ /
USER 999
ENTRYPOINT ["/usr/bin/kube-controllers"]
