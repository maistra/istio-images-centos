#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

: "${MAISTRA_VERSION:=2.2}"

: "${MAISTRA_PROJECT:=https://github.com/maistra}"

: "${HUB:=quay.io/maistra}"
: "${TAG:="${MAISTRA_VERSION}"}"

: "${ISTIO_REPO:="${MAISTRA_PROJECT}/istio.git"}"
: "${ISTIO_BRANCH:="maistra-${MAISTRA_VERSION}"}"

: "${REPOSDIR:="${DIR}/tmp"}"

: "${RM:=rm}"
: "${MAKE:=make}"
: "${GIT:=git}"
: "${CONTAINER_CLI:=docker}"

MAISTRA_DEFAULT_COMPONENTS=(
  "istio"
  "istio-operator"
  "istio-must-gather"
  "ratelimit"
  "prometheus"
)

COMPONENTS="${MAISTRA_COMPONENTS:-${MAISTRA_DEFAULT_COMPONENTS[@]}}"

DEFAULT_IMAGES=(
  "pilot"
  "proxyv2"
  "istio-cni"
  "istio-operator" 
  "istio-must-gather"
  "ratelimit"
  "prometheus"
)

IMAGES="${ISTIO_IMAGES:-${DEFAULT_IMAGES[@]}}"

function verify_podman() {
  [ "${EUID}" == "0" ] && return

  if [ "${CONTAINER_CLI}" = "podman" ] || ([ "${CONTAINER_CLI}" = "docker" ] && docker --version | grep -q podman) ; then
    echo "****************************************************************************************"
    echo
    echo "You are using podman in rootless mode. Some images may not work in this mode. Aborting."
    echo
    echo "****************************************************************************************"
    exit 1
  fi
}

function usage() {
	[[ -n "${1}" ]] && echo "${1}"

	cat <<EOF
Usage: ${BASH_SOURCE[0]} [options ...]"
	options:
		-t <TAG>    TAG to use for operations on images. Defaults to "${TAG}". Special tag 'DAILY' will be replaced with today's date in the format ${MAISTRA_VERSION}-yyy-mm-dd
		-h <HUB>    Docker hub + username. Defaults to "${HUB}"
		-c <COMPONENTS> Specify which Maistra components should be built
		-i <IMAGES> Specify which images should be deleted
		-b          Build locally images
		-d          Delete images
		-p          Build and push images
		-k          Handle bookinfo images in addition to others

At least one of -b, -d or -p is required.

Environment Variables:
  - MAISTRA_COMPONENTS: Specify which Maistra components should be built/pushed (CLI flag -c takes precedence). Default: "${MAISTRA_DEFAULT_COMPONENTS[@]}"
  - ISTIO_IMAGES: Specify which images should be deleted (CLI flag -i takes precedence). Default: "${DEFAULT_IMAGES[@]}"
  - ISTIO_REPO: Istio repository URL to clone, when building bookinfo images. Default: ${ISTIO_REPO}
  - ISTIO_BRANCH: Istio repository branch to clone, when building bookinfo images. Default: ${ISTIO_BRANCH}

EOF
exit 2
}

function suffix() {
  if [ "${1}" == "istio-must-gather" ]; then
    return
  fi

  echo "-ubi8"
}

function get_image_name() {
  local image="${1}"

  case ${image} in
    "istio-operator")
      echo "${HUB}/istio-ubi8-operator:${TAG}"
      ;;
    "ratelimit")
      echo "${HUB}/${image}$(suffix "${image}")"
      ;;
    *)
      echo "${HUB}/${image}$(suffix "${image}"):${TAG}"
      ;;
  esac
}

function build_bookinfo() {
  local dir

  dir="$(mktemp -d)"
  ${GIT} clone --depth=1 -b "${ISTIO_BRANCH}" "${ISTIO_REPO}" "${dir}"

  local src="${dir}/samples/bookinfo/src"

  pushd "${src}/productpage"
    ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-productpage-v1:${TAG}" .
  popd

  pushd "${src}/details"
    #plain build -- no calling external book service to fetch topics
    ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-details-v1:${TAG}" --build-arg service_version=v1 .
    #with calling external book service to fetch topic for the book
    ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-details-v2:${TAG}" --build-arg service_version=v2 --build-arg enable_external_book_service=true .
  popd

  pushd "${src}/reviews"
    #java build the app.
    ${CONTAINER_CLI} run --rm -v "$(pwd)":/home/gradle/project -w /home/gradle/project gradle:4.8.1 gradle clean build
    pushd reviews-wlpcfg
      #plain build -- no ratings
      ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-reviews-v1:${TAG}" --build-arg service_version=v1 .
      #with ratings black stars
      ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-reviews-v2:${TAG}" --build-arg service_version=v2 --build-arg enable_ratings=true .
      #with ratings red stars
      ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-reviews-v3:${TAG}" --build-arg service_version=v3 --build-arg enable_ratings=true --build-arg star_color=red .
    popd
  popd

  pushd "${src}/ratings"
    ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-ratings-v1:${TAG}" --build-arg service_version=v1 .
    ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-ratings-v2:${TAG}" --build-arg service_version=v2 .
    ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-ratings-v-faulty:${TAG}" --build-arg service_version=v-faulty .
    ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-ratings-v-delayed:${TAG}" --build-arg service_version=v-delayed .
    ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-ratings-v-unavailable:${TAG}" --build-arg service_version=v-unavailable .
    ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-ratings-v-unhealthy:${TAG}" --build-arg service_version=v-unhealthy .
  popd

  pushd "${src}/mysql"
    ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-mysqldb:${TAG}" .
  popd

  pushd "${src}/mongodb"
    ${CONTAINER_CLI} build -t "${HUB}/examples-bookinfo-mongodb:${TAG}" .
  popd

  rm -rf "${dir}"
}

