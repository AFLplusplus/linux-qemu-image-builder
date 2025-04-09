FROM archlinux:latest

RUN pacman -Syu --noconfirm qemu qemu-img arch-install-scripts parted gptfdisk util-linux python python-pip sudo dosfstools guestfs-tools linux && pacman -Sw --noconfirm base base-devel linux linux-firmware mkinitcpio qemu-guest-agent vim
RUN pip install --break-system-packages virt-firmware

WORKDIR /root

# Internals
COPY scripts /root/scripts
COPY templates /root/templates

# To change by the user
COPY parameters.sh /root
COPY hooks /root/hooks

