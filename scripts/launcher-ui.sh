#!/bin/bash

# in directory /app
# run launcher as Kemal-webservice silently in background
# (opens UI in browser)
cd /app && MODE=UI launcher 2>&1 >/dev/null &

