#!/bin/sh

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "${SCRIPTS_DIR}/../parameters.sh"

trap 'error_exit' ERR
clean

# Mount the disk
"${SCRIPTS_DIR}/mount.sh"

echo "[*] Replacing user setup & runtime content..."
sudo rm -rf "${MNT_DIR}/setup"
sudo rm -rf "${MNT_DIR}/runtime"

sudo cp -a "${SETUP_DIR}" "${MNT_DIR}/setup/"
sudo cp -a "${RUNTIME_DIR}" "${MNT_DIR}/runtime/"
echo "[*] User content is ready."
echo "[*] Running setup script..."
sudo arch-chroot "${MNT_DIR}" /bin/bash /setup/setup.sh
echo "[*] Update succeeded successfully."

clean
