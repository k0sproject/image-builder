FROM golang:1.19 as builder

RUN mkdir -p /go/calico && git clone -b v3.24.5 https://github.com/projectcalico/calico.git /go/calico

RUN mkdir -p /go/bin/ && cd /go/calico && \
    go get -u github.com/emicklei/go-restful@v2.16.0 && \
    go get -u golang.org/x/net@v0.7.0 && \
    go mod download && \
    go build -buildvcs=false -v -o /go/bin/kube-controllers -ldflags "-X main.VERSION=v3.24.5" ./kube-controllers/cmd/kube-controllers

FROM docker.io/calico/kube-controllers:v3.24.5

COPY --from=builder /go/bin/kube-controllers /usr/bin/kube-controllers



