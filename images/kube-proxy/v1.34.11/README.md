# kube-proxy

This is k0s's [kube-proxy] image. It's an Alpine variant of what can be found in
the upstream [iptables-distroless] image, plus the `kube-proxy` executable. It
uses the new binary `iptables-wrapper`, so that it doesn't need a shell anymore.

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

[kube-proxy]: https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/
[iptables-distroless]: https://github.com/kubernetes/release/tree/master/images/build/distroless-iptables