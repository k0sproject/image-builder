FROM golang:1.19 as builder

RUN mkdir -p /go/calico && git clone -b v3.24.5 https://github.com/projectcalico/calico.git /go/calico

RUN mkdir -p /opt/cni/bin/ && cd /go/calico && \
    go get -u github.com/emicklei/go-restful@v2.16.0 && \
    go get -u golang.org/x/net@v0.7.0 && \
    go mod download && \
    CGO_ENABLED=0 go build -buildvcs=false -v -o /opt/cni/bin/install -ldflags "-X main.VERSION=v3.24.5" ./cni-plugin/cmd/calico && \
    cp /opt/cni/bin/install /opt/cni/bin/calico && \
    cp /opt/cni/bin/install /opt/cni/bin/calico-ipam

FROM docker.io/calico/cni:v3.24.5

COPY --from=builder /opt/cni/bin/ /opt/cni/bin/
