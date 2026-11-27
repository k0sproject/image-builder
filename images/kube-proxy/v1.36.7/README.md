# kube-proxy

This is k0s's [kube-proxy] image. It's an Alpine variant of what can be found in
the upstream [iptables-distroless] image, plus the `kube-proxy` executable. It
uses the new binary `iptables-wrapper`, so that it doesn't need a shell anymore.

Notes:

* This image overrides the vendored `golang.org/x/crypto` version. Kubernetes
  1.36 pins v0.47.0, which is flagged by CVE-2026-46595, CVE-2026-39830 through
  CVE-2026-39834 and CVE-2026-42508. Upstream bumped it only in the 1.37 line
  (`release-1.36` still carries v0.47.0 as of v1.36.3), so the Dockerfile raises
  the requirement in the root module and in every staging module that pins it,
  then re-vendors the workspace before building. The build asserts the override
  actually landed in `vendor/modules.txt`, so a silent failure breaks the build
  rather than shipping a vulnerable binary. Drop this once `release-1.36` picks
  up x/crypto v0.52.0 or newer.
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

[kube-proxy]: https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/
[iptables-distroless]: https://github.com/kubernetes/release/tree/master/images/build/distroless-iptables