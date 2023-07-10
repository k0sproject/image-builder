# this needs to be here to be visible to second build stage
ARG CALICO_VERSION=3.26.1

FROM golang:1.20.5 as builder

# set calico verion in this scope too
ARG CALICO_VERSION=3.26.1

RUN git clone -b v$CALICO_VERSION https://github.com/projectcalico/calico.git /go/calico
RUN mkdir -p /opt/cni/bin/ && cd /go/calico && \
    go mod download && \
    CGO_ENABLED=0 go build -buildvcs=false -v -o /opt/cni/bin/install -ldflags "-X main.VERSION=v$CALICO_VERSION" ./cni-plugin/cmd/calico && \
    cp /opt/cni/bin/install /opt/cni/bin/calico && \
    ln -s install /opt/cni/bin/calico-ipam

FROM docker.io/calico/cni:v$CALICO_VERSION

COPY --from=builder /opt/cni/bin/ /opt/cni/bin/
