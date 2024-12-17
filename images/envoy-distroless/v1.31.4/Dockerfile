FROM docker.io/envoyproxy/envoy-distroless:v1.31.4@sha256:5558a8554a218daf2f2ae2ad27148c83c7f9d551dd94a00c42d61d0f1f507ea1 AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:6d4a4f40e93615df1677463ca56456379cc3a4e2359308c9e72bc60ffc4a12a9

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
