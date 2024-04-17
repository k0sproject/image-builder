# kube-proxy image

Build process is mostly copied from the upstream:

https://github.com/kubernetes/release/tree/master/images/build/distroless-iptables/distroless

## False positive security vulnerabilities

The following CVEs are flagged by trivy and do not affect the `kube-proxy`
binary:

* [CVE-2023-2253]  
  <https://github.com/kubernetes/kubernetes/pull/118036>  
  > k/k doesn't use much code from docker/distribution so this doesn't change
  > anything that's actually relevant, [...]

* [CVE-2023-45142]  
  <https://github.com/kubernetes/kubernetes/pull/121559#issuecomment-1782870871>  
  > [...] kubernetes is NOT affected and we will not accept this cherry pick as
  > it really does not do anything w.r.t security.

* [CVE-2023-47108]  
  <https://github.com/kubernetes/kubernetes/pull/121842>  
  > This DOES NOT impact kubernetes, as we use OpenTelemetry only for tracing,
  > and not for metrics. `go.opentelemetry.io/otel/sdk/metric` is not a
  > dependency of this project.

* [CVE-2024-21626]  
  <https://github.com/kubernetes/kubernetes/pull/123060>  
  > Kubernetes uses `runc` for some aspects of kubelet, however we are NOT
  > affected directly by the CVE-2024-21626 mentioned in the release notes for
  > v1.1.12 directly (You do NOT need a new version of `kubelet`!).

[CVE-2023-2253]:  https://avd.aquasec.com/nvd/cve-2023-2253
[CVE-2023-45142]: https://avd.aquasec.com/nvd/cve-2023-45142
[CVE-2023-47108]: https://avd.aquasec.com/nvd/cve-2023-47108
[CVE-2024-21626]: https://avd.aquasec.com/nvd/cve-2024-21626
