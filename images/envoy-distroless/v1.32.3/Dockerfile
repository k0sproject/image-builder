FROM docker.io/envoyproxy/envoy-distroless:v1.32.2@sha256:11de2e75de4dce39e38ff8da8077096ba9f6f784d6f6866a663fe8d2c809227e AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:6d4a4f40e93615df1677463ca56456379cc3a4e2359308c9e72bc60ffc4a12a9

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
