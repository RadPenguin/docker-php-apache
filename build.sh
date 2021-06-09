#!/bin/bash

REPO_NAME=radpenguin/php-apache
BUILD_DATE=$(date +"%Y-%m-%d-%H-%M-%S")
VERSION=1.0.0

options=
if [[ -z "$1" ]]; then
  options="--no-cache \
  --build-arg=BUILD_DATE=\"$BUILD_DATE\" \
  --build-arg=VERSION=\"$VERSION\""

  echo "Building release version"
else
  echo "Building non-release version"
fi
sleep 2

set -e -u

docker build \
  $options \
  --tag=$REPO_NAME \
  .
docker push $REPO_NAME
