#!/bin/bash
set -e

cd $CRYSTAL_BOOK_DIR
make serve &
firefox http://127.0.0.1:8000
