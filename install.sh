#!/bin/bash

# ==============================================================================
# PRE-FLIGHT
# ==============================================================================
if [ ! -f "./classroom.jpg" ]; then
    echo ":: ERROR: 'classroom.jpg' missing. Place it next to this script."
    exit 1
fi

# ==============================================================================
# CHUNK 1: CORE PACKAGES & CODECS
# ==============================================================================
echo ":: [1/4] Installing Optimized Core..."

# Core Desktop
PACKAGES="sway swaybg foot fuzzel mako \
pipewire pipewire-pulse wireplumber pamixer \
wl-clipboard grim slurp imv \
wob wf-recorder"

# File Management (Thunar + Archives + Drives)
PACKAGES+=" thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp ntfs-3g udiskie unzip"

# Media Codecs (Comprehensive)
PACKAGES+=" ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav"

# System Internals
PACKAGES+=" polkit-gnome power-profiles-daemon python-gobject glib2 libnotify"

# Fonts & Visuals (No Terminus)
PACKAGES+=" xcursor-vanilla-dmz ttf-jetbrains-mono-nerd ttf-font-awesome inter-font noto-fonts"

# Shell & Tools
PACKAGES+=" fish eza fzf starship zed mpv imagemagick"

sudo pacman -S --needed --noconfirm $PACKAGES

# Speed up future downloads
if ! command -v reflector &> /dev/null; then sudo pacman -S --noconfirm reflector; fi
sudo reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# ==============================================================================
# CHUNK 2: AUR ESSENTIALS
# ==============================================================================
echo ":: [2/4] Installing AUR Tools..."

if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && cd .. && rm -rf yay-bin
fi

# gtklock: The lockscreen
# fastfetch: System info
# librewolf-bin: Browser
yay -S --noconfirm librewolf-bin gtklock fastfetch

# ==============================================================================
# CHUNK 3: CONFIGURATION
# ==============================================================================
echo ":: [3/4] Configuring Functionality..."

# 1. Prepare Directories
mkdir -p ~/.config/{sway,foot,fuzzel,fish,mako,gtklock}
mkdir -p ~/.local/bin
mkdir -p ~/Pictures/Wallpapers

# 2. Wallpaper
cp "./classroom.jpg" ~/Pictures/Wallpapers/classroom.jpg

# 3. Fish Shell (TTY Separation Logic)
cat <<EOF > ~/.config/fish/config.fish
if status is-interactive
    set fish_greeting
    
    # Common Aliases
    alias ls='eza -al --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'
    
    # Starship (Runs everywhere)
    starship init fish | source

    # GUI-Only Logic (Sway)
    if set -q WAYLAND_DISPLAY
        # Only run fastfetch in the GUI, not the TTY
        fastfetch
        
        # Sure-Fire Dark Theme Variables (GUI Only)
        set -gx GTK_THEME "Gruvbox-Dark"
        set -gx QT_QPA_PLATFORMTHEME "gtk2"
        set -gx GDK_SCALE 2
        set -gx QT_SCALE_FACTOR 2
        set -gx XCURSOR_SIZE 48
    end
end
EOF

# 4. Starship Prompt (Hostname ALWAYS Visible)
cat <<EOF > ~/.config/starship.toml
[hostname]
ssh_only = false
format = "[\$hostname](bold blue) "
disabled = false

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[directory]
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = " "
style = "bold yellow"
EOF

# 5. Gtklock Config (Basic Gruvbox)
cat <<EOF > ~/.config/gtklock/config.ini
[main]
gtk-theme=Gruvbox-Dark
EOF

# 6. Sway Config (Instant Exit + Gruvbox)
cat <<EOF > ~/.config/sway/config
# --- Variables ---
set \$mod Mod4
set \$term foot
set \$menu fuzzel

# --- Visuals ---
font pango:JetBrainsMono Nerd Font 10
default_border pixel 2
output * scale 2
output * bg ~/Pictures/Wallpapers/classroom.jpg fill

