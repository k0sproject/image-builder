# Calico kube-proxy

This contains a HostProcess container for kube-proxy that works with Calico.  It uses the release files from Calico. The felix and node services scripts are modified slightly until we can get the support in upstream which has other dependencies.

This is coming from [sig-windows-tools](https://github.com/kubernetes-sigs/sig-windows-tools/tree/5f77809/hostprocess/calico) for details on installing Calico
