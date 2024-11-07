FROM archlinux:latest

RUN pacman -Syu --noconfirm qemu qemu-img arch-install-scripts parted gptfdisk util-linux python python-pip sudo dosfstools guestfs-tools linux && pacman -Sw --noconfirm base base-devel linux linux-firmware mkinitcpio qemu-guest-agent vim
RUN pip install --break-system-packages virt-firmware

WORKDIR /root

COPY scripts /root/scripts
COPY templates /root/templates

COPY parameters.sh /root
COPY setup /root/setup
COPY setup_firstboot /root/setup_firstboot
COPY runtime /root/runtime


