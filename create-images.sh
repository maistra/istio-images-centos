#!/bin/bash

function usage() {
  [[ -n "${1}" ]] && echo "${1}"

  cat <<EOF
Usage: ${BASH_SOURCE[0]} [options ...]"
  options:
    -t <TAG>    TAG to use for operations on images, required.
    -h <HUB>    Docker hub + username. Defaults to "docker.io/maistra"
    -i <IMAGES> Specify which images should be built
    -b          Build images
    -d          Delete images
    -p          Push images

At least one of -b, -d or -p is required.
EOF
  exit 2
}

HUB="docker.io/maistra"
DEFAULT_IMAGES="citadel pilot mixer sidecar-injector proxy-init galley istio-operator proxyv2"
IMAGES=${ISTIO_IMAGES:-$DEFAULT_IMAGES}

while getopts ":t:h:bdp" opt; do
  case ${opt} in
    t) TAG="${OPTARG}";;
    h) HUB="${OPTARG}";;
    b) BUILD=true;;
    d) DELETE=true;;
    p) PUSH=true;;
    i) IMAGES="${OPTARG}";;
    *) usage;;
  esac
done

[[ -z "${TAG}" ]] && usage "Missing TAG"
[[ -z "${BUILD}" && -z "${DELETE}" && -z "${PUSH}" ]] && usage


if [ -n "${DELETE}" ]; then
  for image in ${IMAGES}; do
    echo "Deleting image ${image}..."
    docker rmi ${HUB}/${image}-centos7:${TAG}
  done
fi

if [ -n "${BUILD}" ]; then
  for image in ${IMAGES}; do
    echo "Building ${image}..."
    docker build --no-cache -t ${HUB}/${image}-centos7:${TAG} -f Dockerfile.${image} .
    echo "Done"
    echo
  done
fi

if [ -n "${PUSH}" ]; then
  for image in ${IMAGES}; do
    echo "Pushing image ${image}..."
    docker push ${HUB}/${image}-centos7:${TAG}
  done
fi
