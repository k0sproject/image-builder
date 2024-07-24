FROM docker.io/envoyproxy/envoy-distroless:v1.29.5@sha256:ec6fc9d7478f37569b6971943b6b993c6670710a492c70b9a55e44ffb2da41c1 as binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:53745e95f227cd66e8058d52f64efbbeb6c6af2c193e3c16981137e5083e6a32

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
