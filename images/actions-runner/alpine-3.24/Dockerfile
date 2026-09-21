ARG \
    # v2.337.0
    RUNNER_REVISION=397b032cbf865e9c3ddfab89d533ec19325e1273 \
    RUNNER_CONTAINER_HOOKS_VERSION=0.2.0 \
    DOTNET_SDK_IMAGE=mcr.microsoft.com/dotnet/sdk:8.0.425-alpine3.24@sha256:3111b113abec80b4a8a3d4b5cebebf61a4cdab019b7e56ca3e6389e6ac4e1c8d \
    ALPINE_IMAGE=docker.io/library/alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6

FROM --platform=$BUILDPLATFORM $DOTNET_SDK_IMAGE AS build-runner
# Upstream's dev.sh is a bash script.
RUN apk add --no-interactive --no-cache bash

ARG RUNNER_REVISION
WORKDIR /src/runner
RUN --mount=source=patches,target=/run/patches,ro \
    git -C .. -c advice.detachedHead=false clone --revision "$RUNNER_REVISION" --depth 1 https://github.com/actions/runner.git \
    && git apply /run/patches/*.patch
WORKDIR /src/runner/src

ARG TARGETARCH
RUN --mount=type=bind,source=build-runner.sh,target=/run/build-runner.sh \
    /run/build-runner.sh restore
RUN --mount=type=bind,source=build-runner.sh,target=/run/build-runner.sh \
    --network=none \
    /run/build-runner.sh layout package


FROM $ALPINE_IMAGE

ARG TARGETPLATFORM RUNNER_CONTAINER_HOOKS_VERSION
# Docker and Docker Compose arguments
ARG CHANNEL=stable
ARG DOCKER_VERSION=20.10.21
ARG DOCKER_COMPOSE_VERSION=v2.16.0
ARG RUNNER_USER_UID=1001
ARG DOCKER_GROUP_GID=121

RUN apk add --no-interactive --no-cache \
    # https://learn.microsoft.com/dotnet/core/install/linux-alpine?tabs=dotnet8#dependencies
    ca-certificates \
    libgcc \
    libssl3 \
    libstdc++ \
    zlib \
    icu-libs \
    icu-data-full \
    tzdata \
    krb5-libs \
    # Other pre-installed packages for the runner
    bash \
    build-base \
    curl \
    git \
    git-lfs \
    jq \
    musl-utils \
    openssh-client \
    openssl \
    procps \
    shadow \
    sudo \
    tar \
    tini \
    unzip \
    yaml-dev \
    zip \
    nodejs \
    && addgroup -g "${DOCKER_GROUP_GID}" docker \
    && adduser -D -u "${RUNNER_USER_UID}" runner \
    && adduser runner docker \
    && adduser runner wheel \
    && echo "%wheel   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

ENV HOME=/home/runner

ENV RUNNER_ASSETS_DIR=/runnertmp
RUN --mount=from=build-runner,source=/src/runner/_package,target=/run/stage/runner,ro \
    --network=none \
    mkdir -p "$RUNNER_ASSETS_DIR" \
    && cd "$RUNNER_ASSETS_DIR" \
    && tar -xzf /run/stage/runner/actions-runner-*.tar.gz \
    # The runner's bundled node20/node24 (used to run JS actions and built-in hooks)
    # are glibc binaries, and node24 isn't even shipped for linux-arm at all.
    # Alpine's own nodejs package is musl-native; point every "using: nodeNN" version
    # actions may request at it instead.
    && for nodever in node20 node24; do \
         mkdir -p "externalstmp/$nodever/bin" \
         && ln -sf /usr/bin/node "externalstmp/$nodever/bin/node"; \
       done

ENV RUNNER_TOOL_CACHE=/opt/hostedtoolcache
RUN mkdir /opt/hostedtoolcache \
    && chgrp docker /opt/hostedtoolcache \
    && chmod g+rwx /opt/hostedtoolcache

RUN cd "$RUNNER_ASSETS_DIR" \
    && curl -fLo runner-container-hooks.zip https://github.com/actions/runner-container-hooks/releases/download/v${RUNNER_CONTAINER_HOOKS_VERSION}/actions-runner-hooks-k8s-${RUNNER_CONTAINER_HOOKS_VERSION}.zip \
    && unzip ./runner-container-hooks.zip -d ./k8s \
    && rm -f runner-container-hooks.zip

RUN set -vx; \
    export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "arm64" ]; then export ARCH=aarch64 ; fi \
    && if [ "$ARCH" = "arm" ]; then export ARCH=armhf ; fi \
    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "i386" ] || [ "$ARCH" = "" ]; then export ARCH=x86_64 ; fi \
    && if [ "$ARCH" = "" ]; then export ARCH=arm64 ; fi \
    && curl -fLo docker.tgz https://download.docker.com/linux/static/${CHANNEL}/${ARCH}/docker-${DOCKER_VERSION}.tgz \
    && tar zxvf docker.tgz \
    && install -o root -g root -m 755 docker/docker /usr/bin/docker \
    && rm -rf docker docker.tgz

RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "arm64" ]; then export ARCH=aarch64 ; fi \
    && if [ "$ARCH" = "arm" ]; then export ARCH=armv7 ; fi \
    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "i386" ] || [ "$ARCH" = "" ]; then export ARCH=x86_64 ; fi \
    && curl -fLo /usr/bin/docker-compose https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-${ARCH} \
    && chmod +x /usr/bin/docker-compose

# We place the scripts in `/usr/bin` so that users who extend this image can
# override them with scripts of the same name placed in `/usr/local/bin`.
COPY entrypoint.sh startup.sh logger.sh graceful-stop.sh update-status /usr/bin/

# Copy the docker shim which propagates the docker MTU to underlying networks
# to replace the docker binary in the PATH.
COPY docker-shim.sh /usr/local/bin/docker

# Configure hooks folder structure.
COPY --chown=runner:runner hooks /etc/arc/hooks/

ENV ImageOS=alpine324

RUN echo "PATH=${PATH}" > /etc/environment \
    && echo "ImageOS=${ImageOS}" >> /etc/environment

USER runner

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["entrypoint.sh"]


