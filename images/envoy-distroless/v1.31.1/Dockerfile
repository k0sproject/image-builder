# docker buildx imagetools inspect docker.io/envoyproxy/envoy-distroless:v1.31.1
FROM docker.io/envoyproxy/envoy-distroless:v1.31.1@sha256:524d924ef45e78a1bb6041c9f775af307904d008dc9d255c633f810f19a8f7bd AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:a9899ccd9868bbd8913c67f6807410abecf766bc9e3c718eb6248f7b3dfb9819

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
