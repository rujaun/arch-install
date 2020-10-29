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

if [ "$BOOT_METHOD" = "EFI" ]; then
	echo -e "\nInstalling GRUB-UEFI and configuring bootloader..."
	pacman -S grub efibootmgr --noconfirm
	mkdir /boot/efi
	mount "$BOOT_PARTITION" /boot/efi
	grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
	grub-mkconfig -o /boot/grub/grub.cfg
fi


if [ "$BOOT_METHOD" = "BIOS" ]; then
	echo -e "\nInstalling GRUB-BIOS and configuring bootloader on GPT partition table..."
	pacman -S grub --noconfirm
	grub-install --target=i386-pc --recheck "$DISK"
	grub-mkconfig -o /boot/grub/grub.cfg
fi

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
pacman -S xf86-video-fbdev xorg xorg-xinit dkms --noconfirm

if [ "$GPU" = "AMD" ]; then
	echo -e "\nInstalling AMD GPU drivers"
	pacman -S lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
fi

if [ "$GPU" = "Intel" ]; then
	echo -e "\nInstalling Intel GPU drivers"
	pacman -S lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
fi

if [ "$GPU" = "Nvidia" ]; then
	echo -e "\nInstalling Nvidia GPU drivers"
	pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
fi

echo -e "\nInstalling gnome-terminal and gnome-keyring..."
pacman -S gnome-terminal gnome-keyring --noconfirm

echo -e "\nConfigure gnome-keyring daemon to start through PAM"
echo "auth		optional		pam_gnome_keyring.so" >> /etc/pam.d/login
echo "session	optional		pam_gnome_keyring.so auto_start" >> /etc/pam.d/login

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

echo -e "\nInstalling LXQT desktop environment..."
pacman -S lxqt --noconfirm
pacman -S ssdm --noconfirm
pacman -S xscreensaver --noconfirm

echo -e "Enabling SDDM..."
systemctl enable sddm.service