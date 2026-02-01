#!/bin/bash

# 1. OFFICIAL PACKAGES
PACKAGES="sway swaybg foot fuzzel mako xorg-xwayland waybar \
pipewire pipewire-pulse wireplumber pamixer \
wob wf-recorder btop imv \
wl-clipboard cliphist grim slurp \
mesa vulkan-radeon libva-mesa-driver \
thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp ntfs-3g udiskie unzip zip file-roller \
tumbler ffmpegthumbnailer poppler-glib \
ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav \
polkit-gnome power-profiles-daemon python-gobject glib2 libnotify libappindicator-gtk3 \
xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
xcursor-vanilla-dmz ttf-jetbrains-mono-nerd ttf-font-awesome inter-font noto-fonts \
fish eza fzf starship zed mpv qt5-wayland qt6-wayland qbittorrent"

sudo pacman -S --needed --noconfirm $PACKAGES

# 2. AUR PACKAGES
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && cd .. && rm -rf yay-bin
fi

yay -S --noconfirm librewolf-bin fastfetch gtklock

# 3. FIXES
if [ -f /usr/bin/zeditor ]; then
    sudo ln -sf /usr/bin/zeditor /usr/bin/zed
fi

sudo systemctl enable --now power-profiles-daemon.service
sudo chsh -s /bin/bash $(whoami)

echo ":: Install Complete."
