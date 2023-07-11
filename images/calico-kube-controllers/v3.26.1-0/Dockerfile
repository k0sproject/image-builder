ARG CALICO_VERSION=3.26.1
FROM golang:1.20.5 as builder
ARG CALICO_VERSION=3.26.1

RUN git clone -b v$CALICO_VERSION https://github.com/projectcalico/calico.git /go/calico
RUN mkdir -p /go/bin/ && cd /go/calico && \
    go mod download && \
    export ARCH=$(echo ${TARGETPLATFORM} | cut -d / -f2) \
    && echo $ARCH \
    && if [ "$ARCH" = "amd64" ]; then \
      CGO_ENABLED=1 GOEXPERIMENT=boringcrypto go build -o /go/bin/kube-controllers \
        -tags fipsstrict,osusergo,netgo -v -buildvcs=false \
        -ldflags "-X main.VERSION=v$CALICO_VERSION -linkmode external -extldflags -static" ./kube-controllers/cmd/kube-controllers ; \
    else \
      CGO_ENABLED=0 go build -buildvcs=false -v -o /go/bin/kube-controllers -ldflags "-X main.VERSION=v$CALICO_VERSION" ./kube-controllers/cmd/kube-controllers \
    ; fi

FROM docker.io/calico/kube-controllers:v$CALICO_VERSION

COPY --from=builder /go/bin/kube-controllers /usr/bin/kube-controllers



