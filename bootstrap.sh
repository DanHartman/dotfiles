#!/usr/bin/env bash
set -euo pipefail
DIR="$( cd "$( dirname "${0}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_NAME=$(basename "$0")

# utils
yay -S curl wget rsync

# can I get a desktop?
yay -S i3-wm xorg-xinit rofi
mkdir -p ${HOME}/Pictures
curl "https://images.pexels.com/photos/2156/sky-earth-space-working.jpg" > ${HOME}/Pictures/wallpaper.jpg

# fonts
yay -S ttf-droid ttf-iosevka ttf-font-awesome noto-fonts-emoji

# audio
yay -S pulseaudio pamixer

# browsers
yay -S google-chrome firefox
sudo xdg-mime default google-chrome.desktop x-scheme-handler/http
sudo xdg-mime default google-chrome.desktop x-scheme-handler/https
sudo xdg-mime default google-chrome.desktop text/ht

# shell
yay -S zsh antibody alacritty
test -d ~/liquidprompt && rm -rf ~/liquidprompt
cd ~ && git clone https://github.com/nojhan/liquidprompt.git

# chat
yay -S zoom

# dev
yay -S jq go code-git keybase docker docker-compose linux-aufs virtualbox virtualbox-host-modules-arch vagrant xclip
sudo systemctl enable docker
sudo systemctl start docker
sudo gpasswd -a "${USER}" docker

# networking
yay -S wpa_supplicant iwlwifi resolvconf openconnect
sudo systemctl enable wpa_supplicant
sudo gpasswd -a "${USER}" network
yay -R dhcpcd
