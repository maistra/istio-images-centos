#!/bin/bash

set -e

function usage() {
	[[ -n "${1}" ]] && echo "${1}"

	cat <<EOF
Usage: ${BASH_SOURCE[0]} [options ...]"
	options:
		-t <TAG>  TAG to use for operations on images, required.
		-h <HUB>  Docker hub + username. Defaults to "docker.io/maistra"
		-i <IMAGES> Specify which images should be built
		-b        Build images
		-d        Delete images
		-p        Push images

At least one of -b, -d or -p is required.
EOF
exit 2
}

function suffix() {
  if [ "${1}" = "istio-must-gather" -o "${1}" = "proxy-init-centos7" ]; then
    return
  fi

  echo "-ubi8"
}

HUB="docker.io/maistra"
DEFAULT_IMAGES="citadel pilot mixer sidecar-injector galley istio-ior proxy-init proxy-init-centos7 proxyv2 istio-must-gather"
IMAGES=${ISTIO_IMAGES:-$DEFAULT_IMAGES}


CONTAINER_CLI=${CONTAINER_CLI:-docker}

while getopts ":t:h:i:bdp" opt; do
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
		${CONTAINER_CLI} rmi ${HUB}/${image}$(suffix ${image}):${TAG}
	done
fi

if [ -n "${BUILD}" ]; then
	for image in ${IMAGES}; do
		echo "Building ${image}..."
		${CONTAINER_CLI} build --no-cache -t ${HUB}/${image}$(suffix ${image}):${TAG} -f Dockerfile.${image} .
		echo "Done"
		echo
	done
fi

if [ -n "${PUSH}" ]; then
	for image in ${IMAGES}; do
		echo "Pushing image ${image}..."
		${CONTAINER_CLI} push ${HUB}/${image}$(suffix ${image}):${TAG}
	done
fi
