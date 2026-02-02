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
wl-clipboard grim slurp \
mesa vulkan-radeon libva-mesa-driver \
thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp ntfs-3g udiskie unzip zip file-roller \
tumbler ffmpegthumbnailer poppler-glib \
ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav \
polkit-gnome power-profiles-daemon python-gobject glib2 libnotify libappindicator-gtk3 \
xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk \
xcursor-vanilla-dmz ttf-jetbrains-mono-nerd ttf-font-awesome inter-font noto-fonts \
fish eza fzf starship zed mpv qt5-wayland qt6-wayland qbittorrent papirus-icon-theme \
gsettings-desktop-schemas gnome-themes-extra nwg-look imagemagick terminus-font \
pyside6 python-certifi python-pem python-pyopenssl python-pyqt5 python-service-identity shiboken6 syncplay"

sudo pacman -S --needed --noconfirm $PACKAGES

# 2. AUR PACKAGES
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && cd .. && rm -rf yay-bin
fi

yay -S --noconfirm librewolf-bin fastfetch gtklock gruvbox-material-gtk-theme-git spotify

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

echo ":: Configuring Limine Theme (GruvArch)..."

# 1. Copy the pre-made background image to /boot
if [ -f "limine_bg.png" ]; then
    sudo cp limine_bg.png /boot/
    echo ":: Background image copied to /boot."
else
    echo "!! WARNING: limine_bg.png not found in current directory. Skipping image copy."
fi

# 2. Define the Gruvbox Theme Header
# We save this to a temp file first
cat <<EOF > /tmp/limine_theme_header.conf
# --- GRUVARCH THEME START ---
timeout: 5
interface_branding: GruvArch
interface_branding_colour: 3  # Yellow (mapped below)

# Wallpaper
wallpaper: boot():/limine_bg.png
wallpaper_style: stretched

# Text Colors
term_background: 282828
term_foreground: ebdbb2

# Palette Overrides (Gruvbox Dark)
# Standard: Black;Red;Green;Brown(Yellow);Blue;Magenta;Cyan;Gray
term_palette: 282828;cc241d;98971a;d79921;458588;b16286;689d6a;a89984

# Bright: DkGray;BrtRed;BrtGreen;Yellow;BrtBlue;BrtMagenta;BrtCyan;White
term_palette_bright: 928374;fb4934;b8bb26;fabd2f;83a598;d3869b;8ec07c;ebdbb2
# --- GRUVARCH THEME END ---

EOF

# 3. Prepend the header to the existing config
# We concatenate the HEADER + EXISTING CONFIG -> NEW CONFIG
if [ -f /boot/limine.conf ]; then
    # Create a temporary combined file
    cat /tmp/limine_theme_header.conf /boot/limine.conf > /tmp/limine_full.conf
    
    # Move it back to /boot (overwrite existing)
    sudo mv /tmp/limine_full.conf /boot/limine.conf
    echo ":: Limine config updated (Theme added to top)."
else
    echo "!! ERROR: /boot/limine.conf not found. Cannot apply theme."
fi

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
