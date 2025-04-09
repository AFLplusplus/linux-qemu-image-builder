#!/bin/bash

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "${SCRIPTS_DIR}/../parameters.sh"

trap 'error_exit' ERR
clean

PACKAGES_TO_INSTALL=(base base-devel linux linux-firmware mkinitcpio qemu-guest-agent vim linux-headers)

if [ "${CONFIGURE_NETWORK}" -ne "0" ]; then
    PACKAGES_TO_INSTALL+=(networkmanager)
fi

### Preparing main directories
mkdir -p "${OUTPUT_DIR}" # Output of the creation script
mkdir -p "${TMP_DIR}" # tmp directory, can be removed at the end of this script
mkdir -p "${MNT_DIR}" # mnt directory, where qcow2 disk is getting mounted

## Disk creation and mount
qemu-img create -f qcow2 "${IMG}" "${IMG_SIZE}"

echo "[*] Connecting QCOW2 disk to NBD..."
sudo qemu-nbd --connect="${DEV_PATH}" "${IMG}"
nbd_sync
echo "[*] QCOW2 disk connected."

sudo wipefs "${DEV_PATH}"

### Partitionning
echo "[*] Partitionning..."
sudo parted -s "${DEV_PATH}" mklabel gpt # gpt partition table

# Boot Partition
sudo parted -s "${DEV_PATH}" -a optimal mkpart "'EFI system partition'" fat32 0% 1G
sudo parted -s "${DEV_PATH}" set 1 esp on

# Root partition
sudo parted -s "${DEV_PATH}" -a optimal mkpart "'root_partition'" ext4 1G 100%

echo "[*] Partitionning done."

### Filesystem create
echo "[*] Filesystem creation..."
sudo mkfs.fat -F 32 "${BOOT_DEV}"
sudo mkfs.ext4 "${LINUX_DEV}"
echo "[*] Filesystem ready."

### Mount partitions
sudo mount "${LINUX_DEV}" "${MNT_DIR}"

sudo mkdir -p "${BOOT_DIR}"
sudo mount "${BOOT_DEV}" "${BOOT_DIR}"

echo "[*] Installing basic packages..."
sudo pacstrap -c -P -K "${MNT_DIR}" "${PACKAGES_TO_INSTALL[@]}"

echo "[*] Packages installed on disk."

echo "[*] Configuring basic packages..."

if [ "${CONFIGURE_NETWORK}" -ne "0" ]; then
    sudo arch-chroot "${MNT_DIR}" systemctl enable NetworkManager
fi

sudo arch-chroot "${MNT_DIR}" pacman-key --init
sudo arch-chroot "${MNT_DIR}" pacman-key --populate archlinux

echo "[*] Basic packages configured successfully."

### Generate fstab
echo "[*] Generating fstab..."
BOOT_UUID=$(virt-filesystems -a "${IMG}" --long --uuid | grep -i vfat | tr -s " " | cut -d ' ' -f 7)
ROOT_UUID=$(virt-filesystems -a "${IMG}" --long --uuid | grep -i ext4 | tr -s " " | cut -d ' ' -f 7)
cat "${TEMPLATE_DIR}/fstab.template" | sed -e "s/<rootuuid>/${ROOT_UUID}/" | sed -e "s/<bootuuid>/${BOOT_UUID}/" | sudo tee "${MNT_DIR}/etc/fstab" > /dev/null
echo "[*] fstab ready."

### UKI Linux
echo "[*] Preparing Linux for UKI mode..."
sudo mkdir -p "${BOOT_DIR}/efi/EFI/Linux"
sudo mkdir -p "${MNT_DIR}/etc/cmdline.d"
sudo cp "${TEMPLATE_DIR}/linux.preset" "${MNT_DIR}/etc/mkinitcpio.d/linux.preset"
sudo cp "${TEMPLATE_DIR}/libafl.conf" "${MNT_DIR}/etc/cmdline.d/libafl.conf"
cat "${TEMPLATE_DIR}/root.conf.template" | sed -e "s/<rootuuid>/${ROOT_UUID}/" | sudo tee "${MNT_DIR}/etc/cmdline.d/root.conf" > /dev/null
sudo arch-chroot "${MNT_DIR}" mkinitcpio -p linux
echo "[*] Linux has been set up."

