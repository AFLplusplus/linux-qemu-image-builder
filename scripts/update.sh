#!/bin/bash

SCRIPTS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. "${SCRIPTS_DIR}/../parameters.sh"

trap 'error_exit' ERR
clean

# Mount the disk
"${SCRIPTS_DIR}/mount.sh"

echo "[*] Replacing user runtime content..."
sudo rm -rf "${MNT_DIR}/runtime"
sudo cp -a "${RUNTIME_DIR}" "${MNT_DIR}/runtime/"
echo "[*] User runtime content is ready."

clean
