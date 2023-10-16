FROM docker.io/envoyproxy/envoy-distroless:v1.27.1@sha256:a322e12b2c920169c24a8a98181f195b1511509df2394089423f1bbaaa005945 as binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:612a5cf1623f0385abb5a580905cf0bfdc836839f53987787e7def5d7f80afd7

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
