FROM docker.io/envoyproxy/envoy-distroless:v1.29.2@sha256:9f0101d0429a123aeca1369b860559517e0f889b01c1795bc927c9befd60b2b5 as binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:3d46a42c741d469811b95d0b6ec9d10c15ebb1be7c5eaa989d429d91b066d78c

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
