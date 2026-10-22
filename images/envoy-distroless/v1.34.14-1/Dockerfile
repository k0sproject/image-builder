FROM docker.io/envoyproxy/envoy:distroless-v1.34.14@sha256:07a8768c865210cd94a2f4e77a1c249c2e5c9a783a32a65cdfe6f20a057bc264 AS binary

FROM gcr.io/distroless/base-debian13:nonroot@sha256:6c591b4ac789b683ab3665327181e7cfb7a39b5834f42dcb73d7becb8d18a5d9
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/envoyproxy/envoy"

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
