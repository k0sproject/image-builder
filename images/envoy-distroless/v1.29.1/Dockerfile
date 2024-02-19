FROM docker.io/envoyproxy/envoy-distroless:v1.29.0@sha256:ac2ddb6a48d5325c05eda97834cf84e0889dc1ba2eddb1c0bd297ac22cfbbff3 as binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:684dee415923cb150793530f7997c96b3cef006c868738a2728597773cf27359

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
