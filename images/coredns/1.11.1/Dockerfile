ARG \
  VERSION=1.11.1 \
  GIT_COMMIT=ae2bbc29be1aaae0b3ded5d188968a6c97bb3144 \
  HASH=4e1cde1759d1705baa9375127eb405cd2f5031f9152947bb958a51fee5898d8c

FROM docker.io/library/golang:1.20.8-alpine3.18 as build
ARG VERSION GIT_COMMIT HASH

ENV CGO_ENABLED=0

RUN wget https://github.com/coredns/coredns/archive/refs/tags/v${VERSION}.tar.gz \
  && { echo "${HASH} *v${VERSION}.tar.gz" | sha256sum -c -; } \
  && tar xf "v${VERSION}.tar.gz" -C /go \
  && rm -- "v${VERSION}.tar.gz"

WORKDIR /go/coredns-$VERSION
RUN go build -ldflags="-s -w -X github.com/coredns/coredns/coremain.GitCommit=$GIT_COMMIT"

FROM gcr.io/distroless/static-debian12@sha256:98e138282ba524ff4f5124fec603f82ee2331df4ba981d169b3ded8bcd83ca52 as static

FROM scratch
ARG VERSION

COPY --from=build /go/coredns-$VERSION/coredns /coredns
COPY --from=static /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 53 53/udp
ENTRYPOINT ["/coredns"]
