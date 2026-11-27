ARG BUILDER_IMAGE=docker.io/library/golang:1.26.10-alpine3.24@sha256:a2012b4a1d1f9f7e9f44e0d39b805a901e856b1dd80b4e6ee4338db547050308

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base

RUN apk add --no-interactive --no-cache patch make bash rsync

FROM build-base AS kube-proxy

# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.35.md#source-code
ARG K8S_VERSION=1.35.10
ARG K8S_HASH=21206f71aa990caced61df7b5851a04c302e72ec61768ac95dd694e37ec8517f59abefe0fa782bf5bf4398014a777c1524524c291e5a97f55b834cc5af034bf9

# Kubernetes 1.35 still ships old dependencies which are flagged for CVEs.
# The bumps only landed upstream in the 1.37 line, so pull it in here and
# re-vendor before building.
ARG XCRYPTO_VERSION=v0.55.0
ARG CEL_GO_VERSION=v0.29.0
ARG OTEL_SDK_VERSION=v1.43.0
ARG GRPC_VERSION=v1.83.2

RUN set -euo pipefail \
  && wget -q "https://dl.k8s.io/v${K8S_VERSION}/kubernetes-src.tar.gz" \
  && { echo "${K8S_HASH} *kubernetes-src.tar.gz" | sha512sum -c -; } \
  && mkdir -p /go/kubernetes \
  && tar xf kubernetes-src.tar.gz -C /go/kubernetes \
  && rm kubernetes-src.tar.gz

ARG TARGETARCH
RUN --mount=source=files,target=/run/stage/files,ro \
  --mount=type=tmpfs,target=/go/kubernetes/_output \
  --mount=type=cache,id=kube-proxy-go-cache-$TARGETARCH,target=/run/stage/kube-proxy-go-cache \
  set -euo pipefail \
  && { [ "$TARGETARCH" != riscv64 ] || patch -d /go/kubernetes -p0 </run/stage/files/riscv64.patch; } \
  && du -sh /run/stage/kube-proxy-go-cache \
  && cd /go/kubernetes \
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
  && grep -q "^# google.golang.org/grpc $GRPC_VERSION\$" vendor/modules.txt \
  && GOCACHE=/run/stage/kube-proxy-go-cache KUBE_BUILD_PLATFORMS="linux/$TARGETARCH" make -C /go/kubernetes \
    WHAT='-trimpath -buildvcs=false cmd/kube-proxy' \
    FORCE_HOST_GO=y \
    KUBE_STATIC_OVERRIDES=kube-proxy \
    KUBE_VERBOSE=9 \
  && mkdir -p /opt/stage \
  && mv /go/kubernetes/_output/local/bin/linux/*/kube-proxy /opt/stage/kube-proxy

FROM build-base AS iptables-wrapper

ARG IPTABLES_WRAPPER_VERSION=c6b9b2d4ee8701f3d476768ab8732d1b85ec7fef
ARG IPTABLES_WRAPPER_HASH=bd35d22da90a317ec9b91a04c56831916b04d80e9b6318f5440df045d99fcba6

RUN set -euo pipefail \
  && wget -qO iptables-wrapper.tar.gz "https://github.com/kubernetes-sigs/iptables-wrappers/archive/$IPTABLES_WRAPPER_VERSION.tar.gz" \
  && { echo "${IPTABLES_WRAPPER_HASH} *iptables-wrapper.tar.gz" | sha256sum -c -; } \
  && mkdir -p /go/iptables-wrapper \
  && tar xf iptables-wrapper.tar.gz --strip-components=1 -C /go/iptables-wrapper \
  && rm iptables-wrapper.tar.gz

ARG TARGETARCH
RUN --mount=source=files,target=/run/stage/files,ro \
  --mount=type=tmpfs,target=/go/iptables-wrapper/bin \
  --mount=type=cache,id=iptables-wrapper-go-cache-$TARGETARCH,target=/root/.cache/go-build \
  --network=none \
  set -euo pipefail \
  && du -sh /root/.cache/go-build \
  && (cd /go/iptables-wrapper && patch </run/stage/files/iptables-wrapper.patch) \
  && GOARCH="$TARGETARCH" make -C /go/iptables-wrapper build \
  && mv /go/iptables-wrapper/bin/iptables-wrapper /go/iptables-wrapper

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS baselayout
ARG TARGETARCH
RUN --mount=source=alpine-keys/$TARGETARCH,target=/run/stage/alpine/keys,ro \
  --mount=from=iptables-wrapper,source=/go/iptables-wrapper,target=/run/stage/iptables-wrapper,ro \
  set -euo pipefail \
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
COPY --from=kube-proxy /opt/stage/kube-proxy /usr/local/bin/kube-proxy


ENTRYPOINT ["/usr/local/bin/kube-proxy"]
