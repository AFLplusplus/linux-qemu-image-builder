#!/bin/bash

ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "${ROOT_DIR}/parameters.sh"

trap 'error_exit' ERR
clean

# NBD setup
sudo modprobe nbd max_part=8

# Build the docker image creating the Linux disk
docker build -t linux_img_builder .

# Run the container creating the image itself
docker run --privileged -it --rm \
    -v=/dev:/dev \
    -v="${OUTPUT_DIR}:/root/output" \
    linux_img_builder \
    /root/scripts/update.sh

sudo chown -R "${USER}:${USER}" "${OUTPUT_DIR}"

