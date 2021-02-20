#!/bin/bash

# if no params: bash
if [ $# -eq 0 ]; then
  exec bash --init-file /usr/local/bin/init.sh
fi

exec "$@"

