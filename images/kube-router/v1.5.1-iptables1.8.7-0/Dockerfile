FROM docker.io/cloudnativelabs/kube-router:v1.5.1 as binaries

FROM golang:1.19-alpine as build

RUN apk add --no-cache git

RUN git clone -b v2.34.0 https://github.com/osrg/gobgp.git /gobgp

RUN cd /gobgp && go get -u golang.org/x/net@v0.7.0 && \
    go mod tidy && \
    CGO_ENABLED=0 go build -o /usr/local/bin/gobgp /gobgp/cmd/gobgp

RUN git clone -b v1.5.1 https://github.com/cloudnativelabs/kube-router.git /kube-router

RUN cd /kube-router && \
    export GIT_COMMIT=$(git describe --tags --dirty) && \
    export BUILD_DATE="2022-07-29T22:25:37+0000" && \
    go get -u golang.org/x/net@v0.7.0 && \
    go mod tidy && \
    CGO_ENABLED=0 go build -ldflags "-X github.com/cloudnativelabs/kube-router/pkg/version.Version=$GIT_COMMIT -X github.com/cloudnativelabs/kube-router/pkg/version.BuildDate=$BUILD_DATE" \
     -o /usr/local/bin/kube-router /kube-router/cmd/kube-router


FROM alpine:3.15

RUN apk add --no-cache \
      'iptables=1.8.7-r1' \
      'ip6tables=1.8.7-r1' \
      ipset \
      iproute2 \
      ipvsadm \
      conntrack-tools \
      curl \
      bash && \
    mkdir -p /var/lib/gobgp

COPY --from=build /usr/local/bin/kube-router /usr/local/bin/
COPY --from=build /usr/local/bin/gobgp /usr/local/bin/
COPY --from=binaries /etc/motd-kube-router.sh /etc/motd-kube-router.sh

RUN wget -O /iptables-wrapper-installer.sh https://raw.githubusercontent.com/cloudnativelabs/kube-router/v1.5.1/build/image-assets/iptables-wrapper-installer.sh && \
    chmod +x /iptables-wrapper-installer.sh && \
    /iptables-wrapper-installer.sh --no-sanity-check

RUN echo "hosts: files dns" > /etc/nsswitch.conf

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/kube-router"]
