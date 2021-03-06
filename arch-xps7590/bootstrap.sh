#!/usr/bin/env bash
set -euo pipefail
DIR="$( cd "$( dirname "${0}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_NAME=$(basename "$0")

echo "update system"
sudo pacman -Syu

echo "utils"
yay -S curl wget rsync xdg-utils htop openssh inetutils

echo "can I get a desktop?"
yay -S i3-wm i3status xorg-xinit rofi xorg-server dmenu xf86-input-libinput feh flameshot
mkdir -p ${HOME}/Pictures
mkdir -p ${HOME}/Pictures/Screenshots
curl "https://images.pexels.com/photos/2156/sky-earth-space-working.jpg" > ${HOME}/Pictures/wallpaper.jpg

echo "fonts"
yay -S ttf-droid ttf-iosevka ttf-font-awesome noto-fonts-emoji

echo "audio"
yay -S pulseaudio pamixer alsa-utils pavucontrol

echo "video"
sudo gpasswd -a "${USER}" video

echo "browsers"
yay -S google-chrome
sudo xdg-mime default google-chrome-stable.desktop x-scheme-handler/http
sudo xdg-mime default google-chrome-stable.desktop x-scheme-handler/https
sudo xdg-mime default google-chrome-stable.desktop text/ht
cat <<EOF > "${HOME}/.local/share/applications/mimeapps.list"
x-scheme-handler/http=google-chrome-stable.desktop
x-scheme-handler/https=google-chrome-stable.desktop
text/ht=google-chrome-stable.desktop
EOF

echo "shell"
yay -S zsh alacritty
test -d ~/liquidprompt && rm -rf ~/liquidprompt
cd ~ && git clone https://github.com/nojhan/liquidprompt.git

echo "chat"
yay -S zoom signal-desktop

echo "dev"
yay -S jq go atom docker docker-compose virtualbox virtualbox-host-modules-arch vagrant xclip
sudo systemctl enable docker
sudo systemctl start docker
sudo gpasswd -a "${USER}" docker

echo "networking"
yay -S wpa_supplicant resolvconf openconnect networkmanager-openconnect
sudo systemctl enable wpa_supplicant
sudo gpasswd -a "${USER}" network
sudo systemctl enable systemd-resolved
sudo systemctl start systemd-resolved

echo "backlight kernel"
yay -S linux-oled
