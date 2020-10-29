#!/bin/bash

echo -e "\n Setting system clock..."
hwclock --systohc
timedatectl set-ntp true
timedatectl set-local-rtc 1 --adjust-system-clock

echo -e "\nUpdating system..."
sudo pacman -Syu --noconfirm

echo -e "\nInstall Yay - AUR (Arch User Repository) helper? (Y/N): "

read AURYAY

if [ "$AURYAY" = "Y" ]; then
	echo -e "\nInstalling Yay - AUR (Arch User Repository) helper"
	sudo pacman -S git go --noconfirm

	git clone https://aur.archlinux.org/yay-git.git
	cd yay-git
	makepkg -si
	cd ..
	rm -rf ./yay-git
fi

echo -e "\nInstall b43-firmware? (Y/N): "

read B43

if [ "$B43" = "Y" ]; then
	echo -e "\nInstalling b43-firmware"
	yay -S b43-firmware --noconfirm
fi

echo -e "\nInstall LXQt Connman applet? (Y/N): "

read CONNMAN

if [ "$CONNMAN" = "Y" ]; then
	echo -e "\nInstalling LXQt Connman applet"
	yay -S lxqt-connman-applet --noconfirm
fi

echo -e "\nInstall Arch Linux screensaver and other goodies? (Y/N): "

read SCREENSAVER

if [ "$SCREENSAVER" = "Y" ]; then
	echo -e "\nInstalling Arch Linux screensaver"
	yay -S xscreensaver-arch-logo --noconfirm
	yay -S archlinux-themes-sddm --noconfirm
	yay -S sddm-nordic-theme-git --noconfirm
fi