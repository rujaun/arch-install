#!/bin/bash

echo -n "Disk name:"

read DISK

echo -n "Do you require a swap partition? (Y/N)"

read SWAP
SWAP_SIZE=0

if [ "$SWAP" = "Y" ]; then
	echo -n "SWAP size in G:"
	read SWAP_SIZE
fi

echo -n "Hostname:"

read HOST

echo -n "ROOT Password:"

read ROOT_PASSWORD

echo -n "User name (lowercase):"

read USERNAME

echo -n "User Password:"

read USER_PASSWORD

echo -n "GPU (AMD | Intel | Nvidia):"

read GPU

echo -n "CPU (AMD | Intel):"

read CPU

# Create Partitions:
DISK="/dev/${DISK}"
BOOT_PARTITION="${DISK}1"
ROOT_PARTITION="${DISK}2"
SWAP_PARTITION=""

if [ "$SWAP" = "Y" ]; then
	SWAP_PARTITION="${DISK}2"
	ROOT_PARTITION="${DISK}3"
fi

echo -n "Creating GPT partition table"

parted --script "$DISK" mklabel gpt

echo -n "Creating UEFI Boot partition:"
parted --script "$DISK" mkpart "EFI system partition" fat32 2MiB 512MiB
parted --script set 1 esp on


if [ "$SWAP" = "Y" ]; then
	echo -n "Creating SWAP partition:"
	parted --script "$DISK" mkpart "swap partition" linux-swap 514MiB 8706MiB
fi

echo -n "Creating root partition:"
if [ "$SWAP" = "Y" ]; then
	parted -script "$DISK" mkpart "root partition" ext4 8708MiB 100%
else
	parted -script "$DISK" mkpart "root partition" ext4 514MiB 100%
fi

# Format partitions:
echo -n "Formatting EFI partition:"
mkfs.fat -F32 "${BOOT_PARTITION}"

if [ "$SWAP" = "Y" ]; then
	echo -n "Making SWAP partition..."
	mkswap "${SWAP_PARTITION}"
fi

echo -n "Formatting root partition"
mkfs.ext4 "${ROOT_PARTITION}"

# Update repos
#pacman -Syy --noconfirm

#echo -n "Installing and running reflector to update mirrors..."
#pacman -S reflector --noconfirm
#reflector -c "ZA" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist

# Mount root partition
#echo -n "Mounting root partition..."
#mount "${ROOT_PARTITION}" /mnt

# Install base system
#echo -n "Installing base system..."
#pacstrap /mnt base base-devel linux linux-firmware linux-headers util-linux amd-ucode vim

# Generate fstab
#echo -n "Generating fstab"
#genfstab -U /mnt >> /mnt/etc/fstab

#Preparing chroot script handoff
#echo -n "Preparing chroot script handoff"
#cp ./chroot_install.sh /mnt

#echo -n "Entering chroot"
#arch-chroot /mnt ./chroot_install.sh "$DISK" "$SWAP" "$BOOT_PARTITION" "$ROOT_PASSWORD" "$USERNAME" "$USER_PASSWORD" "$HOST" "$GPU" "$CPU"

#echo -n "Removing chroot_install.sh"
#rm /mnt/chroot_install.sh

#echo -n "Unmounting root partition and reboot"
#umount -R /mnt
#systemctl reboot