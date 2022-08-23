# Issues for this repository are disabled

Issues for this repository are tracked in Red Hat Jira. Please head to <https://issues.redhat.com/browse/MAISTRA> in order to browse or open an issue.

# Dockerfiles for CentOS based images of Istio

Images are on [quay.io](https://quay.io/organization/maistra).

## Build
In order to build them locally, you can make use of the helper script `create-images.sh`, passing the desired tag:
```sh
./create-images.sh -t my-tag -b
# -t is the tag, -b stands for "build"
```
This will build all images locally with the name maistra/*COMPONENT*:my-tag and push them into quay.io/maistra/*COMPONENT*.

## Push
You can build and push the Maistra container images directly into a remote registry, using this following command:
```sh
./create-images.sh -h my-registry -t my-tag -p
# -h is the registry, -t is the tag, -p stands for "build and push"
```
This will build all images locally and push them into my-registry/*COMPONENT*:my-tag.

## Other features

- Remove (untag) the existing local stored container images  

```sh
./create-images.sh -h my-registry/my-repo -t my-tag -d
# it's possible to specify which images should be removed with -i "my-image1 my-image2"
# example: ./create-images.sh -h my-registry/my-repo -t my-tag -d -i "my-image1 my-image2"
```

**NB**: the parameter `-i` following by the images list is used **ONLY** for the untagging (`-d`)  

- Specify only the components which will be built and pushed  

```sh
./create-images.sh -h my-registry/my-repo -t my-tag -c "istio istio-operator" -p
```

**NB**: the parameter `-c` following by the components list is used **ONLY** for the build/push (`-b` or `-p`)  

- Build and push the bookinfo container images 

```sh
./create-images.sh -h my-registry/my-repo -t my-tag -k -p
# -h is the registry, -t is the tag, -k enables the bookinfo images build, -p stands for "build and push"
```

Execute `./create-images.sh` to see all the options.

## Versions

Versions are tracked in a branch for each release name. For example, the maistra-2.3 branch tracks the 2.3 release.
