ARG BUILDER_IMAGE=docker.io/library/golang:1.26.8-alpine3.24@sha256:8ac98ca534ac3f51e1f420a1dd2c15e74c75cfa0f23f3ad27eb5d7236c349a0c

# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.36.md#source-code
ARG VERSION=1.36.5
ARG HASH=720201f23d63a6394515f347d3674bc2c0a267309fa3b007c2f8cc941d29f55a0a45484ddb811d88aa578cc79ed827f65e8868c0bad6f7d84a8154e27e4cffd0

ARG IPTABLES_WRAPPER_VERSION=c6b9b2d4ee8701f3d476768ab8732d1b85ec7fef
ARG IPTABLES_WRAPPER_HASH=bd35d22da90a317ec9b91a04c56831916b04d80e9b6318f5440df045d99fcba6

# Kubernetes 1.36 still ships old dependencies which are flagged for CVEs.
# The bumps only landed upstream in the 1.37 line, so pull it in here and
# re-vendor before building.
ARG XCRYPTO_VERSION=v0.55.0
ARG CEL_GO_VERSION=v0.29.0
ARG OTEL_SDK_VERSION=v1.43.0
ARG GRPC_VERSION=v1.83.2


FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base
ENV GOTOOLCHAIN=local CGO_ENABLED=0 GOTELEMETRY=off
RUN apk add --no-interactive --no-cache patch make bash rsync


FROM build-base AS kube-proxy
WORKDIR /go/src/kube-proxy
ARG VERSION HASH XCRYPTO_VERSION CEL_GO_VERSION OTEL_SDK_VERSION GRPC_VERSION
RUN --mount=source=files,target=/run/stage/files,ro \
  --mount=type=tmpfs,target=/tmp \
  set -eu \
  && wget -qO /tmp/sources.tar.gz https://dl.k8s.io/v$VERSION/kubernetes-src.tar.gz \
  && { printf '%s */tmp/sources.tar.gz' "$HASH" | sha512sum -c -; } \
  && tar xf /tmp/sources.tar.gz \
  && patch -p0 </run/stage/files/riscv64.patch \
  && for f in go.mod staging/src/k8s.io/*/go.mod; do \
    grep -q golang.org/x/crypto "$f" || continue; \
    ( cd "$(dirname "$f")" && go mod edit -require=golang.org/x/crypto@$XCRYPTO_VERSION ); \
  done \
  && for f in go.mod staging/src/k8s.io/*/go.mod; do \
    grep -q github.com/google/cel-go "$f" || continue; \
    ( cd "$(dirname "$f")" && go mod edit -require=github.com/google/cel-go@$CEL_GO_VERSION ); \
  done \
  && for f in go.mod staging/src/k8s.io/*/go.mod; do \
    grep -q go.opentelemetry.io/otel/sdk "$f" || continue; \
    ( cd "$(dirname "$f")" && go mod edit -require=go.opentelemetry.io/otel/sdk@$OTEL_SDK_VERSION ); \
  done \
  && for f in go.mod staging/src/k8s.io/*/go.mod; do \
    grep -q google.golang.org/grpc "$f" || continue; \
    ( cd "$(dirname "$f")" && go mod edit -require=google.golang.org/grpc@$GRPC_VERSION ); \
  done \
  && go work vendor \
  && grep -q "^# golang.org/x/crypto $XCRYPTO_VERSION\$" vendor/modules.txt \
  && grep -q "^# github.com/google/cel-go $CEL_GO_VERSION\$" vendor/modules.txt \
  && grep -q "^# go.opentelemetry.io/otel/sdk $OTEL_SDK_VERSION\$" vendor/modules.txt \
  && grep -q "^# google.golang.org/grpc $GRPC_VERSION\$" vendor/modules.txt

