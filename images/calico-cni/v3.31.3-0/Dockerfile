# https://github.com/projectcalico/calico/blob/v3.29.2/cni-plugin/Dockerfile

ARG \
  VERSION=3.31.3 \
  HASH=d130227adf56f5ae30ea22d8ef05974fbf4428360d4120f99f6bd3b1fa99d0d9 \
  # https://github.com/projectcalico/calico/blob/v3.31.3/metadata.mk#L52-L55
  # Calico has FLANNEL_VERSION=main branch and CNI_VERSION=master.
  # v3.31.3 was released 2025-12-19: https://github.com/projectcalico/calico/releases/tag/v3.31.3
  #
  # https://github.com/projectcalico/calico/blob/v3.31.3/cni-plugin/Makefile#L169
  # https://github.com/projectcalico/flannel-cni-plugin/commits/main/?since=2024-09-12&until=2025-12-19
  FLANNEL_VERSION=5a977558e9fbbf93ff7ba927847fbca194e02416 \
  #
  # https://github.com/projectcalico/calico/blob/v3.31.3/cni-plugin/Makefile#L150
  # https://github.com/projectcalico/containernetworking-plugins/commits/master/?since=2025-01-27&until=2025-12-19
  CNI_VERSION=9ffe547cb3b66f80dd32a00fc69a6d0082b55321 \
  BUILDER_IMAGE=docker.io/library/golang:1.25.5-alpine3.23

FROM $BUILDER_IMAGE AS builder

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
RUN CGO_ENABLED=0 go build \
  -v -buildvcs=false \
  -o /out/opt/cni/bin/ \
  -ldflags "-s -w -X main.VERSION=v$VERSION+k0s.0" \
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
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/projectcalico/calico"
COPY --from=builder /out/ /
COPY --from=flannel /go/flannel/dist/flannel-* /opt/cni/bin/flannel
COPY --from=cni-bins /go/cni/bin/* /opt/cni/bin/
ENV PATH=/opt/cni/bin
WORKDIR /opt/cni/bin
CMD ["/opt/cni/bin/install"]
