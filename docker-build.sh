#!/bin/bash
NAME=<YOUR_USERNAME>
IMAGE_NAME="<YOUR_IMAGE_NAME>"
VERSION="1.0.0"

CPU_PLATFORM=amd64

docker build \
  --tag ${NAME}-${IMAGE_NAME}:${VERSION} \
  --file Dockerfile \
  --platform linux/${CPU_PLATFORM} \
  .
