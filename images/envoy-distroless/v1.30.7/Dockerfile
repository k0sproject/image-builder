# docker buildx imagetools inspect docker.io/envoyproxy/envoy-distroless:v1.30.5
FROM docker.io/envoyproxy/envoy-distroless:v1.30.5@sha256:f9105acc862172b3e8e9d26db751580d121d04f77cdda1275ad0e85034e38a74 AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:a9899ccd9868bbd8913c67f6807410abecf766bc9e3c718eb6248f7b3dfb9819

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
