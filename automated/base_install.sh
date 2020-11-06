#!/bin/bash

# Update repos
pacman -Syy --noconfirm

echo -e "\nInstalling and running reflector to update mirrors..."
pacman -S reflector --noconfirm
reflector -c "ZA" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist

# Install base system
echo -e "\nInstalling base system..."
pacstrap /mnt base base-devel linux linux-firmware linux-headers util-linux mkinitcpio lvm2 vim dhcpcd networkmanager wpa_supplicant dialog git curl wget

# Generate fstab
echo -e "\nGenerating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo -e "\nPreparing chroot script handoff"
cp ./chroot_install.sh /mnt/chroot_install.sh