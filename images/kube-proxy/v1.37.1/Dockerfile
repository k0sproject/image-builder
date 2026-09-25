ARG BUILDER_IMAGE=docker.io/library/golang:1.26.4-alpine3.24

# https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.37.md#source-code
ARG VERSION=1.37.0-alpha.3
ARG HASH=407aa7241cd88a8ee7bf1f1b18399cc3adedcc25adb8df7123e6b2b4a5856ed3972b88262c0ae0eb9eec7d84c67250fbadf0f1f76a88530c2cede1348bec8353

ARG IPTABLES_WRAPPER_VERSION=bfef9e5087a198b50a4124bb9ce9d2c7c99025dd
ARG IPTABLES_WRAPPER_HASH=cefaaa2325236de34f0bc55b526aa9b4f319ba90cf136001d646c7bab6d51a32


FROM --platform=$BUILDPLATFORM $BUILDER_IMAGE AS build-base
ENV GOTOOLCHAIN=local CGO_ENABLED=0 GOTELEMETRY=off
RUN apk add --no-interactive --no-cache patch make bash rsync


FROM build-base AS kube-proxy
WORKDIR /go/src/kube-proxy
ARG VERSION HASH
RUN --mount=source=files,target=/run/stage/files,ro \
  --mount=type=tmpfs,target=/tmp \
  set -euo pipefail \
  && wget -qO /tmp/sources.tar.gz https://dl.k8s.io/v$VERSION/kubernetes-src.tar.gz \
  && { echo $HASH /tmp/sources.tar.gz | sha512sum -c -; } \
  && tar xf /tmp/sources.tar.gz \
  && patch -p0 </run/stage/files/riscv64.patch

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
  set -euo pipefail \
  && wget -qO /tmp/sources.tar.gz https://github.com/kubernetes-sigs/iptables-wrappers/archive/$IPTABLES_WRAPPER_VERSION.tar.gz \
  && { echo $IPTABLES_WRAPPER_HASH /tmp/sources.tar.gz | sha256sum -c -; } || { sha256sum /tmp/sources.tar.gz; exit 1; } \
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
    tzdata \
    ca-certificates-bundle \
    conntrack-tools \
    ipset \
    iptables \
    nftables \
    iptables-legacy \
    kmod \
  && cp -a /run/stage/iptables-wrapper/iptables-wrapper /opt/stage/usr/sbin \
  && chroot /opt/stage /usr/sbin/iptables-wrapper install \
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
