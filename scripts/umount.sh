#!/bin/bash

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "${SCRIPTS_DIR}/../parameters.sh"

echo "Unmounting partitions..."

sync

if [[ $(mount | grep " ${BOOT_DIR} ") ]]; then
    echo "[*] Unmounting boot partition..."
    sudo umount -lf "${BOOT_DIR}"
    sync
    echo "[*] boot partition has been unmounted successfully."
fi

if [[ $(lsblk | grep "${BOOT_DEV}") ]]; then
    echo "[*] Disconnecting boot partition..."
    sudo qemu-nbd --disconnect "${BOOT_DEV}"
    sync
    echo "[*] boot partition has been disconnected successfully."
fi

if [[ $(mount | grep " ${MNT_DIR} ") ]]; then
    echo "[*] Unmounting root partition..."
    sudo umount -lf "${MNT_DIR}"
    sync
    echo "[*] root partition has been unmounted successfully."
fi

if [[ $(lsblk | grep "${LINUX_DEV}") ]]; then
    echo "[*] Disconnecting root partition..."
    sudo qemu-nbd --disconnect "${LINUX_DEV}"
    sync
    echo "[*] root partition has been disconnected successfully."
fi

if [ -e "${DEV_PATH}" ]; then
    echo "[*] Disconnecting NBD device..."
    sudo qemu-nbd --disconnect "$DEV_PATH"
    sync
    echo "[*] NBD device has been disconnected."
fi
