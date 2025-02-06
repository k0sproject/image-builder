FROM docker.io/envoyproxy/envoy-distroless:v1.29.12@sha256:23b8962edd99e87c7dc39eabd8e4bd9dfb07463bed3eb7e842db786c60f82264 AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:97d15218016debb9b6700a8c1c26893d3291a469852ace8d8f7d15b2f156920f

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
