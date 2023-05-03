FROM golang:1.19 as builder

RUN mkdir -p /go/calico && git clone -b v3.24.5 https://github.com/projectcalico/calico.git /go/calico

RUN mkdir -p /opt/cni/bin/ && cd /go/calico && \
    go get -u github.com/emicklei/go-restful@v2.16.0 && \
    go get -u golang.org/x/net@v0.7.0 && \
    sed -i -e 's/kubernetes v1.24.0/kubernetes v1.24.8/' go.mod && \
    go mod tidy && \
    CGO_ENABLED=0 go build -buildvcs=false -v -o /opt/cni/bin/calico-node -ldflags "-X main.VERSION=v3.24.5" ./node/cmd/calico-node

FROM docker.io/calico/node:v3.24.5

COPY --from=builder /opt/cni/bin/calico-node /usr/bin/calico-node
