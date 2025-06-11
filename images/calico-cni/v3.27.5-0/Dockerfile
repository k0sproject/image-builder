# https://github.com/projectcalico/calico/blob/v3.27.3/cni-plugin/Dockerfile.amd64

ARG \
  VERSION=3.27.5 \
  HASH=f9cca65b96ab05732ed1902afd0f3086be54d6bb6b47c86a289ecf4ea5cdc25d

FROM docker.io/calico/cni:v$VERSION as upstream

FROM docker.io/library/golang:1.22.12-alpine3.20 as builder

ARG VERSION HASH
RUN wget https://github.com/projectcalico/calico/archive/refs/tags/v$VERSION.tar.gz \
  && { echo "$HASH *v$VERSION.tar.gz" | sha256sum -c -; } \
  && mkdir /go/calico && tar xf "v$VERSION.tar.gz" --strip-components=1 -C /go/calico \
  && rm -- "v$VERSION.tar.gz"

COPY --from=upstream /licenses/ /out/licenses/
COPY --from=upstream /opt/cni/ /out/opt/cni/
RUN set -e \
  && apk add --no-cache binutils \
  && rm /out/opt/cni/bin/install /out/opt/cni/bin/calico /out/opt/cni/bin/calico-ipam \
  && strip /out/opt/cni/bin/*

WORKDIR /go/calico
RUN CGO_ENABLED=0 go build \
  -v -buildvcs=false \
  -o /out/opt/cni/bin/ \
  -ldflags "-s -w -X main.VERSION=v$VERSION" \
  ./cni-plugin/cmd/calico ./cni-plugin/cmd/install 

RUN set -e \
  && cd /out/opt/cni/bin \
  && ln -s calico calico-ipam

FROM scratch
COPY --from=builder /out/ /

ENV PATH=/opt/cni/bin
WORKDIR /opt/cni/bin
CMD ["/opt/cni/bin/install"]
