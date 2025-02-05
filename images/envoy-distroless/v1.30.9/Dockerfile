FROM docker.io/envoyproxy/envoy-distroless:v1.30.8@sha256:184d9267cb35a34d3d64b685dc06b279d8efaafda43ce9a5822c7ff19c26dfc1 AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:6d4a4f40e93615df1677463ca56456379cc3a4e2359308c9e72bc60ffc4a12a9

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
