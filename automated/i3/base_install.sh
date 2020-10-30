#!/bin/bash

echo -e "\nDisk name: "

read DISK

echo -e "\nSWAP file size in G: (0 for no swap): "
read SWAP_SIZE

echo -e "\nRoot partition size in G: "
read ROOT_SIZE

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
	parted --script "$DISK" mkpart "root" 514MiB 100%

	# Format partitions:
	echo -e "\nFormatting EFI partition:"
	mkfs.fat -F32 "${BOOT_PARTITION}"
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

	parted --script "$DISK" mkpart "root" 6MiB 100%
fi

cryptsetup luksFormat --type luks1 --use-random -S 1 -s 512 -h sha512 -i 5000 "${ROOT_PARTITION}"
cryptsetup open "${ROOT_PARTITION}" cryptlvm
pvcreate /dev/mapper/cryptlvm
vgcreate vg /dev/mapper/cryptlvm


if (( "$SWAP_SIZE" > 0 )); then
	lvcreate -L ${SWAP_SIZE}G vg -n swap
fi

lvcreate -L ${ROOT_SIZE}G vg -n root
lvcreate -l 100%FREE vg -n home

mkfs.ext4 /dev/vg/root
mkfs.ext4 /dev/vg/home
mkswap /dev/vg/swap

mount /dev/vg/root /mnt
mkdir /mnt/home
mount /dev/vg/home /mnt/home
swapon /dev/vg/swap

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

#Preparing chroot script handoff
echo -e "\nPreparing chroot script handoff"
cp ./grub /mnt/grub.lol
cp ./mkinitcpio.conf /mnt/mkinitcpio.conf.lol
cp ./chroot_install.sh /mnt/chroot_install.sh

echo -e "\nEntering chroot"
arch-chroot /mnt sh ./chroot_install.sh "$DISK" "$SWAP_SIZE" "$BOOT_PARTITION" "$USERNAME" "$PASSWORD" "$HOST" "$GPU" "$CPU" "$BOOT_METHOD"

echo -e "\nRemoving chroot_install.sh"
rm /mnt/grub.lol
rm /mnt/chroot_install.sh
rm /mnt/mkinitcpio.conf.lol

echo -e "\nUnmounting root partition"
umount -l /mnt

read -p "Install finished - Press enter to continue..."