FROM docker.io/envoyproxy/envoy-distroless:v1.30.1@sha256:645582c5e845940c11b61d6203d1ded5095e3908b23c39a53450fc9940cc4989 as binary

FROM gcr.io/distroless/base-debian12:nonroot@sha256:1c99fceaba16f833d6eb030c07d6304bce68f18350e1a0c69a85b8781afc00d9

COPY --from=binary /usr/local/bin/envoy* /usr/local/bin/
COPY --from=binary /etc/envoy/envoy.yaml /etc/envoy/envoy.yaml

ENTRYPOINT ["/usr/local/bin/envoy"]
CMD ["-c", "/etc/envoy/envoy.yaml"]
