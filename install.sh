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

# 1. OFFICIAL PACKAGES
PACKAGES="sway swaybg foot fuzzel mako xorg-xwayland waybar \
pipewire pipewire-pulse wireplumber pamixer \
wob wf-recorder btop imv \
wl-clipboard grim slurp \
mesa vulkan-radeon libva-mesa-driver \
thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp ntfs-3g udiskie unzip zip file-roller \
tumbler ffmpegthumbnailer poppler-glib \
ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav \
polkit-gnome power-profiles-daemon python-gobject glib2 libnotify libappindicator-gtk3 \
xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
xcursor-vanilla-dmz ttf-jetbrains-mono-nerd ttf-font-awesome inter-font noto-fonts \
fish eza fzf starship zed mpv qt5-wayland qt6-wayland qbittorrent \
gsettings-desktop-schemas gnome-themes-extra nwg-look imagemagick terminus-font \
pyside6 python-certifi python-pem python-pyopenssl python-pyqt5 python-service-identity shiboken6 syncplay"

sudo pacman -S --needed --noconfirm $PACKAGES

# 2. AUR PACKAGES
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && cd .. && rm -rf yay-bin
fi

yay -S --noconfirm librewolf-bin fastfetch gtklock gruvbox-material-gtk-theme-git spotify gruvbox-plus-icon-theme-git

# 3. FIXES
if [ -f /usr/bin/zeditor ]; then
    sudo ln -sf /usr/bin/zeditor /usr/bin/zed
fi

# Set default editor as Zed
echo 'export EDITOR="zed --wait"' >> ~/.bashrc
echo 'export VISUAL="zed --wait"' >> ~/.bashrc

echo ":: Applying GTK Theme (Gruvbox)..."
# This forces the settings into the database immediately
gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-Material-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Gruvbox-Plus-Dark"
gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd Font 10"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

sudo systemctl enable --now power-profiles-daemon.service
sudo chsh -s /bin/bash $(whoami)

echo ":: Configuring Limine Theme (GruvArch)..."

# 1. Define the possible locations (Most common vs. Alternative)
# Installers usually put it in /boot/limine/limine.conf or /boot/limine.conf
LIMINE_CONF=""

if [ -f "/boot/limine/limine.conf" ]; then
    LIMINE_CONF="/boot/limine/limine.conf"
elif [ -f "/boot/limine.conf" ]; then
    LIMINE_CONF="/boot/limine.conf"
elif [ -f "/limine/limine.conf" ]; then
    LIMINE_CONF="/limine/limine.conf"
fi

# 2. Check if we found it
if [ -z "$LIMINE_CONF" ]; then
    echo "!! ERROR: Could not find limine.conf in standard locations."
    echo "!! Please check if /boot is mounted or if Limine is installed."
    # We exit this block but don't crash the whole script
    return 1 2>/dev/null || exit 1
else
    echo ":: Found Limine config at: $LIMINE_CONF"
fi

# 3. Copy the background image to the SAME folder as the config
# (This ensures the bootloader can actually see the image file)
CONF_DIR=$(dirname "$LIMINE_CONF")

if [ -f "limine_bg.png" ]; then
    sudo cp limine_bg.png "$CONF_DIR/"
    echo ":: Background image copied to $CONF_DIR/"
else
    echo "!! WARNING: limine_bg.png not found in current directory."
fi

# 4. Create the Header
cat <<EOF > /tmp/limine_theme_header.conf
# --- GRUVARCH THEME START ---
timeout: 5
interface_branding: GruvArch
interface_branding_colour: 3

# Wallpaper (Points to the image in the same folder)
wallpaper: boot():/limine_bg.png
wallpaper_style: stretched

# Colors
term_background: 282828
term_foreground: ebdbb2
term_palette: 282828;cc241d;98971a;d79921;458588;b16286;689d6a;a89984
term_palette_bright: 928374;fb4934;b8bb26;fabd2f;83a598;d3869b;8ec07c;ebdbb2
# --- GRUVARCH THEME END ---

EOF

# 5. Prepend safely to the detected file
cat /tmp/limine_theme_header.conf "$LIMINE_CONF" > /tmp/limine_full.conf
sudo mv /tmp/limine_full.conf "$LIMINE_CONF"
echo ":: Limine config updated successfully at $LIMINE_CONF."

# Cleanup
rm /tmp/limine_theme_header.conf
echo ":: Configuring TTY (Font & Colors)..."

# 1. Configure vconsole.conf for BIG text
# 'ter-132n' is Terminus, 32px high (Very readable on 1080p/4k)
echo "FONT=ter-132n" | sudo tee /etc/vconsole.conf

# 2. Set Text Color to Gruvbox Cream on Login
# We add a command to your shell profile that changes the text color
# immediately when you log into the TTY.
echo 'if [ "$TERM" = "linux" ]; then
    echo -en "\e]P0282828" # Black -> Gruvbox Dark
    echo -en "\e]P7ebdbb2" # White -> Gruvbox Cream
    clear # Apply changes
fi' >> ~/.bash_profile

echo ":: TTY configured (Big Font + Gruvbox Colors)."

echo ":: Install Complete."
