#!/bin/sh

ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "${ROOT_DIR}/parameters.sh"

qemu-system-x86_64 \
  -accel "$QEMU_ACCEL" \
  -m "$QEMU_RAM" \
  -smp "$QEMU_DEBUG_NB_CORES" \
  -drive if=pflash,format=raw,readonly=on,file="${OVMF_CODE}" \
  -drive if=pflash,format=raw,snapshot=off,file="${OVMF_VARS}" \
  -blockdev filename="${IMG}",node-name=storage,driver=file \
  -blockdev driver=qcow2,file=storage,node-name=disk \
  -device virtio-scsi-pci,id=scsi0,bus=pci.0,addr=4 \
  -device scsi-hd,bus=scsi0.0,drive=disk,id=virtio-disk0,bootindex=1 \
  -net nic \
  -net user

