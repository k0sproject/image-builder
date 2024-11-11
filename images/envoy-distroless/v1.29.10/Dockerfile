FROM docker.io/envoyproxy/envoy-distroless:v1.29.10@sha256:280fba1031c6610e3509cff146d9b10dfc78f83b79760248e5615580a571c5fc AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:c3584d9160af7bbc6a0a6089dc954d0938bb7f755465bb4ef4265aad0221343e

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
