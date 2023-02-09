#!/bin/bash

CUR_DIR=$(pwd)

for f in $(find $CUR_DIR -type f -exec file {} \; | grep 'not stripped' | awk '{print $1}'); do
  f="${f::-1}"
  strip "${f}"
done
