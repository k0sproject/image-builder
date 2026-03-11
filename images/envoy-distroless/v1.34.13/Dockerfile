FROM docker.io/envoyproxy/envoy:distroless-v1.34.13@sha256:a21f5ca65573184017bd65be169e1521a8717ce980e8ecb7338085df0d09549c AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:8b9f2e503e55aff85b79d6b22c7a63a65170e8698ae80de680e3f5ea600977bf
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/envoyproxy/envoy"

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
