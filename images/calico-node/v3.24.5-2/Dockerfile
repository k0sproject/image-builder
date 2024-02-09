FROM golang:1.19 as builder

RUN mkdir -p /go/calico && git clone -b v3.24.5 https://github.com/projectcalico/calico.git /go/calico

RUN mkdir -p /opt/cni/bin/ && cd /go/calico && \
    go get -u github.com/docker/distribution@v2.8.2 && \
    go get -u github.com/emicklei/go-restful@v2.16.0 && \
    go get -u golang.org/x/net@v0.17.0 && \
    go get -u google.golang.org/grpc@v1.57.1 && \
    sed -i -e 's/kubernetes v1.24.0/kubernetes v1.25.16/' go.mod && \
    sed -i -e 's/grpc v1.40.0/grpc v1.57.1/' go.mod && \
    sed -i -e 's/v0.24.0/v0.25.16/' go.mod && \
    go mod tidy && \
    CGO_ENABLED=0 go build -buildvcs=false -v -o /opt/cni/bin/calico-node -ldflags "-X main.VERSION=v3.24.5" ./node/cmd/calico-node

FROM docker.io/calico/node:v3.24.5

COPY --from=builder /opt/cni/bin/calico-node /usr/bin/calico-node
