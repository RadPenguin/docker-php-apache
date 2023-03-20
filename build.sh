#!/bin/bash

IMAGE_TAG=${IMAGE_TAG:-latest}
PHP_VERSION=${PHP_VERSION:-8.1}
REPO_NAME=taeram/php-apache
XDEBUG_VERSION=${XDEBUG_VERSION:-}

if [[ "$PHP_VERSION" = "7.4" ]]; then
  XDEBUG_VERSION="-3.1.5"
  IMAGE_TAG=php-7.4
fi

FROM_IMAGE=php:${PHP_VERSION}-apache

scriptStartTime=$( date +%s )

set -e -u

docker login
docker build \
  --build-arg FROM_IMAGE="$FROM_IMAGE" \
  --build-arg XDEBUG_VERSION="$XDEBUG_VERSION" \
  --tag=$REPO_NAME:$IMAGE_TAG \
  .
docker push $REPO_NAME:$IMAGE_TAG

scriptEndTime=$( date +%s )
echo "Completed build in "$((scriptEndTime-$scriptStartTime))" seconds"
