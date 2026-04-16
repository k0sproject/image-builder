FROM docker.io/library/alpine:3.21.3 AS build
# https://github.com/kubernetes/kubernetes/blob/821bc2e15e3abadb996d477f2bfb59466cec01e0/build/pause/Makefile#L20
ENV VERSION=3.10.1
ENV HASH=26fe80855d14b50136986bc9806b96e72124a97e

RUN apk add --no-cache gcc musl-dev binutils

# https://github.com/kubernetes/kubernetes/blob/master/build/pause/linux/pause.c
RUN wget https://github.com/kubernetes/kubernetes/raw/$HASH/build/pause/linux/pause.c
RUN gcc -Os -static -DVERSION=$VERSION -o pause pause.c && strip pause

FROM scratch
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/kubernetes/kubernetes"
COPY --from=build /pause /pause
USER 65535:65535
ENTRYPOINT ["/pause"]
