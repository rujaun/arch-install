#!/bin/bash

DISK="$1"
SWAP="$2"
BOOT_PARTITION="$3"
ROOT_PASSWORD="$4"
USERNAME="$5"
USER_PASSWORD="$6"
HOST="$7"
GPU="$8"
CPU="$9"

echo -n "Setting timezone..."
timedatectl set-timezone Africa/Johannesburg

echo -n "Updating hardware clock..."
timedatectl set-local-rtc 1 --adjust-system-clock

echo -n "Setting locale..."
echo en_ZA.UTF-8 UTF-8 > /etc/locale.gen
echo LANG=en_ZA.UTF-8 > /etc/locale.conf
export LANG=en_ZA.UTF-8
locale-gen

echo -n "Setting hostname and configuring hosts..."
echo "$HOST" > /etc/hostname
echo "127.0.0.1			localhost" >> /etc/hosts
echo "::1				localhost" >> /etc/hosts
echo "127.0.1.1			$HOST" >> /etc/hosts

echo -n "Setting root password..."
echo "root:$ROOT_PASSWORD" | chpasswd

echo -n "Install GRUB and configuring bootloader..."
pacman -S grub efibootmgr --noconfirm
mkdir /boot/efi
mount "$BOOT_PARTITION" /boot/efi
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

# echo -n "Setting up local user account and installing sudo..."
# pacman -S sudo --noconfirm
# useradd --create-home "$USERNAME"
# echo "$USERNAME:$USER_PASSWORD" | chpasswd
# usermod --append --groups wheel "$USERNAME"
# echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

# echo -n "Install and enable NetworkManager..."
# pacman -S networkmanager --noconfirm
# systemctl enable NetworkManager.service

# echo -n "Enabling TRIM scheduling for SSDs..."
# sudo systemctl enable fstrim.timer

# echo -n "Installing Xorg and GPU drivers..."
# sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
# pacman -Syu --noconfirm

# echo -n "Installing xorg and dkms..."
# sudo pacman -S xorg dkms --noconfirm

# if [ "$GPU" = "AMD" ]; then
# 	echo -n "Installing AMD GPU drivers"
# 	sudo pacman -S lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
# fi

# if [ "$GPU" = "Intel" ]; then
# 	echo -n "Installing Intel GPU drivers"
# 	sudo pacman -S lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
# fi

# if [ "$GPU" = "Nvidia" ]; then
# 	echo -n "Installing Nvidia GPU drivers"
# 	sudo pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
# fi

# echo -n "Installing Plasma desktop environment..."
# sudo pacman -S plasma plasma-wayland-session --noconfirm
# sudo pacman -S kdegraphics-thumbnailers kio-extras --noconfirm
# sudo pacman -S bzip2 gzip lzip xz p7zip unrar zip unzip --noconfirm
# sudo pacman -S konsole kate dolphin partitionmanager kcolorchooser krita okular vlc ark persepolis transmission-qt firefox chromium ktouch --noconfirm
# sudo pacman -S packagekit packagekit-qt5 appstream appstream-qt --noconfirm

# echo -n "Installing vim-plug..."
# curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
#     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# echo -n "Installing python..."
# sudo pacman -S python python-pip --noconfirm

# echo -n "Installing support for NTFS and exfat drives / partitions..."
# sudo pacman -S ntfs-3g exfat-utils --noconfirm

# echo -n "Enabling SDDM..."
# sudo pacman -S ntfs-3g exfat-utils --noconfirm