#!/bin/bash

# This script is run during the setup, out of the VM.
# The chroot is effective during the execution of this script.
# Thus, some operations like docker things cannot be done there.

# Default root password
echo "root:toor" | chpasswd

