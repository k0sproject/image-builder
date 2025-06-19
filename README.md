# Image Builder

This repo contains the Dockerfiles and GitHub actions for building the images used in [k0s](https://github.com/k0sproject/k0s).

## Semi automated image bumps

Whenever we an image bump we always commit first the previous version for easier comparisson.
In order to do the process more automatic, you can use `bump-images.sh`. For instance, if you
wanted to bump kube-proxy from 1.32.5 to 1.32.6 and from 1.33.1 to 1.33.2 you could run:

```shell
./bump-images.sh kube-proxy v1.32.5 v1.32.6 v1.33.1 v1.33.2
```

This will create a commit with a copy of the previous version, commit it, replace the version
in the new files and make a commit which must be manually validated.

Calico is a special case because it's made of three different images, if the image name is calico,
the script will do it for calico-cni, calico-kube-controllers and calico-node:

```shell
./bump-images.sh calico v3.28.2-0 v3.28.4-0 v3.29.3-1 v3.29.4-0
````