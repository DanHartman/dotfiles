# document from arch installation medium to bootable dell 2019 xps7590 running arch linux

## UEFI settings
* enter BIOS: press F2 @ poweron
* expand "System Configuration"
  * Select "SATA Operation"
  * Click "AHCI" radio button
  * Agree to popup warning
  * Click Apply
  * Select "USB Configuration"
  * Verify "Enable USB Boot Support" is checked
* expand "Secure Boot"
  * Select "Secure Boot Enable"
  * Uncheck "Secure Boot Enable"
  * Agree to popup warning
  * Click Apply
* expand "POST Behavior"
  * Select "Fastboot"
  * Click "Thorough" radio button
  * Click Apply
* insert installation medium USB
* click "Exit"

## Live USB
* Boot from USB: press F12 @ poweron
* Arrow key to select USB drive
* Press Enter
  * Text was TINY
  * But it is shonuff working

## Keyboard layout
no mod, left as default

## Verify boot mode
* `ls /sys/firmware/efi/efivars`
  * no error occured, which means it is booted in UEFI mode

## Connect to internet
```sh
ip link
iwctl
  device list
  station wlan0 scan
  station wlan0 get-networks
  station wlan0 connect ${YOUR_SSID}
  exit
```

## Update system clock
`timedatectl set-ntp true`

## Partitioning
* `fdisk /dev/nvme0n1`
* `d` (delete partition)
  * `3` (Microsoft basic data 936.7G)
* `n` (make new partition)
  * `3` (the previously deleted slot)
  * hit enter for default first sector
  * `+870G` (create 870GB partition)
  * `Y` (remove bitlocker signature)
* `n` (make new partition)
  * `7` (next available partition number)
  * hit enter for default first sector
  * `+64G` (create 64GB partition for swap)
* `t` (change partition type)
  * `7` (partition number created for swap)
  * `19` (for linux swap)
* `w` (write partition changes)

## Formatting
* `mkfs.ext4 /dev/nvme0n1p3`
* `y` (to prompt warning that it contained DOS/MBR boot sector data)
* `mkswap /dev/nvme0n1p7`

## Mount file systems
* `mount /dev/nvme0n1p3 /mnt`
* `swapon /dev/nvme0n1p7`

## Update keyring in case install medium is older
`pacman -Sy archlinux-keyring`

## Install essential packages
`pacstrap /mnt base linux linux-firmware vim networkmanager`

## Configure the system
`genfstab -U /mnt >> /mnt/etc/fstab`

## Chroot
`arch-chroot /mnt`

## Time zone
```sh
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc
date (verify)
```

## Localization
* `vim /etc/locale.gen`
  * uncomment en_US.UTF-8 UTF-8
* `locale-gen`
* `echo "LANG=en_US.UTF-8" > /etc/locale.conf`

## Network
```sh
echo "riker" > /etc/hostname
cat <<EOF >> /etc/hosts

127.0.0.1 localhost
::1       localhost
127.0.1.1 riker.localdomain riker
EOF
```

## Root password
`passwd`

## Boot loader
* `pacman -S grub efibootmgr`
* `mkdir /boot/EFI`
* `fdisk -l | grep EFI | awk '{ print $1 }'` to see which partition on the internal drive is the EFI System
  * `mount /dev/nvme0n1p1 /boot/EFI/`
* `grub-install --target=x86_64-efi --efi-directory=/boot/EFI/ --bootloader-id=GRUB`
* update `/etc/default/grub` with the following items
```sh
  GRUB_DEFAULT=saved
  GRUB_TIMEOUT=3
  GRUB_DISABLE_SUBMENU=y
  uncomment GRUB_COLOR_NORMAL
  uncomment GRUB_SAVEDEFAULT
```
* `grub-mkconfig -o /boot/grub/grub.cfg`

## Microcode
```sh
pacman -S intel-ucode
grub-mkconfig -o /boot/grub/grub.cfg
```

## MAKEPKG MultiProcessor Builds
* `vim /etc/makepkg.conf`
  * uncomment `#MAKEFLAGS=-j2`
  * edit line to read: `MAKEFLAGS="-j$(nproc)"`

## User
* `pacman -S sudo`
* `visudo`
  * uncomment to allow members of group wheel to execute any command
* `useradd -g wheel ${USER}`
* `mkdir /home/${USER}`
* `usermod -d /home/${USER} -m ${USER}`
* `passwd ${USER}`

## Power management
* udpate `/etc/default/grub` with the following
```sh
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet mem_sleep_default=deep"
```
* `grub-mkconfig -o /boot/grub/grub.cfg`

## YAY
```sh
pacman -S git base-devel
cd /opt/
git clone https://aur.archlinux.org/yay-git.git
chown -R ${USER}:wheel ./yay-git/
cd yay-git/
sudo su ${USER}
sudo chown -R ${USER}:wheel /home/${USER}
makepkg -si
exit
```

## Powertop
```sh
# install package
pacman -S powertop

# run auto-tune on boot
cat <<'EOF' > /etc/systemd/system/powertop.service
[Unit]
Description=Powertop tunings

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/powertop --auto-tune
ExecStartPost=/bin/sh -c 'for f in $(grep -l "Mouse" /sys/bus/usb/devices/*/product | sed "s/product/power\\/control/"); do echo on >| "$f"; done'

[Install]
WantedBy=multi-user.target
EOF
```

## Dotfiles
```sh
sudo su ${USER}
cd ${HOME}
git clone https://github.com/DanHartman/dotfiles.git
cd dotfiles
arch-xps7590/bootstrap.sh
./install.sh
```
## known_hosts
`curl "https://github.com/danhartman.keys" >> ${HOME}/.ssh/authorized_keys`

## update grub with since new kernel(s) may have been installed
`grub-mkconfig -o /boot/grub/grub.cfg`

## make sure NetworkManager is enabled
`sudo systemctl enable NetworkManager`
`sudo systemctl start NetworkManager`

## Reboot
```sh
exit
umount -R /mnt
reboot
```
