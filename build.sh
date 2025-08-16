#!/bin/bash

ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "${ROOT_DIR}/parameters.sh"

# NBD setup
sudo modprobe nbd max_part=8

# Prepare build
trap 'error_exit' ERR
sudo rm -rf "${OUTPUT_DIR}"
clean

# Build the docker image creating the Linux disk
docker build -t linux_img_builder "${ROOT_DIR}"

# Run the container creating the image itself
docker run --privileged -it --rm \
    -v=/dev:/dev \
    -v="${OUTPUT_DIR}:/root/output" \
    linux_img_builder \
    /root/scripts/create_image.sh

sudo chown -R "${USER}:$(id -g)" "${OUTPUT_DIR}"

echo "=== QEMU started, first run setup is getting executed... ==="
${ROOT_DIR}/run_headless.sh
echo "=== VM is ready for fuzzing. ==="
