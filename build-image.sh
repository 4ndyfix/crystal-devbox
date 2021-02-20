#!/bin/bash
set -e

CRYSTAL_VERSION='0.36.1'

NAME='crystal-devbox'
TAG='0.9.0-'${CRYSTAL_VERSION}

IMAGE_TAGGED=$NAME:$TAG
IMAGE_LATEST=$NAME:latest

docker rmi -f $IMAGE_TAGGED
docker rmi -f $IMAGE_LATEST

docker build \
 --tag $IMAGE_TAGGED \
 --build-arg CRYSTAL_VERSION=$CRYSTAL_VERSION \
 .

docker tag $IMAGE_TAGGED $IMAGE_LATEST