#!/bin/bash

function init() {
  MAISTRA_BRANCH=${MAISTRA_BRANCH:-$(git rev-parse --abbrev-ref HEAD 2> /dev/null)}
  if [ -z "${MAISTRA_BRANCH}" ]; then
    echo "Could not guess what branch to look for. Set MAISTRA_BRANCH variable."
    exit 1
  fi
  echo "Using Maistra branch ${MAISTRA_BRANCH}"

  ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

function update_must_gather() {
  echo "Updating must-gather..."

  local url="https://raw.githubusercontent.com/maistra/istio-must-gather/${MAISTRA_BRANCH}/gather_istio.sh"
  local file="${ROOTDIR}/artifacts/gather_istio"
  curl -Lsf "${url}" -o "${file}" || {
    echo "Failed to download artifact ${url}"
    exit 1
  }

  chmod +x "${file}"
  echo "Done"
}

function update_istio() {
  # TODO
  return
}

function main() {
  init
  update_istio
  update_must_gather
}

main