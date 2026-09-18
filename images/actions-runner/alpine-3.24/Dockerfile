FROM alpine:3.24.2

ARG TARGETPLATFORM
# Must stay on a release built against .NET 8, matching Alpine's dotnet8-runtime package.
ARG RUNNER_VERSION=2.337.0
ARG RUNNER_CONTAINER_HOOKS_VERSION=0.2.0
# Docker and Docker Compose arguments
ARG CHANNEL=stable
ARG DOCKER_VERSION=20.10.21
ARG DOCKER_COMPOSE_VERSION=v2.16.0
ARG DUMB_INIT_VERSION=0.19.0
ARG RUNNER_USER_UID=1001
ARG DOCKER_GROUP_GID=121

# dotnet8-runtime is Alpine's own musl-native build of the .NET runtime. The runner
# release tarball only ships a glibc-linked native host, so instead of that host we
# run the runner's managed DLLs directly through this musl-native `dotnet` (see the
# apphost-wrapping step below), avoiding any glibc-compat shims or binary patching.
RUN apk add --no-cache \
    bash \
    build-base \
    ca-certificates \
    curl \
    dotnet8-runtime \
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
RUN export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "i386" ]; then export ARCH=x64 ; fi \
    && if [ "$ARCH" = "" ]; then export ARCH=arm64 ; fi \
    && mkdir -p "$RUNNER_ASSETS_DIR" \
    && cd "$RUNNER_ASSETS_DIR" \
    && curl -fLo runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz \
    && mv ./externals ./externalstmp \
    && for apphost in bin/Runner.Listener bin/Runner.PluginHost bin/Runner.Worker; do \
         if [ -f "$apphost" ] && [ -f "$apphost.dll" ]; then \
           rm -f "$apphost" \
           && printf '#!/bin/sh\nexec dotnet "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/%s.dll" "$@"\n' "$(basename "$apphost")" > "$apphost" \
           && chmod +x "$apphost"; \
         fi; \
         # The release build is self-contained (glibc); rewrite its runtimeconfig.json
         # to framework-dependent so dotnet resolves Alpine's musl-native dotnet8-runtime
         # instead of the bundled glibc runtime libs.
         runtimeconfig="$apphost.runtimeconfig.json"; \
         if [ -f "$runtimeconfig" ]; then \
           jq '{runtimeOptions: (.runtimeOptions | {tfm, framework: {name: .includedFrameworks[0].name, version: .includedFrameworks[0].version}, configProperties})}' "$runtimeconfig" > "$runtimeconfig.tmp" \
           && mv "$runtimeconfig.tmp" "$runtimeconfig"; \
         fi; \
         # deps.json still pins the self-contained runtimepack (with its glibc native
         # libs) as an app dependency; strip it so only the system framework is used.
         depsjson="$apphost.deps.json"; \
         if [ -f "$depsjson" ]; then \
           jq '(.runtimeTarget.name) as $tgt | .targets[$tgt] |= with_entries(if (.key | startswith("runtimepack.")) then empty else (.value.dependencies //= {}) | .value.dependencies |= with_entries(select(.key | startswith("runtimepack.") | not)) end) | .libraries |= with_entries(select(.key | startswith("runtimepack.") | not))' "$depsjson" > "$depsjson.tmp" \
           && mv "$depsjson.tmp" "$depsjson"; \
         fi; \
       done \
    # config.sh's preflight `ldd`-checks the bundled (unused, glibc) native libs and
    # always fails on musl; that check is meaningless now that we run via dotnet exec.
    && sed -i '/^# Check dotnet Core 6.0 dependencies for Linux$/,/^# Change directory to the script root directory$/{/^# Change directory to the script root directory$/!d}' config.sh \
    # The runner's bundled node20/node24 (used to run JS actions and built-in hooks)
    # are glibc binaries too, and node24 isn't even shipped for linux-arm at all.
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


