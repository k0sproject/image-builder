FROM docker.io/envoyproxy/envoy:distroless-v1.37.0@sha256:92fdb97b9fdb47da82fbe3651b83bd1419e544966d264632af4864004652685f AS binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:748987b77724fc1a9cf1acc8afb7f2cecff8cd91f24f43423647f1896eb7262f
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/envoyproxy/envoy"

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
