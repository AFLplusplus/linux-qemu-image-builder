#!/bin/bash

ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "${ROOT_DIR}/parameters.sh"

qemu-system-x86_64 \
  -accel "$QEMU_ACCEL" \
  -m "$QEMU_RAM" \
  -drive if=pflash,format=raw,readonly=on,file="${OVMF_CODE}" \
  -drive if=pflash,format=raw,snapshot=off,file="${OVMF_VARS}" \
  -blockdev filename="${IMG}",node-name=storage,driver=file \
  -blockdev driver=qcow2,file=storage,node-name=disk \
  -device virtio-scsi-pci,id=scsi0 \
  -device scsi-hd,bus=scsi0.0,drive=disk,id=virtio-disk0,bootindex=1

