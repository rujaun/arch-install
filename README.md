# Personal Arch Linux install guide
This guide was written for my own personal use.

## Disclaimer
No liability for the contents of this documents can be accepted. Use the concepts, examples and other content at your own risk. There may be errors and inaccuracies, that may of course be damaging to your system. Although this is highly unlikely, you should proceed with caution. The author does not accept any responsibility for any damage incurred.

---


## Partition disks

List all disks:
```
fdisk -l
```

Select first disk:
```
fdisk /dev/sda
```
Create new GPT partition label:
```
g
```

Create UEFI ESP Partition:
```
n

+512M
```

Change type to EFI Filesystem:
```
t
1
```

Create root partition (Use all available space left):
```
n
```

Write changes to disk:
```
w
```

Select second disk:
```
fdisk /dev/sdb
```

Create new GPT partition label:
```
g
```

Create partition (Use all available space):
```
n
```

Write changes to disk:
```
w
```

---
## Create filesystems

Create UEFI filesystem:
```
mkfs.fat -F32 /dev/sda1
```

Create ext4 root filesystem:
```
mkfs.ext4 /dev/sda2
```

Create second disk ext4 filesystem:
```
mkfs.ext4 /dev/sdb1
```

---
## Mirror selection
By this point you should have established an internet connection with either ethernet or wifi

```
ping 8.8.8.8
```

Sync pacman:
```
pacman -Syy
```

Install reflector:
```
pacman -S reflector
```

Get best performant mirrors and update mirrorlist:
```
reflector -c "ZA" -f 12 -l 10 -n 12 --save /etc/pacman.d/mirrorlist
```
---
### Installation

Mount root partition:
```
mount /dev/sda2 /mnt
```

Install base system:
```
pacstrap /mnt base base-devel linux linux-firmware linux-headers vim
```
---
### Configure fresh install

Generate fstab:
```
genfstab -U /mnt >> /mnt/etc/fstab
```

Chroot into newly installed system
```
arch-chroot /mnt
```

Set the timezone:
```
timedatectl set-timezone Africa/Johannesburg
```

Set the locale:
```
vim /etc/locale.gen

# Uncomment
en_ZA.UTF-8
```

Generate the locale config:
```
locale-gen
echo LANG=en_ZA.UTF-8 > /etc/locale.conf
export LANG=en_ZA.UTF-8
```

Set the hostname:
```
echo archbox > /etc/hostname
```

Configure hosts file:
```
vim /etc/hosts

# Add the following:
127.0.0.1       localhost
::1             localhost
127.0.1.1       archbox
```

Set the root password:
```
passwd
```
---
### Install bootloader

Install grub and efibootmgr:
```
pacman -S grub efibootmgr
```

Create EFI boot mountpoint directory:
```
mkdir /boot/efi
```

Mount the ESP partition:
```
mount /dev/sda1 /boot/efi
```

Install grub:
```
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
```

Create GRUB config:
```
grub-mkconfig -o /boot/grub/grub.cfg
```

Install and enable NetworkManager:
```
pacman -S networkmanager
systemctl enable NetworkManager.service
```

Reboot:
```
reboot
```

---
### Post Installation
Install sudo:
```
pacman -S sudo
```

Add new user and set password
```
useradd --create-home new_user
passwd new_user
```

Add the new user to Wheel group:
```
usermod --append --groups wheel new_user
```

Edit sudoers file and give wheel sudo privileges:
```
visudo

### Uncomment
%wheel ALL=(ALL) ALL
```
---
### Install AUR helper

Install git and golang:
```
sudo pacman -S git go
```

In home directory clone yay:
```
cd ~/
sudo git clone https://aur.archlinux.org/yay-git.git
cd yay-git
```

Build and install yay:
```
makepkg -si
```
---
### Install Xorg and GPU drivers

