ARG CALICO_VERSION=3.26.1
FROM golang:1.20.5 as builder

ARG CALICO_VERSION=3.26.1

RUN git clone -b v$CALICO_VERSION https://github.com/projectcalico/calico.git /go/calico

RUN mkdir -p /opt/cni/bin/ && cd /go/calico && \
    go mod tidy && \
    CGO_ENABLED=0 go build -buildvcs=false -v -o /opt/cni/bin/calico-node -ldflags "-X main.VERSION=v$CALICO_VERSION" ./node/cmd/calico-node

FROM docker.io/calico/node:v$CALICO_VERSION

COPY --from=builder /opt/cni/bin/calico-node /usr/bin/calico-node
