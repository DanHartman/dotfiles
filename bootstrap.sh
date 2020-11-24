#!/usr/bin/env bash
set -euo pipefail
DIR="$( cd "$( dirname "${0}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_NAME=$(basename "$0")

# utils
yay -S curl wget rsync xdg-utils htop

# can I get a desktop?
yay -S i3-wm i3status xorg-xinit rofi xorg-server dmenu
mkdir -p ${HOME}/Pictures
curl "https://images.pexels.com/photos/2156/sky-earth-space-working.jpg" > ${HOME}/Pictures/wallpaper.jpg

# fonts
yay -S ttf-droid ttf-iosevka ttf-font-awesome noto-fonts-emoji

# audio
yay -S pulseaudio pamixer alsa-utils

# browsers
yay -S google-chrome firefox
xdg-mime default google-chrome-stable.desktop x-scheme-handler/http
xdg-mime default google-chrome-stable.desktop x-scheme-handler/https
xdg-mime default google-chrome-stable.desktop text/ht

# shell
yay -S zsh alacritty
test -d ~/liquidprompt && rm -rf ~/liquidprompt
cd ~ && git clone https://github.com/nojhan/liquidprompt.git

# chat
yay -S zoom signal-desktop

# dev
sudo pacman -Syu
yay -S jq go atom docker docker-compose linux-aufs virtualbox virtualbox-host-modules-arch vagrant xclip
sudo systemctl enable docker
sudo systemctl start docker
sudo gpasswd -a "${USER}" docker

# networking
yay -S wpa_supplicant iwlwifi resolvconf openconnect networkmanager-openconnect
sudo systemctl enable wpa_supplicant
sudo gpasswd -a "${USER}" network
yay -R dhcpcd
