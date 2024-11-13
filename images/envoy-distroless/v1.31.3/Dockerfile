FROM docker.io/envoyproxy/envoy-distroless:v1.31.3@sha256:8a3f187987ffb8488f0ca1a07e5e0a9ae191733436713c5890bc18a4e67dece9 AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:c3584d9160af7bbc6a0a6089dc954d0938bb7f755465bb4ef4265aad0221343e

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
