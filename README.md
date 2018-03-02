# Dockerfiles for CentOS based images of Istio

Images are on [Docker Hub](https://hub.docker.com/u/openshiftistio/).

## Building
In order to build them locally, you can make use of the helper script `create-images.sh`, passing the desired tag:
```sh
./create-images.sh -t my-tag -b
# -t is the tag, -b stands for "build"
```
This will build all images locally with the name openshiftistio/*COMPONENT*-centos7:my-tag.

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

### Master
`master` branch of this repository tracks the master branch of Istio. It's supposed to generate images frequently, on top of the latest and greatest Istio.
It uses the [Istio-daily](https://copr.fedorainfracloud.org/coprs/g/openshift-istio/istio-daily/) COPR repository in order to have the latest, ***unreleased*** Istio.

Images on [Docker Hub](https://hub.docker.com/u/openshiftistio/) with the tag `latest` are based on this branch.

### Released, stable versions
The branch `stable` tracks released versions of Istio, and is not updated frequently as master.
It uses the [Istio](https://copr.fedorainfracloud.org/coprs/g/openshift-istio/istio/) COPR repository in order to have the latest ***stable*** Istio.
