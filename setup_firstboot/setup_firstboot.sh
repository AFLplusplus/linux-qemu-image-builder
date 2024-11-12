#!/bin/bash

# This script is executed once at first boot
sleep 20
# wait till internet is up

yes | pacman -S docker docker-compose git less >>/setup_error 2>&1
systemctl start docker >>/setup_error 2>&1
/runtime/setup.sh >>/setup_error 2>&1
echo "Done" >>/setup_error 2>&1
