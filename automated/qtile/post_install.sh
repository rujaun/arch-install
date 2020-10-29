#!/bin/bash

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
cp ./config.py ~/.config/qtile/config.py