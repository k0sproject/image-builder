FROM docker.io/envoyproxy/envoy-distroless:v1.29.3@sha256:3c8e339269db9fa842ad5b9942700a244197052f7c8b8adced36390f2b3a8860 as binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:1c99fceaba16f833d6eb030c07d6304bce68f18350e1a0c69a85b8781afc00d9

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
