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
	echo -e "\nSetting swappiness to 10... "
	touch /etc/sysctl.d/99-swappiness.conf
	echo "vm.swappiness=10" >> /etc/sysctl.d/99-swappiness.conf
else
	echo -e "\nSetting swappiness to 0... "
	touch /etc/sysctl.d/99-swappiness.conf
	echo "vm.swappiness=0" >> /etc/sysctl.d/99-swappiness.conf
fi

echo -e "\nSetting timezone and updating hardware clock..."
ln -sf /usr/share/zoneinfo/Africa/Johannesburg /etc/localtime
hwclock --systohc

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


LUKSUUID=$(blkid | grep "/dev/${DISK}2" | grep -o "UUID=.*" | cut -d\" -f2)
sed -i '/GRUB_CMDLINE_LINUX=/d' /grub.lol
LINEINSERT=$(echo "10iGRUB_CMDLINE_LINUX="cryptdevice=UUID=${LUKSUUID}:cryptlvm root=/dev/vg/root cryptkey=rootfs:/root/secrets/crypto_keyfile.bin"")
sed -i "${LINEINSERT}" /grub.lol
cp -p /grub.lol /etc/default/grub
cp -p /mkinitcpio.conf.lol /etc/mkinitcpio.conf

if [ "$BOOT_METHOD" = "EFI" ]; then
	echo -e "\nInstalling GRUB-UEFI and configuring bootloader..."
	pacman -S grub efibootmgr --noconfirm
	mkdir /boot/efi
	mount "$BOOT_PARTITION" /boot/efi
	grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
fi


if [ "$BOOT_METHOD" = "BIOS" ]; then
	echo -e "\nInstalling GRUB-BIOS and configuring bootloader on GPT partition table..."
	pacman -S grub --noconfirm
	grub-install --target=i386-pc --recheck "$DISK"
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

mkdir /root/secrets && chmod 700 /root/secrets
head -c 64 /dev/urandom > /root/secrets/crypto_keyfile.bin
chmod 600 /root/secrets/crypto_keyfile.bin

while true; do
    echo "Enter your disk encryption passphrase :"
    cryptsetup -v luksAddKey -i 1 /dev/${DISKP}3 /root/secrets/crypto_keyfile.bin

    read -r -p "Do you need to try again? [y/N]" response
    if [[ "$response" =~ ^([Yy])+$ ]]; then
            continue
    else
            break
    fi
done

# create initramfs image
mkinitcpio -p linux

grub-mkconfig -o /boot/grub/grub.cfg

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

echo -e "\nInstalling Plasma desktop environment..."
pacman -S plasma plasma-wayland-session --noconfirm
pacman -S kdegraphics-thumbnailers kio-extras --noconfirm
pacman -S bzip2 gzip lzip xz p7zip unrar zip unzip --noconfirm
pacman -S konsole kate dolphin partitionmanager kcolorchooser krita okular vlc ark persepolis transmission-qt firefox chromium ktouch --noconfirm
pacman -S packagekit packagekit-qt5 appstream appstream-qt --noconfirm
pacman -S kwallet ksshaskpass kwalletmanager kwallet-pam signon-kwallet-extension --noconfirm


echo -e "Enabling SDDM..."
systemctl enable sddm.service#!/bin/bash
