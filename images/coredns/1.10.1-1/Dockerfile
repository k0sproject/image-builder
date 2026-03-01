FROM golang:1.19.6 as build

RUN git clone -b v1.10.1 https://github.com/coredns/coredns.git /coredns

WORKDIR /coredns

RUN export GIT_COMMIT=$(git describe --dirty --always) && \
    go get -u golang.org/x/net@v0.7.0 && \
    CGO_ENABLED=0 go build -ldflags="-s -w -X github.com/coredns/coredns/coremain.GitCommit=$GIT_COMMIT"

FROM scratch

COPY --from=build /coredns/coredns /coredns
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 53 53/udp
ENTRYPOINT ["/coredns"]

