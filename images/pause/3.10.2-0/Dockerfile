FROM docker.io/library/alpine:3.21.3 AS build
# https://github.com/kubernetes/kubernetes/blob/e6bea155c582846cfc43bf77ebc342b4cb83c637/build/pause/Makefile#L20
ENV VERSION=3.10.2
ENV HASH=e6bea155c582846cfc43bf77ebc342b4cb83c637

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