# --- Inputs ---
input * {
    xkb_layout "us"
    repeat_delay 300
    repeat_rate 50
    tap enabled
}
seat seat0 xcursor_theme Vanilla-DMZ 48

# --- Bar (Clean, JetBrains Font) ---
bar {
    position top
    font pango:JetBrainsMono Nerd Font Bold 10
    status_command while date +'%I:%M %p | %d-%m-%Y'; do sleep 1; done
    colors {
        statusline #ebdbb2
        background #282828
        focused_workspace  #282828 #d79921 #282828
        active_workspace   #282828 #3c3836 #ebdbb2
        inactive_workspace #282828 #282828 #a89984
    }
}

# --- Audio (Wob Integration) ---
set \$WOBSOCK \$XDG_RUNTIME_DIR/wob.sock
exec mkfifo \$WOBSOCK && tail -f \$WOBSOCK | wob
bindsym \$mod+equal exec pamixer -i 5 && pamixer --get-volume > \$WOBSOCK
bindsym \$mod+minus exec pamixer -d 5 && pamixer --get-volume > \$WOBSOCK

# --- Keybindings ---
bindsym \$mod+Return exec \$term
bindsym \$mod+Shift+q kill
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+c reload
# INSTANT EXIT (No Warning)
bindsym \$mod+Shift+e exec swaymsg exit

# Apps
bindsym \$mod+b exec librewolf
bindsym \$mod+c exec zed --disable-gpu
bindsym \$mod+Shift+Return exec thunar

# Lock Screen (Gtklock)
bindsym \$mod+Escape exec gtklock

# Screenshots & Recording
bindsym \$mod+p exec grim ~/Pictures/shot_\$(date +%s).png
bindsym \$mod+Shift+s exec grim -g "\$(slurp)" ~/Pictures/shot_\$(date +%s).png
bindsym \$mod+Shift+r exec ~/.local/bin/record-screen.sh

# Navigation
bindsym \$mod+h focus left
bindsym \$mod+j focus down
bindsym \$mod+k focus up
bindsym \$mod+l focus right

# Workspaces
bindsym \$mod+1 workspace 1
bindsym \$mod+2 workspace 2
bindsym \$mod+3 workspace 3
bindsym \$mod+4 workspace 4
bindsym \$mod+5 workspace 5
bindsym \$mod+Shift+1 move container to workspace 1
bindsym \$mod+Shift+2 move container to workspace 2
bindsym \$mod+Shift+3 move container to workspace 3
bindsym \$mod+Shift+4 move container to workspace 4
bindsym \$mod+Shift+5 move container to workspace 5

# --- Autostart ---
exec /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec udiskie --tray
exec mako
EOF

# ==============================================================================
# CHUNK 4: HELPER SCRIPTS
# ==============================================================================
echo ":: [4/4] Finalizing Services..."

# Recording Script (Simple)
cat <<EOF > ~/.local/bin/record-screen.sh
#!/bin/bash
PIDFILE="/tmp/recording.pid"
if [ -f "\$PIDFILE" ]; then
    kill -SIGINT \$(cat "\$PIDFILE")
    rm "\$PIDFILE"
    notify-send "Recording" "Stopped."
else
    mkdir -p ~/Videos
    wf-recorder -f ~/Videos/recording_\$(date +%s).mp4 &
    echo \$! > "\$PIDFILE"
    notify-send "Recording" "Started..."
fi
EOF
chmod +x ~/.local/bin/record-screen.sh

# Services
sudo systemctl enable --now power-profiles-daemon.service
sudo systemctl mask sleep.target suspend.target
systemctl --user enable --now wireplumber.service pipewire-pulse.service
chsh -s /usr/bin/fish

echo ":: ---------------------------------------------------"
echo ":: FOUNDATION INSTALLED."
echo ":: ---------------------------------------------------"
