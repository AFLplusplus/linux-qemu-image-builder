#!/bin/bash
set -eu

ROOT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


# === Build parameters ===

# path to nbd device
DEV_PATH=/dev/nbd0

# Image name (the final image will be in output/$IMG_NAME.qcow2)
IMG_NAME=linux

# (virtual) Image size
IMG_SIZE=20G

# Boot partition size
BOOT_SIZE=1G

# Mount directory
MNT_DIR="${ROOT_DIR}/mnt"

# Boot directory
BOOT_DIR="${MNT_DIR}/boot"

# configuration files templates location
OUTPUT_DIR="${ROOT_DIR}/output"

# path to the user hooks
HOOKS_DIR="${ROOT_DIR}/hooks"

# Setup directory
SETUP_DIR="${HOOKS_DIR}/setup"

# Setup first boot directory
SETUP_FIRSTBOOT_DIR="${HOOKS_DIR}/setup_firstboot"

# Runtime directory
RUNTIME_DIR="${HOOKS_DIR}/runtime"

# OVMF FD directory
OVMF_DIR=/usr/share/edk2/x64

# Should network be configured or not
CONFIGURE_NETWORK=1


# === Run parameters ===

# Choose run accelerator
QEMU_ACCEL=kvm # kvm or tcg

# Choose nb of cores
QEMU_DEBUG_NB_CORES=8

# Choose RAM size
QEMU_RAM=4G


# === Internals, can be ignored ===
SCRIPTS_DIR="${ROOT_DIR}/scripts"
TEMPLATE_DIR="${ROOT_DIR}/templates"
TMP_DIR="${ROOT_DIR}/tmp"
BOOT_DEV=${DEV_PATH}p1
LINUX_DEV=${DEV_PATH}p2

IMG="${OUTPUT_DIR}/${IMG_NAME}.qcow2"
OVMF_CODE="${OUTPUT_DIR}/OVMF_CODE.4m.fd"
OVMF_VARS="${OUTPUT_DIR}/OVMF_VARS.4m.fd"

# Taken from https://lists.sr.ht/~sircmpwn/sr.ht-dev/patches/53636
nbd_sync() {
    echo "[*] Syncing with NBD device..."
    for i in $(seq 1 10); do
        sleep $i
        partprobe "${DEV_PATH}" 2> /dev/null && break
    done
    echo "[*] NBD synced."
}

clean() {
    echo "[*] Cleaning up..."
    rm -rf "${TMP_DIR}"
    "${SCRIPTS_DIR}/umount.sh"
}

error_exit() {
    echo "[!] Error while running the script!"
    clean
    exit 1
}
