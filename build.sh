#!/bin/bash

REPO_NAME=taeram/php-apache
scriptStartTime=$( date +%s )

set -e -u

docker login
docker build --tag=$REPO_NAME .
docker push $REPO_NAME

scriptEndTime=$( date +%s )
echo "Completed build in "$((scriptEndTime-$scriptStartTime))" seconds"
