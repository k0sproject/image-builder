FROM docker.io/library/golang:1.26.2-alpine3.23 AS builder

RUN apk add git make curl

RUN git clone -b v1.4.0 https://github.com/dinumathai/pushgateway.git

WORKDIR pushgateway

ADD patches/*.patch .

# Apply patches, mainly to update Go dependencies
RUN for patch in *.patch; do \
        echo "Applying $patch"; \
        git apply "$patch"; \
    done

RUN go mod tidy && go mod vendor && \
    make common-build PROMU_VERSION=0.18.0

FROM scratch

COPY --from=builder /go/pushgateway/pushgateway /bin/pushgateway

USER 65534

ENTRYPOINT [ "/bin/pushgateway" ]
