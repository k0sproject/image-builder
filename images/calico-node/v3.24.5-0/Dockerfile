FROM golang:1.19 as builder

RUN mkdir -p /go/calico && git clone -b v3.24.5 https://github.com/projectcalico/calico.git /go/calico

RUN mkdir -p /go/bin/ && cd /go/calico && \
    go get -u github.com/emicklei/go-restful@v2.16.0 && \
    go get -u golang.org/x/net@v0.7.0 && \
    go mod download && \
    export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && make -C node dist/bin/calico-node-amd64

FROM docker.io/calico/node:v3.24.5

COPY --from=builder / /
