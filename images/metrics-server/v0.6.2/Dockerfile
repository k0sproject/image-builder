FROM golang:1.17.13 as build

RUN mkdir -p /go/src/sigs.k8s.io/ && git clone -b v0.6.2 https://github.com/kubernetes-sigs/metrics-server.git /go/src/sigs.k8s.io/metrics-server

ENV GOPRIVATE=on

WORKDIR /go/src/sigs.k8s.io/metrics-server
RUN go get -u github.com/emicklei/go-restful@v2.16.0 && \
    go get -u github.com/prometheus/prometheus@v0.0.0-20210315130517-21a282fabecb && \
    go get -u golang.org/x/net@v0.4.0 && \
    go get -u gopkg.in/yaml.v3@v3.0.0-20220521103104-8f96da9f5d5e && \
    go mod download && make metrics-server

FROM gcr.io/distroless/static
COPY --from=build /go/src/sigs.k8s.io/metrics-server/metrics-server /
USER 65534
ENTRYPOINT ["/metrics-server"]
