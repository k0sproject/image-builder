# kube-proxy

This is k0s's [kube-proxy] image. It's an Alpine variant of what can be found in
the upstream [iptables-distroless] image, plus the `kube-proxy` executable. It
uses the new binary `iptables-wrapper`, so that it doesn't need a shell anymore.

## False positive security vulnerabilities

The following CVEs are flagged by trivy and do not affect the `kube-proxy`
binary:

* [CVE-2023-47108]  
  <https://github.com/kubernetes/kubernetes/pull/121842>  
  > This DOES NOT impact kubernetes, as we use OpenTelemetry only for tracing,
  > and not for metrics. `go.opentelemetry.io/otel/sdk/metric` is not a
  > dependency of this project.
* [CVE-2024-45310]  
  This is a runc vulnerability regarding container execution. Kube-proxy is not
  concerned with container management at all.

Notes:

* Alpine's `kmod` package depends on `/bin/sh` for its trigger scripts run at
  package installation. Hence `apk` refuses to purge `busybox`. Have a little
  nasty hack in place that fiddles with Alpine's package database to remove that
  dependency after installation, so that `busybox`, and hence the shell, can be
  purged.
* Include the `alpine-release` package, so that the image has a proper
  `/etc/os-release` file. This enables the security scanning of the Alpine
  packages. As that package depends on `alpine-keys`, which is not required
  here, pull the same trick as for the `kmod` package and remove that dependency
  as well.
* Kube-Proxy's [nftables backend] ([KEP-3866]) needs the `nft` binary, which is
  not yet part of this image.

[kube-proxy]: https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/
[iptables-distroless]: https://github.com/kubernetes/release/tree/master/images/build/distroless-iptables/distroless
[CVE-2023-47108]: https://avd.aquasec.com/nvd/cve-2023-47108
[CVE-2024-45310]: https://avd.aquasec.com/nvd/cve-2024-45310
[nftables backend]: https://github.com/kubernetes/enhancements/issues/3866
[KEP-3866]: https://github.com/kubernetes/enhancements/blob/master/keps/sig-network/3866-nftables-proxy/README.md