ARG TARGETARCH
RUN --mount=type=cache,id=kube-proxy-go-cache-$TARGETARCH,target=/run/build/go-cache \
  --mount=type=tmpfs,target=/go/src/kube-proxy/_output \
  --mount=type=tmpfs,target=/tmp \
  --network=none \
  set -eu \
  && GOCACHE=/run/build/go-cache KUBE_BUILD_PLATFORMS="linux/$TARGETARCH" make \
    WHAT='-trimpath -buildvcs=false cmd/kube-proxy' \
    FORCE_HOST_GO=y \
    KUBE_STATIC_OVERRIDES=kube-proxy \
    KUBE_VERBOSE=9 \
  && mv _output/local/bin/linux/*/kube-proxy .


FROM build-base AS iptables-wrapper
WORKDIR /go/src/iptables-wrapper
ARG IPTABLES_WRAPPER_VERSION IPTABLES_WRAPPER_HASH
RUN --mount=source=files,target=/run/stage/files,ro \
  --mount=type=tmpfs,target=/tmp \
  set -eu \
  && wget -qO /tmp/sources.tar.gz https://github.com/kubernetes-sigs/iptables-wrappers/archive/$IPTABLES_WRAPPER_VERSION.tar.gz \
  && { echo $IPTABLES_WRAPPER_HASH /tmp/sources.tar.gz | sha256sum -c -; } \
  && tar xf /tmp/sources.tar.gz --strip-components=1 \
  && patch </run/stage/files/iptables-wrapper.patch

ARG TARGETARCH
RUN --mount=type=cache,id=kube-proxy-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --mount=type=tmpfs,target=/tmp \
  --network=none \
  GOARCH="$TARGETARCH" make build \
  && mv bin/iptables-wrapper .


FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS baselayout
ARG TARGETARCH
RUN --mount=source=alpine-keys/$TARGETARCH,target=/run/stage/alpine/keys,ro \
  --mount=from=iptables-wrapper,source=/go/src/iptables-wrapper,target=/run/stage/iptables-wrapper,ro \
  set -eu \
  && case "${TARGETARCH-}" in \
    amd64) export APK_ARCH=x86_64 ;; \
    arm64) export APK_ARCH=aarch64 ;; \
    arm) export APK_ARCH=armv7 ;; \
    riscv64) export APK_ARCH=riscv64 ;; \
    *) echo Unsupported target platform: "${TARGETARCH-}"; exit 1;; \
  esac \
  && mkdir -p -- /opt/stage/etc/apk \
  && cp -a /etc/apk/repositories /run/stage/alpine/keys /opt/stage/etc/apk \
  && apk add --no-interactive --root /opt/stage --arch "$APK_ARCH" --initdb \
    alpine-release \
    busybox \
    tzdata \
    ca-certificates-bundle \
    conntrack-tools \
    ipset \
    iptables \
    nftables \
    iptables-legacy \
    kmod \
  && cp -a /run/stage/iptables-wrapper/iptables-wrapper-installer.sh /run/stage/iptables-wrapper/iptables-wrapper /opt/stage \
  && chroot /opt/stage /iptables-wrapper-installer.sh \
  && sed -i -e 's,^D:/bin/sh ,D:,' -e '/D:alpine-keys/d' /opt/stage/lib/apk/db/installed \
  && bins="$(chroot /opt/stage /bin/busybox --list-full)" \
  && apk del --no-interactive --no-network --root /opt/stage --purge busybox alpine-keys \
  && for bin in $bins; do \
    link="$(readlink "/opt/stage/$bin")"; \
    [ "${link##*/}" != busybox ] || rm "/opt/stage/$bin"; \
  done \
  && rm -r /opt/stage/etc/issue /opt/stage/etc/apk/repositories /opt/stage/var/cache

FROM scratch
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/kubernetes/kubernetes"
COPY --from=baselayout /opt/stage /
COPY --from=kube-proxy /go/src/kube-proxy/kube-proxy /usr/local/bin/kube-proxy


ENTRYPOINT ["/usr/local/bin/kube-proxy"]
