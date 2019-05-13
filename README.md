# Dockerfiles for CentOS based images of Istio

Images are on [Docker Hub](https://hub.docker.com/u/maistra/).

## Building
In order to build them locally, you can make use of the helper script `create-images.sh`, passing the desired tag:
```sh
./create-images.sh -t my-tag -b
# -t is the tag, -b stands for "build"
```
This will build all images locally with the name openshiftistio/*COMPONENT*:my-tag.

If you don't want to follow this naming, you can always build them individually, for example:
```sh
docker build -t my-pilot:my-tag -f Dockerfile.pilot .
```

## Helper script
`create-images.sh` is able to do more than just, say, creating images. It supports removal (untagging), building and pushing of images.

Example: if you want to build local images (`-b`) but want do remove (untag) previously existing local images (`-d`) first, and after building, you want to push (`-p`) them, run:
```sh
./create-images.sh -t my-tag -b -d -p
```
Run `./create-images.sh` to see all the options.

## Versions

Versions are tracked in a branch for each release name. For example, the Maistra 0.11 release tracks the maistra-0.11 branch.