function exec_bookinfo_images() {
  local cmd="${1}"
  local images
  local image

  images="$(${CONTAINER_CLI} images --format "{{.Repository}}:{{.Tag}}" | grep -E "examples-bookinfo.*$TAG")"

  echo "$images"
  for image in ${images}; do
    ${CONTAINER_CLI} "${cmd}" "${image}"
  done
}

function get_repo() {
  if [ $# -ne 1 ]; then
    echo "Usage: get_repo REPOSITORY_NAME"
    exit 1
  fi
  local repo_name=$1
  ${GIT} clone "${MAISTRA_PROJECT}/${repo_name}"
}

function exec_build() {
  if [ $# -ne 2 ]; then
    echo "ERROR"
    echo "Usage: exec_build COMPONENT_NAME build|push"
    exit 1
  fi

  if [ "$2" != "build" ] && [ "$2" != "push" ]; then
    echo "ERROR"
    echo "Usage: exec_build COMPONENT_NAME build|push"
    exit 1
  fi

  local component=$1

  local push=false
  if [ "$2" == "push" ]; then
    push=true
  fi

  local image
  image="$(get_image_name "${component}")"
  case ${component} in
    "istio"|"maistra-istio"|"istio-maistra") #Possibility to test with other Maistra Istio names (ex: forked repos)
      ${GIT} checkout ${ISTIO_BRANCH}

      make_target="maistra-image"
      if ${push}; then
        make_target="maistra-image.push"
      fi
      make_vars=("HUB=${HUB}" "TAG=${TAG}")
      ;;
    "istio-must-gather")
      #TODO: delete this sed when podman will be a variable (cf. https://github.com/maistra/istio-must-gather/blob/maistra-2.2/Makefile#L23-L27)
      sed -i -e "s/podman/${CONTAINER_CLI}/g" "${REPOSDIR}/${component}/Makefile"

      make_target="image"
      if ${push}; then
        make_target="push"
      fi
      make_vars=("HUB=${HUB}" "TAG=${TAG}")
      ;;
    "istio-operator")
      echo "${REPOSDIR}/${component} - ${MAKE} IMAGE=${image} image"
      ${MAKE} IMAGE="${image}" image
      if ${push}; then
        ${CONTAINER_CLI} push "${image}"
      fi
      ;;
    "ratelimit")
      ${GIT} checkout ${ISTIO_BRANCH}
      make_target="docker_image_without_tests"
      if ${push}; then
        make_target="docker_push_without_tests"
      fi
      make_vars=("IMAGE=${image}" "VERSION=${TAG}")
      ;;
    "prometheus")
      cp "${DIR}/Dockerfile.prometheus" "${REPOSDIR}/${component}/Dockerfile.maistra"
      ${CONTAINER_CLI} build "${REPOSDIR}/${component}" -f Dockerfile.maistra -t "${image}"
      if ${push}; then
        ${CONTAINER_CLI} push "${image}"
      fi
      ;;
    *)
      echo "${component} is not in the maistra components list"
      ;;
  esac

  #Istio-operator and Prometheus builds are specific
  if [ "${component}" != "prometheus" ] && [ "${component}" != "istio-operator" ]; then
    ${MAKE} "${make_vars[@]}" ${make_target}
  fi
}

## MAIN
while getopts ":t:h:i:c:bdpk" opt; do
	case ${opt} in
		t) TAG="${OPTARG}";;
		h) HUB="${OPTARG}";;
		b) BUILD=true;;
		d) DELETE=true;;
		p) PUSH=true;;
		c) COMPONENTS="${OPTARG}";;
		i) IMAGES="${OPTARG}";;
		k) BOOKINFO=true;;
		*) usage;;
	esac
done

[[ -z "${TAG}" ]] && usage "Missing TAG"
[[ -z "${BUILD}" && -z "${DELETE}" && -z "${PUSH}" ]] && usage

if [ "${TAG}" == "DAILY" ]; then
  TAG="${MAISTRA_VERSION}-$(date +%Y-%m-%d)"
fi

verify_podman

if [ -n "${DELETE}" ]; then
	for image in ${IMAGES}; do
		echo "Deleting image ${image}..."
    if [ "${image}" == "ratelimit" ]; then
      image_name="$(get_image_name "$image"):${TAG}"
    else
      image_name="$(get_image_name "$image")"
    fi
		${CONTAINER_CLI} rmi "${image_name}"
	done

	if [ -n "${BOOKINFO}" ]; then
	  exec_bookinfo_images rmi
	fi
fi

if [ -n "${BUILD}" ] || [ -n "${PUSH}" ]; then
  [ ! -d "${REPOSDIR}" ] && mkdir "${REPOSDIR}"
  trap 'echo "Removing ${REPOSDIR}" && ${RM} -rf "${REPOSDIR}"' EXIT
  
  cd "${REPOSDIR}"

  for component in ${COMPONENTS}; do
    echo "[${component}] Clone the git repository "
    get_repo "${component}"

    cd "${REPOSDIR}/${component}"
    if [ -n "${BUILD}" ]; then
      echo "[${component}] Execute the container image build"
      exec_build "${component}" "build"
    fi
    if [ -n "${PUSH}" ]; then
      echo "[${component}] Execute the build and push container image build"
      exec_build "${component}" "push"
    fi
    cd "${REPOSDIR}/"
    echo "Done"
    echo
  done

  if [ -n "${BOOKINFO}" ]; then
    build_bookinfo
    if [ -n "${PUSH}" ]; then
      exec_bookinfo_images push
    fi
  fi
fi