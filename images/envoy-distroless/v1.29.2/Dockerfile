FROM docker.io/envoyproxy/envoy-distroless:v1.29.1@sha256:76dcbc0509d51001da1c94937b4498bd30ae6eb074d98863336c522311b19fa4 as binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:1a6f64f3fed75597fda0fa9cf8e60c3f6b029dedcef57071a2f42975a1b2bf8a

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
