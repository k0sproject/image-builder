FROM docker.io/envoyproxy/envoy-distroless:v1.29.11@sha256:b37caf73d76e0c95f7cfff839d274afde752e52f7ae57628a60ff439be96d135 AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:6d4a4f40e93615df1677463ca56456379cc3a4e2359308c9e72bc60ffc4a12a9

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
