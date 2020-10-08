# Personal Arch Linux install guide
This guide was written for my own personal use.

## Disclaimer
No liability for the contents of this documents can be accepted. Use the concepts, examples and other content at your own risk. There may be errors and inaccuracies, that may of course be damaging to your system. Although this is highly unlikely, you should proceed with caution. The author does not accept any responsibility for any damage incurred.

---
## Update the system clock
```
timedatectl set-ntp true
```
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
### Arch Linux installation

Mount root partition:
```
mount /dev/sda2 /mnt
```

Install base system:
```
pacstrap /mnt base base-devel linux linux-firmware linux-headers util-linux vim htop
```
---
### Configure Arch Linux installation

Generate Fstab file:
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
OR
```
ln -sf /usr/share/zoneinfo/Africa/Johannesburg /etc/localtime
hwclock --systohc
```

Set the locale:
```
vim /etc/locale.gen

### Uncomment
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

### Add the following:
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

Install GRUB and efibootmgr:
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

Install GRUB:
```
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
```

Create GRUB config:
```
grub-mkconfig -o /boot/grub/grub.cfg
```

---
### Install and enable NetworkManager
```
pacman -S networkmanager
systemctl enable NetworkManager.service
```
Reboot:
```
reboot
```
---
### Add local user account and install sudo
```
pacman -S sudo
```

Add new user and set password
```
useradd --create-home new_user
passwd new_user
```

Add the new user to wheel group:
```
usermod --append --groups wheel new_user
```

Edit sudoers file and give wheel group sudo privileges:
```
visudo

### Uncomment
%wheel ALL=(ALL) ALL
```
---
### Enable TRIM scheduling for SSDs
```
sudo systemctl enable fstrim.timer
```
---
### Install AUR (Arch User Repository) helper

Install git and golang:
```
sudo pacman -S git go
```

In home directory clone yay:
```
cd ~/
git clone https://aur.archlinux.org/yay-git.git
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
sudo vim /etc/pacman.conf

### Uncomment
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Upgrade system after multilib enable:
```
sudo pacman -Syu
```

Install Xorg and dkms:
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
### Install Plasma desktop environment
For a minimalistic Arch Linux installation, I don't install `kde-applications`.

Install Plasma:
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
sudo pacman -S konsole kate dolphin partitionmanager kcolorchooser krita okular vlc ark kget transmission-qt acetoneiso2 firefox chromium
```

Enable SDDM:
```
sudo systemctl enable sddm.service
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
UUID=<your-uuid-here>        /mnt/sdb1      ext4        defaults        0 2
```

Reboot.
```
reboot
```

Change ownership of mount point to enable writing to disk:
```
sudo chown new_user:wheel /mnt/sdb1
```

---
### Fix screen tearing on Plasma (Nvidia)

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

*Credit to: [vitkin](https://unix.stackexchange.com/users/316930/vitkin) - [Source](https://unix.stackexchange.com/questions/510757/how-to-automatically-force-full-composition-pipeline-for-nvidia-gpu-driver#answer-550695)*

---
### Install Realtek 8125B 2.5G LAN controller driver
Build and install the Realtek driver:
```
cd r8125
sudo sh ./autorun.sh
```
---
### Install support for NTFS drives and partitions
```
sudo pacman -S ntfs-3g
```
---
### Install OpenSSH and add SSH key to ssh-agent
```
sudo pacman -S openssh
```
Start ssh-agent:
```
eval "$(ssh-agent -s)"
```
Close down permissions on existing SSH key:
```
chmod 400 ~/.ssh/id_rsa
```
Add SSH key to ssh-agent:
```
ssh-add ~/.ssh/id_rsa
```
---
### Install development tools from the AUR (Arch User Repository)
Install Sublime Text 3 and Visual Studio Code
```
yay -S visual-studio-code-bin
yay -S sublime-text-3
```

Install powerline patched programming fonts:
```
yay -S awesome-terminal-fonts-git
yay -S powerline-fonts-git
yay -S nerd-fonts-source-code-pro
yay -S nerd-fonts-fira-code
```
---
### Install powerline-go
```
go get -u github.com/justjanne/powerline-go
```

Add this to `.bashrc`:
```
GOPATH=$HOME/go

function _update_ps1() {
    PS1="$($GOPATH/bin/powerline-go -error $?)"
}
if [ "$TERM" != "linux" ] && [ -f "$GOPATH/bin/powerline-go" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi
```

Source `.bashrc` to update with new PS1:
```
source ~/.bashrc
```
---
### Install development tools from the Arch repo
Install Geany and Dbeaver:
```
sudo pacman -S geany dbeaver
```

Install Python 3:
```
sudo pacman -S python python-pip
```

Install Go:
```
sudo pacman -S go
```
---
### Docker installation
```
sudo pacman -S docker docker-compose
```

Add user to the `docker` group (requires restart):
```
sudo usermod --append --groups docker new_user
```

Start Docker service:
```
sudo systemctl start docker.service
```

Stop Docker service:
```
sudo systemctl stop docker.service
```

Get status of Docker service:
```
systemctl status docker
```

Verify Docker operation:
```
docker info
```

Test Docker installation with Arch Linux image and return `hello world`:
```
docker run -it --rm archlinux bash -c "echo hello world"
```

Install Kitematic:
```
yay -S kitematic
```

---
### Install credential manager for SSH key passphrases
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

**NB: Remember to set password for kwallet!**

**Configuration for more than one key:**

In `ssh-add.sh` replace:
```
ssh-add -q < /dev/null
```
with:
```
ssh-add -q ~/.ssh/key1 ~/.ssh/key2 ~/.ssh/key3 < /dev/null
```
Reboot.

Run this for each of your SSH private keys to store their passphrases in `kwallet`:
```
ssh-add /path/to/key < /dev/null
```

Reboot.

*Credit to: [Feakster](https://forum.manjaro.org/u/Feakster) - [Source](https://archived.forum.manjaro.org/t/howto-use-kwallet-as-a-login-keychain-for-storing-ssh-key-passphrases-on-manjaro-arm-kde/115719)*

---
### Install fonts

Make new fonts directory:
```
sudo mkdir /usr/share/fonts/WinFonts
```

Copy fonts to new directory:
```
sudo cp ~/WinFonts/* /usr/share/fonts/WinFonts/
```

Change permissions on new fonts and directory:
```
sudo chmod 644 /usr/share/fonts/WinFonts/*
```

Regenerate the fontconfig cache:
```
fc-cache --force
```