# Autologin as root
# sudo cp autologin.conf "$MNT_DIR/etc/systemd/system/autologin@.service"
# sudo arch-chroot "$MNT_DIR" mv /etc/systemd/system/getty.target.wants/getty@tty1.service /etc/systemd/system/getty.target.wants/getty@tty1.service.backup
# sudo arch-chroot "$MNT_DIR" ln -s /etc/systemd/system/autologin@.service /etc/systemd/system/getty.target.wants/getty@tty1.service

### Install user-provided runtime scripts.
echo "[*] Copying user runtime content..."
sudo cp -a "${RUNTIME_DIR}" "${MNT_DIR}/runtime/"
echo "[*] User runtime content is ready."

echo "[*] Preparing entrypoint service..."
sudo cp "${TEMPLATE_DIR}/entrypoint.service" "${MNT_DIR}/etc/systemd/system/entrypoint.service"
echo "[*] Entrypoint service is ready."

### Run user-provided setup script.
echo "[*] Running user-provided VM setup..."
sudo cp -a "${SETUP_DIR}" "${MNT_DIR}/setup/"
sudo arch-chroot "${MNT_DIR}" /bin/bash /setup/setup.sh
echo "[*] User setup ran successfully."

### Run user-provided first run setup script.
echo "[*] Running user-provided VM first boot setup..."
sudo cp "${TEMPLATE_DIR}/setup_firstboot.service"       "${MNT_DIR}/etc/systemd/system/"
sudo cp -a "${SETUP_FIRSTBOOT_DIR}"                     "${MNT_DIR}/setup_firstboot/"
sudo cp -a "${TEMPLATE_DIR}/setup_firstboot_wrapper.sh"    "${MNT_DIR}/setup_firstboot/"
sudo arch-chroot "${MNT_DIR}" systemctl daemon-reload
sudo arch-chroot "${MNT_DIR}" systemctl enable setup_firstboot
echo "[*] User first boot setup enabled successfully."

### Get OVMF
echo "[*] Fetching OVMF..."
cp ${OVMF_DIR}/OVMF_{CODE,VARS}.4m.fd ${OUTPUT_DIR}

### Setup UEFI
echo "[*] Applying OVMF hack..."
PARTUUID=$(sudo blkid | grep "$DEV_PATH" | grep vfat | sed "s/.*PARTUUID=\"\(.*\)\"/\1/")
PARTUUID_SPLIT=(${PARTUUID//-/ })

RES=""
VAL=$(echo "${PARTUUID_SPLIT[0]}" | tac -rs .. | echo "$(tr -d '\n')")
RES="${RES}${VAL}"

VAL=$(echo "${PARTUUID_SPLIT[1]}" | tac -rs .. | echo "$(tr -d '\n')")
RES="${RES}${VAL}"

VAL=$(echo "${PARTUUID_SPLIT[2]}" | tac -rs .. | echo "$(tr -d '\n')")
RES="${RES}${VAL}"

RES="${RES}${PARTUUID_SPLIT[3]}"
RES="${RES}${PARTUUID_SPLIT[4]}"

# Now RES contains the unparsed PARTUUID, inject it in the efi variable
cat "${TEMPLATE_DIR}/boot_uefi.json.template" | sed -e "s/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/$RES/" > "${TMP_DIR}/boot_uefi.json"
virt-fw-vars --inplace "${OVMF_VARS}" --set-json "${TMP_DIR}/boot_uefi.json"
echo "[*] OVMF ready to boot linux automatically."

# Unmount cleanly
clean
echo "[*] The Linux QCOW2 disk is ready and available in the output directory."
