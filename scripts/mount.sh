#!/bin/sh

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "${SCRIPTS_DIR}/../parameters.sh"

trap 'error_exit' ERR
clean

echo "[*] Connecting QCOW2 disk to NBD..."
sudo qemu-nbd --connect="${DEV_PATH}" "${IMG}"
nbd_sync

sleep 2

### mount partitions
echo "[*] Mounting root directory..."
mkdir -p "${MNT_DIR}"
sudo mount ${LINUX_DEV} "${MNT_DIR}"

sleep 2

echo "[*] Mounting boot directory..."
sudo mkdir -p "${BOOT_DIR}"
sudo mount "${BOOT_DEV}" "${BOOT_DIR}"

echo "[*] Linux disk mounted successfully."
