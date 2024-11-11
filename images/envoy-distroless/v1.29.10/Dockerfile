# docker buildx imagetools inspect docker.io/envoyproxy/envoy-distroless:v1.29.8
FROM docker.io/envoyproxy/envoy-distroless:v1.29.8@sha256:000962566ef908117897e939c4b76add266e277c2b740965d881d08faf52b86e AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:a9899ccd9868bbd8913c67f6807410abecf766bc9e3c718eb6248f7b3dfb9819

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
