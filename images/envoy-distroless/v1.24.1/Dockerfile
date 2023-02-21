FROM docker.io/envoyproxy/envoy-distroless:v1.24.1 as binary

FROM gcr.io/distroless/base-debian11:nonroot

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
