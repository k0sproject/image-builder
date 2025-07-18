# Build the proxy-agent binary
FROM golang:1.19.9 as builder
RUN mkdir /go/src/sigs.k8s.io
# version skew policy for konnectivity is described here https://github.com/kubernetes-sigs/apiserver-network-proxy#releases
ARG APISERVER_AGENT_VERSION=0.1.4

RUN git clone  -b v$APISERVER_AGENT_VERSION https://github.com/kubernetes-sigs/apiserver-network-proxy.git /go/src/sigs.k8s.io/apiserver-network-proxy 
# Copy in the go src
WORKDIR /go/src/sigs.k8s.io/apiserver-network-proxy/proxy-agent

# Build
ARG ARCH
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} go build -v -a -ldflags '-extldflags "-static"' -o proxy-agent sigs.k8s.io/apiserver-network-proxy/cmd/agent

# Copy the loader into a thin image
FROM gcr.io/distroless/static-debian11
WORKDIR /
COPY --from=builder /go/src/sigs.k8s.io/apiserver-network-proxy/proxy-agent .
ENTRYPOINT ["/proxy-agent"]