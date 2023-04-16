#!/bin/bash
set -e

GIT_TAG=$(git describe)
CRYSTAL_VERSION='1.8.0'

NAME='4ndyfix/crystal-devbox'
TAG=${GIT_TAG}'-'${CRYSTAL_VERSION}

IMAGE_TAGGED=$NAME:$TAG
IMAGE_LATEST=$NAME:latest

docker rmi -f $IMAGE_TAGGED
docker rmi -f $IMAGE_LATEST

docker build \
 --tag $IMAGE_TAGGED \
 --build-arg CRYSTAL_VERSION=$CRYSTAL_VERSION \
 .

docker tag $IMAGE_TAGGED $IMAGE_LATEST

