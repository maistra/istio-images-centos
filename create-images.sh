#!/bin/bash

if [ -z "${TAG}" ]; then
  echo "Missing \$TAG variable"
  echo "Run example: TAG=1.0 ./create-images"
  exit 1
fi

for image in istio-ca pilot mixer sidecar-injector proxy-init; do
  echo "Building ${image}..."
  docker build -t openshiftistio/${image}-centos7:${TAG} -f Dockerfile.${image} .
  echo "Done"
  echo
done
