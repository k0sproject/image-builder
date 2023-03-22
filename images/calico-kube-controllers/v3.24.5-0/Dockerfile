FROM golang:1.19 as builder

RUN mkdir -p /go/calico && git clone -b v3.24.5 https://github.com/projectcalico/calico.git /go/calico

RUN mkdir -p /go/bin/ && cd /go/calico && \
    go get -u github.com/emicklei/go-restful@v2.16.0 && \
    go get -u golang.org/x/net@v0.7.0 && \
    go mod download && \
    export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && echo $ARCH \
    && if [ "$ARCH" = "amd64" ]; then \
      CGO_ENABLED=1 GOEXPERIMENT=boringcrypto go build -o /go/bin/kube-controllers \
        -tags fipsstrict,osusergo,netgo -v -buildvcs=false \
        -ldflags "-X main.VERSION=v3.24.5 -linkmode external -extldflags -static" ./kube-controllers/cmd/kube-controllers ; \
    else \
      CGO_ENABLED=0 go build -buildvcs=false -v -o /go/bin/kube-controllers -ldflags "-X main.VERSION=v3.24.5" ./kube-controllers/cmd/kube-controllers \
    ; fi


FROM docker.io/calico/kube-controllers:v3.24.5

COPY --from=builder /go/bin/kube-controllers /usr/bin/kube-controllers



