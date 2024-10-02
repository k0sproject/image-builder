# https://github.com/projectcalico/calico/blob/v3.28.1/cni-plugin/Dockerfile.amd64

ARG \
  VERSION=3.28.1 \
  HASH=c56f1530e7ded9d5b4afb9d83a7a24da6d2959ef7ad38521813f1c2bf138182d \
  # https://github.com/projectcalico/calico/blob/v3.28.1/metadata.mk#L53
  FLANNEL_VERSION=v1.2.0-flannel2-go1.22.5 \
  # https://github.com/projectcalico/calico/blob/v3.28.1/metadata.mk#L52
  CNI_VERSION=v1.1.1-calico+go-1.22.5 \
  BUILDER_IMAGE=docker.io/library/golang:1.22.5-alpine3.20

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

RUN git clone --single-branch --branch ${FLANNEL_VERSION} https://github.com/projectcalico/flannel-cni-plugin.git /go/flannel

RUN make build_linux

FROM $BUILDER_IMAGE AS cni-bins
ARG CNI_VERSION

RUN apk add --no-cache git make bash
RUN mkdir -p /go/cni
WORKDIR /go/cni

RUN git clone --single-branch --branch $CNI_VERSION https://github.com/projectcalico/containernetworking-plugins.git /go/cni

RUN GOFLAGS='-buildvcs=false' CGO_ENABLED=0 ./build_linux.sh -ldflags "-X github.com/containernetworking/plugins/pkg/utils/buildversion.BuildVersion=$(GIT_VERSION)"


FROM scratch
COPY --from=builder /out/ /
COPY --from=flannel /go/flannel/dist/flannel-* /opt/cni/bin/flannel
COPY --from=cni-bins /go/cni/bin/* /opt/cni/bin/
ENV PATH=/opt/cni/bin
WORKDIR /opt/cni/bin
CMD ["/opt/cni/bin/install"]
