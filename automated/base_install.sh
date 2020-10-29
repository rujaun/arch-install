#!/bin/bash

echo -e "\nDisk name: "

read DISK

echo -e "\nSWAP file size in MiB: (0 for no swap): "
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

echo -e "\nEFI or BIOS: "
read BOOT_METHOD

if [ "$BOOT_METHOD" = "EFI" ]; then
	# Create UEFI Partitions:
	DISK="/dev/${DISK}"
	BOOT_PARTITION="${DISK}1"
	ROOT_PARTITION="${DISK}2"

	echo -e "\nCreating GPT partition table:\n"

	parted --script "$DISK" mklabel gpt

	echo -e "\nCreating UEFI Boot partition:\n"
	parted --script "$DISK" mkpart "efi" fat32 2MiB 512MiB
	parted --script /dev/sda set 1 esp on

	echo -e "\nCreating root partition:\n"
	parted --script "$DISK" mkpart "root" ext4 514MiB 100%

	# Format partitions:
	echo -e "\nFormatting EFI partition:"
	mkfs.fat -F32 "${BOOT_PARTITION}"

	echo -e "\nFormatting root partition"
	mkfs.ext4 -F "${ROOT_PARTITION}"
fi

if [ "$BOOT_METHOD" = "BIOS" ]; then
	# Create MBR Partitions:
	DISK="/dev/${DISK}"
	BOOT_PARTITION="${DISK}1"
	ROOT_PARTITION="${DISK}2"

	echo -e "\nCreating GPT for BIOS partition table:\n"

	parted --script "$DISK" mklabel gpt

	echo -e "\nCreating root partition:\n"
	parted --script "$DISK" mkpart "bios" 2MiB 4MiB
	parted --script /dev/sda set 1 bios_grub on

	parted --script "$DISK" mkpart "root" ext4 6MiB 100%

	# Format partitions:
	echo -e "\nFormatting root partition"
	mkfs.ext4 -F "${ROOT_PARTITION}"
fi

# Update repos
pacman -Syy --noconfirm

echo -e "\nInstalling and running reflector to update mirrors..."
pacman -S reflector --noconfirm
reflector -c "ZA" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist

# Mount root partition
echo -e "\nMounting root partition..."
mount "${ROOT_PARTITION}" /mnt

# Install base system
echo -e "\nInstalling base system..."
pacstrap /mnt base base-devel linux linux-firmware linux-headers util-linux vim htop git curl wget

# Generate fstab
echo -e "\nGenerating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

#Preparing chroot script handoff
echo -e "\nPreparing chroot script handoff"
cp ./chroot_install.sh /mnt/chroot_install.sh

echo -e "\nEntering chroot"
arch-chroot /mnt sh ./chroot_install.sh "$DISK" "$SWAP_SIZE" "$BOOT_PARTITION" "$USERNAME" "$PASSWORD" "$HOST" "$GPU" "$CPU" "$BOOT_METHOD"

echo -e "\nRemoving chroot_install.sh"
rm /mnt/chroot_install.sh

echo -e "\nUnmounting root partition"
umount -l /mnt

read -p "Install finished - Press enter to continue..."