# https://github.com/projectcalico/calico/blob/v3.29.1/cni-plugin/Dockerfile

ARG \
  VERSION=3.29.1 \
  HASH=17894ed9f7487f1418e599fdeff5db9047374dee12d560114e25ff9147a455c3 \
  # https://github.com/projectcalico/calico/blob/v3.29.1/metadata.mk#L46-L49
  # Calico has FLANNEL_VERSION=main branch and CNI_VERSION=master.
  # v3.29.1 was released 2024-11-21.
  #
  # https://github.com/projectcalico/calico/blob/v3.29.1/cni-plugin/Makefile#L169
  # https://github.com/projectcalico/flannel-cni-plugin/commits/main/?since=2024-09-12&until=2024-11-21
  FLANNEL_VERSION=5a977558e9fbbf93ff7ba927847fbca194e02416 \
  #
  # https://github.com/projectcalico/calico/blob/v3.29.1/cni-plugin/Makefile#L150
  # https://github.com/projectcalico/containernetworking-plugins/commits/master/?since=2024-10-21&until=2024-11-21
  CNI_VERSION=bd588f8f788998f371f4b9ec94bc81071be2fcce \
  BUILDER_IMAGE=docker.io/library/golang:1.22.10-alpine3.20

FROM $BUILDER_IMAGE AS builder

ARG VERSION HASH
RUN wget https://github.com/projectcalico/calico/archive/refs/tags/v$VERSION.tar.gz \
  && { echo "$HASH *v$VERSION.tar.gz" | sha256sum -c -; } \
  && mkdir /go/calico && tar xf "v$VERSION.tar.gz" --strip-components=1 -C /go/calico \
  && rm -- "v$VERSION.tar.gz"

WORKDIR /go/calico
RUN CGO_ENABLED=0 go build \
  -v -buildvcs=false \
  -o /out/opt/cni/bin/ \
  -ldflags "-s -w -X main.VERSION=v$VERSION" \
  ./cni-plugin/cmd/calico ./cni-plugin/cmd/install 

RUN set -e \
  && cd /out/opt/cni/bin \
  && ln -s calico calico-ipam

FROM $BUILDER_IMAGE AS flannel
ARG FLANNEL_VERSION

RUN apk add --no-cache git make bash
RUN mkdir -p /go/flannel
WORKDIR /go/flannel

RUN git clone --single-branch https://github.com/projectcalico/flannel-cni-plugin.git /go/flannel \
  && git reset --hard $FLANNEL_VERSION 

RUN make build_linux

FROM $BUILDER_IMAGE AS cni-bins
ARG CNI_VERSION

RUN apk add --no-cache git make bash
RUN mkdir -p /go/cni
WORKDIR /go/cni

RUN git clone --single-branch https://github.com/projectcalico/containernetworking-plugins.git /go/cni \
  && git reset --hard $CNI_VERSION

RUN GOFLAGS='-buildvcs=false' CGO_ENABLED=0 ./build_linux.sh -ldflags "-X github.com/containernetworking/plugins/pkg/utils/buildversion.BuildVersion=$(GIT_VERSION)"


FROM scratch
COPY --from=builder /out/ /
COPY --from=flannel /go/flannel/dist/flannel-* /opt/cni/bin/flannel
COPY --from=cni-bins /go/cni/bin/* /opt/cni/bin/
ENV PATH=/opt/cni/bin
WORKDIR /opt/cni/bin
CMD ["/opt/cni/bin/install"]