Enable multilib for 32bit support:
```
vim /etc/pacman.conf

#Uncomment
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Upgrade system after multilib enable:
```
sudo pacman -Syu
```

Install xorg and dkms:
```
sudo pacman -S xorg dkms 
```

For Nvidia:
```
sudo pacman -S nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader
```

For AMD:
```
sudo pacman -S lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader
```

For Intel:
```
sudo pacman -S lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader
```
---
### Install Plasma
I don't install `kde-applications` to keep it as minimalistic as possible.

```
sudo pacman -S plasma plasma-wayland-session
```

Install KDE thumbnail render dependencies:
```
sudo pacman -S kdegraphics-thumbnailers kio-extras
```

Install de/compression tools:
```
sudo pacman -S bzip2 gzip lzip xz p7zip unrar zip unzip
```

Install a few applications:
```
sudo pacman -S konsole kate dolphin kcolorchooser krita okular vlc ark firefox chromium vlc
```

Enable SDDM:
```
systemctl enable sddm.service
```
---
### Auto mount second disk with Fstab
Create mount point directory:
```
sudo mkdir /mnt/sdb1
```

Retrieve UUID for the second disk:
```
lsblk -f
```

Edit Fstab file:
```
sudo vim /etc/fstab
```

Append the following with previously retrieved UUID:
```
UUID=f574a9e1-51d1-4483-b26e-dfbe858ac2c3        /mnt/sdb1      ext4        defaults        0 2
```

Reboot.

Change ownership of mount point to enable writing to disk:
```
sudo chown new_user:wheel /mnt/sdb1
```

---
### Fix screen tearing on plasma (Nvidia)

Under `System Settings` -> `Display and Monitor` -> `Compositor`:
`Tearing prevention("vsync")` set to `Never`

Install `force-composition-pipeline.sh` to:
```
~/.config/autostart-scripts/force-composition-pipeline.sh
```

Make it executable:
```
chmod +x ~/.config/autostart-scripts/force-composition-pipeline.sh
```

Credit to [vitkin](https://unix.stackexchange.com/users/316930/vitkin) - [Source](https://unix.stackexchange.com/questions/510757/how-to-automatically-force-full-composition-pipeline-for-nvidia-gpu-driver#answer-550695)

---
### Install Realtek 8125B 2.5G LAN controller driver
Build and install the Realtek driver:
```
cd r8125
sudo sh ./autorun.sh
```
---
### Install OpenSSH
```
sudo pacman -S openssh
```

Install xclip to copy SSH key from terminal:
```
sudo pacman -S xclip
```

---
### Install development tools from the AUR
Install sublime-text and Visual Studio Code
```
yay -S visual-studio-code-bin
yay -S sublime-text-3
```
---
### Install credentials manager for ssh key passphrases
Credit to [Feakster](https://forum.manjaro.org/u/Feakster) - [Source](https://archived.forum.manjaro.org/t/howto-use-kwallet-as-a-login-keychain-for-storing-ssh-key-passphrases-on-manjaro-arm-kde/115719)

Install required packages:
```
sudo pacman -S kwallet ksshaskpass kwalletmanager kwallet-pam signon-kwallet-extension
```
Install `ssh-agent.sh` to:
```
~/.config/plasma-workspace/env/ssh-agent.sh
```
Make it executable:
```
chmod u+x ~/.config/plasma-workspace/env/ssh-agent.sh
```

Set `SSH_ASKPASS` environment variable - install `askpass.sh` to:
```
~/.config/plasma-workspace/env/askpass.sh
```
Make it executable:
```
chmod u+x ~/.config/plasma-workspace/env/askpass.sh
```

Create an ssh-add startup script - install `ssh-add.sh` to:
```
~/.config/autostart-scripts/ssh-add.sh
```
Make it executable:
```
chmod u+x ~/.config/autostart-scripts/ssh-add.sh
```

Logout or reboot

Add your SSH key passphrases to kwallet:
```
ssh-add /path/to/key < /dev/null
```
---
### Install fonts

Make new fonts directory:
```
sudo mkdir /usr/share/fonts/WinFonts
```

Copy fonts to new directory:
```
cp ~/WinFonts/* /usr/share/fonts/WinFonts/
```

Change permissions on new fonts and directory:
```
chmod 644 /usr/share/fonts/WinFonts/*
```

Regenerate the fontconfig cache:
```
fc-cache --force
```