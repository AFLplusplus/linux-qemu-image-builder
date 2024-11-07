#!/bin/bash

if [ -f /setup_successful ]; then
    exit 0
fi

./setup_firstboot.sh

touch /setup_successful

shutdown now
