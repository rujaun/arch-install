#!/bin/bash

echo -e "\nSWAP file size in G: (0 for no swap): "
read SWAP_SIZE

echo -e "\nHostname: "

read HOST

echo -e "\nUser name (lowercase): "

read USERNAME

echo -e "\nUser Password: "

read PASSWORD

echo -e "\nGPU (AMD | Intel | Nvidia): "

read GPU

echo -e "\nCPU (AMD | Intel): "

read CPU

if (( "$SWAP_SIZE" > 0 )); then
	echo -e "\nCreating SWAP file:"
	cd /
	dd if=/dev/zero of=swapfile bs=1M count="$SWAP_SIZE" status=progress
	chmod 600 swapfile
	mkswap swapfile
	swapon swapfile
	echo "/swapfile		none	swap defaults 0 0" >> /etc/fstab
	touch /etc/sysctl.d/99-swappiness.conf
	echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf
else
	echo "vm.swappiness=0" >> /etc/sysctl.d/99-swappiness.conf
fi

echo -e "\nSetting timezone and updating hardware clock..."
ln -sf /usr/share/zoneinfo/Africa/Johannesburg /etc/localtime

echo -e "\nSetting locale..."
echo "en_ZA.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_ZA.UTF-8" > /etc/locale.conf
export LANG=en_ZA.UTF-8

echo -e "\nSetting hostname and configuring hosts..."
echo "$HOST" > /etc/hostname
echo "127.0.0.1			localhost" >> /etc/hosts
echo "::1				localhost" >> /etc/hosts
echo "127.0.1.1			$HOST" >> /etc/hosts

echo "root:$PASSWORD" | chpasswd

echo -e "\nSetting up local user account and installing sudo..."
pacman -S sudo --noconfirm
useradd --create-home "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
usermod --append --groups wheel "$USERNAME"
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

echo -e "\nInstall and enable NetworkManager..."
pacman -S networkmanager --noconfirm
systemctl enable NetworkManager.service

echo -e "\nEnabling TRIM scheduling for SSDs..."
systemctl enable fstrim.timer

echo -e "\nInstalling Xorg and GPU drivers..."
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syu --noconfirm

echo -e "\nInstalling xorg and dkms..."
pacman -S xorg dkms --noconfirm

if [ "$GPU" = "AMD" ]; then
	echo -e "\nInstalling AMD GPU drivers"
	pacman -S xf86-video-amdgpu lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
fi

if [ "$GPU" = "Intel" ]; then
	echo -e "\nInstalling Intel GPU drivers"
	pacman -S lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
fi

if [ "$GPU" = "Nvidia" ]; then
	echo -e "\nInstalling Nvidia GPU drivers"
	pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
fi

echo -e "\nInstalling python..."
pacman -S python python-pip --noconfirm

echo -e "\nInstalling support for NTFS and exfat drives / partitions..."
pacman -S ntfs-3g exfat-utils --noconfirm

if [ "$CPU" = "AMD" ]; then
	echo -e "\nInstalling AMD CPU microcode"
	pacman -S amd-ucode --noconfirm
fi

if [ "$CPU" = "Intel" ]; then
	echo -e "\nInstalling Intel CPU microcode"
	pacman -S intel-ucode --noconfirm
fi

pacman -S bzip2 gzip lzip xz p7zip unrar zip unzip --noconfirm

echo -e "\n Remember to delete chroot_install.sh"
echo -e "\n rm /mnt/chroot_install.sh"