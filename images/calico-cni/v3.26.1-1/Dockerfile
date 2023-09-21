# https://github.com/projectcalico/calico/blob/v3.26.1/cni-plugin/Dockerfile.amd64

ARG \
  VERSION=3.26.1 \
  HASH=6d0afbbd4bdfe4deb18d0ac30adb7165eb08b0114ec5a00d016f37a8caf88849

FROM docker.io/calico/cni:v$VERSION as upstream

FROM docker.io/library/golang:1.20.8-alpine3.18 as builder

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
  -o /out/opt/cni/bin/calico \
  -ldflags "-s -w -X main.VERSION=v$VERSION" \
  ./cni-plugin/cmd/calico

RUN set -e \
  && cd /out/opt/cni/bin \
  && ln -s calico calico-ipam \
  && ln -s calico install

FROM scratch
COPY --from=builder /out/ /

ENV PATH=/opt/cni/bin
WORKDIR /opt/cni/bin
CMD ["/opt/cni/bin/install"]
