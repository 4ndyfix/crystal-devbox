#!/bin/bash

/usr/bin/make serve &

SECS=60
while [[ $SECS -gt 0 ]]; do
  nc -vz localhost 8000
  if [[ $? -eq 0 ]]; then
    break
  fi
  echo "Still waiting $SECS sec for crystal-book ..."
  let SECS-=1
  sleep 1
done
