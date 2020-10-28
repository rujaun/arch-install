#!/bin/bash

echo -n "Disk name:"

read DISK

echo -n "Do you require a swap file? (Y/N)"

read SWAP
SWAP_SIZE=0

if [ "$SWAP" = "Y" ]; then
	echo -n "SWAP file size in MiB:"
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

echo -n "EFI or BIOS:"
read BOOT_METHOD

if [ "$BOOT_METHOD" = "EFI" ]; then
	# Create UEFI Partitions:
	DISK="/dev/${DISK}"
	BOOT_PARTITION="${DISK}1"
	ROOT_PARTITION="${DISK}2"

	echo -n "Creating GPT partition table:\n"

	parted --script "$DISK" mklabel gpt

	echo -n "Creating UEFI Boot partition:\n"
	parted --script "$DISK" mkpart "efi" fat32 2MiB 512MiB
	parted --script /dev/sda set 1 esp on

	echo -n "Creating root partition:\n"
	parted --script "$DISK" mkpart "root" ext4 514MiB 100%

	# Format partitions:
	echo -n "Formatting EFI partition:"
	mkfs.fat -F32 "${BOOT_PARTITION}"

	echo -n "Formatting root partition"
	mkfs.ext4 -F "${ROOT_PARTITION}"
fi

if [ "$BOOT_METHOD" = "BIOS" ]; then
	# Create MBR Partitions:
	DISK="/dev/${DISK}"
	ROOT_PARTITION="${DISK}1"

	echo -n "Creating MBR partition table:\n"

	parted --script "$DISK" mklabel msdos

	echo -n "Creating root partition:\n"
	parted --script "$DISK" mkpart primary ext4 2MiB 100%

	parted --script /dev/sda set 1 boot on

	# Format partitions:
	echo -n "Formatting root partition"
	mkfs.ext4 -F "${ROOT_PARTITION}"
fi

# Update repos
pacman -Syy --noconfirm

echo -n "Installing and running reflector to update mirrors..."
pacman -S reflector --noconfirm
reflector -c "ZA" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist

# Mount root partition
echo -n "Mounting root partition..."
mount "${ROOT_PARTITION}" /mnt

# Install base system
echo -n "Installing base system..."
pacstrap /mnt base base-devel linux linux-firmware linux-headers util-linux amd-ucode vim

# Generate fstab
echo -n "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

#Preparing chroot script handoff
echo -n "Preparing chroot script handoff"
cp ./chroot_install.sh /mnt/chroot_install.sh

echo -n "Entering chroot"
arch-chroot /mnt sh ./chroot_install.sh "$DISK" "$SWAP" "$SWAP_SIZE" "$BOOT_PARTITION" "$ROOT_PASSWORD" "$USERNAME" "$USER_PASSWORD" "$HOST" "$GPU" "$CPU" "$BOOT_METHOD"

echo -n "Removing chroot_install.sh"
rm /mnt/chroot_install.sh

echo -n "Unmounting root partition and reboot"
umount -l /mnt

read -p "Install finished - Press enter to continue..."