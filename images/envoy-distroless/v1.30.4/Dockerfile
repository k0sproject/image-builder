FROM docker.io/envoyproxy/envoy-distroless:v1.30.4@sha256:10040cc5e1d97f6b9aa51ab9538f9c2961b8aa2647d8453dcb3c6c09ae424f18 AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:a9899ccd9868bbd8913c67f6807410abecf766bc9e3c718eb6248f7b3dfb9819

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
