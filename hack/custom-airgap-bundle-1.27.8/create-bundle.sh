#!/bin/sh

cat airgap-images-list.txt | xargs -I{} docker pull {}

docker image save $(cat airgap-images-list.txt | xargs) -o k0s-custom-airgap-1.27.8.tar
