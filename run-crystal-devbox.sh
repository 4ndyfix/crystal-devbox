#!/bin/bash

docker run \
  --name crystal-devbox \
  --rm -it \
  -e DISPLAY=$DISPLAY \
  -e HOME=$HOME \
  -e USER=$USER \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /etc/shadow:/etc/shadow:ro \
  -v /etc/group:/etc/group:ro \
  -v /etc/passwd:/etc/passwd:ro \
  -v /etc/machine-id:/etc/machine-id \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/local/share/ca-certificates:/usr/local/share/ca-certificates/ \
  -v $HOME:$HOME \
  --device /dev/dri \
  -u $(id -u):$(id -g) \
  --group-add $(grep docker: /etc/group|cut -d':' -f3) \
  -w $PWD \
  --net=host \
  --privileged \
  4ndyfix/crystal-devbox:latest \
  "$@"

