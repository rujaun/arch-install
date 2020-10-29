#!/bin/bash

echo -e "\n Setting system clock..."
hwclock --systohc
timedatectl set-local-rtc 1 --adjust-system-clock
timedatectl set-timezone "$(curl --fail https://ipapi.co/timezone)"

echo -e "\nUpdating system..."
sudo pacman -Syu --noconfirm

echo -e "\nInstalling Qtile window manager..."
sudo pacman -S qtile --noconfirm

echo -e "\nCopying .xinitrc"
cp ./.xinitrc ~/.xinitrc

echo -e "\nAdding startx to bash_profile"

FILE=~/.bash_profile
if [[ -f "$FILE" ]]; then
	echo -e "\n$FILE exists."
	
	echo -e "\nWriting to bash_profile"
	echo "[[ $(fgconsole 2>/dev/null) == 1 ]] && exec startx --vt1" > ~/.bash_profile
else
	echo -e "\nCreating to bash_profile"
	touch ~/.bash_profile
	echo "[[ -f ~/.bashrc ]] && . ~/.bashrc" > ~/.bash_profile

	echo -e "\nWriting to bash_profile"
	echo "[[ $(fgconsole 2>/dev/null) == 1 ]] && exec startx --vt1" >> ~/.bash_profile
fi

echo -e "\nCopying qtile configuration..."
mkdir -p ~/.config/qtile/
cp ./config.py ~/.config/qtile/config.py

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

echo -e "\nInstall b43-firmware ?: "

read B43

if [ "$B43" = "Y" ]; then
	echo -e "\nInstalling b43-firmware"
	yay -S b43-firmware --noconfirm
fi