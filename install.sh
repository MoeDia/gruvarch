#!/bin/bash

mkdir -p ~/.config
mkdir -p ~/.local/bin
mkdir -p ~/Pictures/Wallpapers

# Copy wallpaper
cp classroom.jpg ~/Pictures/Wallpapers/

echo ":: Copying Dotfiles..."
# Copy the contents of your repo's .config to the system .config
cp -r .config/* ~/.config/

# Copy the contents of your repo's .local to the system .local
cp -r .local/* ~/.local/

chmod +x ~/.local/bin/*

# Make Waybar scripts executable
if [ -d ~/.config/waybar/scripts ]; then
    chmod +x ~/.config/waybar/scripts/*
fi

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
fish eza fzf starship zed mpv qt5-wayland qt6-wayland qbittorrent papirus-icon-theme gsettings-desktop-schemas gnome-themes-extra nwg-look"

sudo pacman -S --needed --noconfirm $PACKAGES

# 2. AUR PACKAGES
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && cd .. && rm -rf yay-bin
fi

yay -S --noconfirm librewolf-bin fastfetch gtklock gruvbox-material-gtk-theme-git

# 3. FIXES
if [ -f /usr/bin/zeditor ]; then
    sudo ln -sf /usr/bin/zeditor /usr/bin/zed
fi

echo ":: Applying GTK Theme (Gruvbox)..."
# This forces the settings into the database immediately
gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-Material-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd Font 10"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

sudo systemctl enable --now power-profiles-daemon.service
sudo chsh -s /bin/bash $(whoami)


echo ":: Install Complete."
