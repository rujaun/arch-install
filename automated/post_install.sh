#!/bin/bash

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

echo -e "\nInstall development tools from the AUR (Arch User Repository)? (Y/N): "

read DEVTOOLS

if [ "$DEVTOOLS" = "Y" ]; then
	echo -e "\nInstalling development tools from the AUR (Arch User Repository)"
	yay -S visual-studio-code-bin --noconfirm
	yay -S sublime-text-3 --noconfirm
fi


echo -e "\nInstall powerline patched programming fonts? (Y/N): "

read POWERFONTS

if [ "$POWERFONTS" = "Y" ]; then
	echo -e "\nInstalling powerline patched programming fonts"
	yay -S awesome-terminal-fonts-git
	yay -S powerline-fonts-git
	yay -S nerd-fonts-source-code-pro
	yay -S nerd-fonts-fira-code
fi

echo -e "\nInstall dbeaver? (Y/N): "

read DBEAVER

if [ "$DBEAVER" = "Y" ]; then
	echo -e "\nInstalling dbeaver..."
	sudo pacman -S dbeaver --noconfirm
fi


echo -e "\nInstall Python 3 + PIP? (Y/N): "

read PYTHON

if [ "$PYTHON" = "Y" ]; then
	echo -e "\nInstalling Python..."
	sudo pacman -S python python-pip --noconfirm
fi

echo -e "\nInstall Docker? (Y/N): "

read DOCKER

if [ "$DOCKER" = "Y" ]; then
	echo -e "\nInstalling Docker..."
	sudo pacman -S docker docker-compose --noconfirm
	sudo usermod --append --groups docker $USER
	yay -S kitematic --noconfirm
fi


echo -e "\nInstall LibreOffice? (Y/N): "

read LIBRE

if [ "$LIBRE" = "Y" ]; then
	echo -e "\nInstalling LibreOffice fresh..."
	sudo pacman -S libreoffice-fresh --noconfirm
fi


echo -e "\nInstall a few mathematics applications? (Y/N): "

read MATH

if [ "$MATH" = "Y" ]; then
	echo -e "\nYay for math!"
	sudo pacman -S geogebra kmplot cantor kalgebra labplot --noconfirm
fi

echo -e "\nInstall research paper managers? (Y/N): "

read RESEARCH

if [ "$RESEARCH" = "Y" ]; then
	echo -e "\nInstalling research paper managers..."
	
	yay -S jabref --noconfirm
	yay -S zotero --noconfirm
fi