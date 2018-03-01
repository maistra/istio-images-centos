# Dockerfiles for CentOS based images of Istio

Images are on [Docker Hub](https://hub.docker.com/u/openshiftistio/).

## Building
In order to build them locally, you can make use of the helper script `create-images.sh`, passing the desired tag:
```sh
TAG=my-tag ./create-images.sh
```
This will build all images locally with the name openshiftistio/*COMPONENT*-centos7:my-tag.

If you don't want to follow this naming, you can always build them individually, for example:
```sh
docker build -t my-pilot:my-tag -f Dockerfile.pilot .
```