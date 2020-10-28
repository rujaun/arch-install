#!/bin/bash

DISK="$1"
SWAP_SIZE="$2"
BOOT_PARTITION="$3"
USERNAME="$4"
PASSWORD="$5"
HOST="$6"
GPU="$7"
CPU="$8"
BOOT_METHOD="$9"

if (( "$SWAP_SIZE" > 0 )); then
	echo -n "Creating SWAP file:"
	cd /
	dd if=/dev/zero of=swapfile bs=1M count="$SWAP_SIZE" status=progress
	chmod 600 swapfile
	mkswap swapfile
	swapon swapfile
	echo "/swapfile		none	swap defaults 0 0" >> /etc/fstab
	touch /etc/sysctl.d/99-swappiness.conf
	echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf
fi

echo -n "Setting timezone and updating hardware clock..."
hwclock --systohc
timedatectl set-local-rtc 1 --adjust-system-clock
ln -sf /usr/share/zoneinfo/Africa/Johannesburg /etc/localtime

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

echo "root:$PASSWORD" | chpasswd

if [ "$BOOT_METHOD" = "EFI" ]; then
	echo -n "Install GRUB-UEFI and configuring bootloader..."
	pacman -S grub efibootmgr --noconfirm
	mkdir /boot/efi
	mount "$BOOT_PARTITION" /boot/efi
	grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
	grub-mkconfig -o /boot/grub/grub.cfg
fi


if [ "$BOOT_METHOD" = "BIOS" ]; then
	echo -n "Install GRUB-BIOS and configuring bootloader..."
	pacman -S grub
	grub-install --target=i386-pc --recheck "$DISK"
	grub-mkconfig -o /boot/grub/grub.cfg
fi

echo -n "Setting up local user account and installing sudo..."
pacman -S sudo --noconfirm
useradd --create-home "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
usermod --append --groups wheel "$USERNAME"
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

echo -n "Install and enable NetworkManager..."
pacman -S networkmanager --noconfirm
systemctl enable NetworkManager.service

echo -n "Enabling TRIM scheduling for SSDs..."
systemctl enable fstrim.timer

echo -n "Installing Xorg and GPU drivers..."
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syu --noconfirm

echo -n "Installing xorg and dkms..."
pacman -S xorg dkms --noconfirm

if [ "$GPU" = "AMD" ]; then
	echo -n "Installing AMD GPU drivers"
	pacman -S lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
fi

if [ "$GPU" = "Intel" ]; then
	echo -n "Installing Intel GPU drivers"
	pacman -S lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
fi

if [ "$GPU" = "Nvidia" ]; then
	echo -n "Installing Nvidia GPU drivers"
	pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
fi

echo -n "Installing Plasma desktop environment..."
pacman -S plasma plasma-wayland-session --noconfirm
pacman -S kdegraphics-thumbnailers kio-extras --noconfirm
pacman -S bzip2 gzip lzip xz p7zip unrar zip unzip --noconfirm
pacman -S konsole kate dolphin partitionmanager kcolorchooser krita okular vlc ark persepolis transmission-qt firefox chromium ktouch --noconfirm
pacman -S packagekit packagekit-qt5 appstream appstream-qt --noconfirm

echo -n "Installing vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo -n "Installing python..."
pacman -S python python-pip --noconfirm

echo -n "Installing support for NTFS and exfat drives / partitions..."
pacman -S ntfs-3g exfat-utils --noconfirm

echo -n "Enabling SDDM..."
systemctl enable sddm.service

if [ "$CPU" = "AMD" ]; then
	echo -n "Installing AMD CPU microcode"
	pacman -S amd-ucode --noconfirm
fi

if [ "$CPU" = "Intel" ]; then
	echo -n "Installing Intel CPU microcode"
	pacman -S intel-ucode --noconfirm
fi
