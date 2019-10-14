#!/bin/bash

set -e -u

REPO_NAME=radpenguin/php-apache
BUILD_DATE=$( date +"%Y-%m-%d-%H-%M-%S" )
VERSION=1.0.0

docker build \
  --build-arg=BUILD_DATE="$BUILD_DATE" \
  --build-arg=VERSION="$VERSION" \
  --tag=$REPO_NAME \
  .

docker push $REPO_NAME
