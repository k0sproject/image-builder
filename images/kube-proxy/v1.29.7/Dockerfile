ARG BUILDER_IMAGE=docker.io/library/golang:1.22.5-alpine3.19

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base

RUN apk add --no-interactive --no-cache patch make bash rsync

FROM build-base AS kube-proxy

# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.29.md#source-code
ARG K8S_VERSION=1.29.7
ARG K8S_HASH=9b80bca98bfb889040fd110c630fc00714170548b61031b91802e7ec9ecf379d3c00fae116842bab5d119f5d26d4321b8cc2dcbd833b2220b033eb25dd6a1a34

RUN set -euo pipefail \
  && wget -q "https://dl.k8s.io/v${K8S_VERSION}/kubernetes-src.tar.gz" \
  && { echo "${K8S_HASH} *kubernetes-src.tar.gz" | sha512sum -c -; } \
  && mkdir -p /go/kubernetes \
  && tar xf kubernetes-src.tar.gz -C /go/kubernetes \
  && rm kubernetes-src.tar.gz

ARG TARGETARCH
RUN --mount=type=tmpfs,target=/go/kubernetes/_output \
  --mount=type=cache,id=kube-proxy-go-cache-$TARGETARCH,target=/run/stage/kube-proxy-go-cache \
  --network=none \
  set -euo pipefail \
  && du -sh /run/stage/kube-proxy-go-cache \
  && GOCACHE=/run/stage/kube-proxy-go-cache KUBE_BUILD_PLATFORMS="linux/$TARGETARCH" make -C /go/kubernetes \
    WHAT='-trimpath -buildvcs=false cmd/kube-proxy' \
    FORCE_HOST_GO=y \
    KUBE_STATIC_OVERRIDES=kube-proxy \
    KUBE_VERBOSE=9 \
  && mkdir -p /opt/stage \
  && mv /go/kubernetes/_output/local/bin/linux/*/kube-proxy /opt/stage/kube-proxy

FROM build-base AS iptables-wrapper

ARG IPTABLES_WRAPPER_VERSION=5792812d9e5a5bb7f22d79d557bbfeece253343d
ARG IPTABLES_WRAPPER_HASH=a1cc352145b052c15d1334414ec12e9b10630b5e768a5234b156af491997e08f

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

FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE as baselayout
ARG TARGETARCH
RUN --mount=source=alpine-keys/$TARGETARCH,target=/run/stage/alpine/keys,ro \
  --mount=from=iptables-wrapper,source=/go/iptables-wrapper,target=/run/stage/iptables-wrapper,ro \
  set -euo pipefail \
  && case "${TARGETARCH-}" in \
    amd64) export APK_ARCH=x86_64 ;; \
    arm64) export APK_ARCH=aarch64 ;; \
    arm) export APK_ARCH=armv7 ;; \
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
COPY --from=baselayout /opt/stage /
COPY --from=kube-proxy /opt/stage/kube-proxy /usr/local/bin/kube-proxy

ENTRYPOINT ["/usr/local/bin/kube-proxy"]
