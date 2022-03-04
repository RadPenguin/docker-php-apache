#!/bin/bash

REPO_NAME=radpenguin/php-apache
scriptStartTime=$( date +%s )

set -e -u

docker build --tag=$REPO_NAME .
docker push $REPO_NAME

scriptEndTime=$( date +%s )
echo "Completed build in "$((scriptEndTime-$scriptStartTime))" seconds"
