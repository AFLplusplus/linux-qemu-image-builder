#!/bin/bash

if [ -f /setup_successful ]; then
    echo "VM has already been setup. Stopping early..."
    exit 0
fi
/setup_firstboot/setup_firstboot.sh
touch /setup_successful

shutdown now
