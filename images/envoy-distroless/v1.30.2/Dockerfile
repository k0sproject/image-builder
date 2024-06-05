FROM docker.io/envoyproxy/envoy-distroless:v1.30.2@sha256:5fe272f80c4f3b4d19d46fc376623dbb8bc6f08d3f39ac8e597e60f688ae644a as binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:53745e95f227cd66e8058d52f64efbbeb6c6af2c193e3c16981137e5083e6a32

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
