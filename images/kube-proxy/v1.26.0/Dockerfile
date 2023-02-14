FROM registry.k8s.io/kube-proxy:v1.26.0 as binary

FROM gcr.io/distroless/base-debian11

COPY --from=binary /usr/local/bin/kube-proxy /usr/local/bin/kube-proxy

ENTRYPOINT ["/usr/local/bin/kube-proxy"]

