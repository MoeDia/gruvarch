#!/bin/bash

# ==============================================================================
# PRE-FLIGHT
# ==============================================================================
if [ ! -f "./classroom.jpg" ]; then
    echo ":: ERROR: 'classroom.jpg' missing. Place it next to this script."
    exit 1
fi

# ==============================================================================
# CHUNK 1: CORE PACKAGES (Lightweight)
# ==============================================================================
echo ":: [1/6] Installing Core System..."

# Added: fastfetch, qt5-styleplugins (AUR later) for sure-fire theming
PACKAGES="sway swaybg foot fuzzel mako \
wl-clipboard grim slurp imv pcmanfm-qt \
pipewire pipewire-pulse wireplumber pamixer \
lxsession xcursor-vanilla-dmz \
ttf-jetbrains-mono-nerd ttf-font-awesome inter-font \
fish eza fzf starship mpv ffmpeg zed power-profiles-daemon \
unzip wf-recorder noto-fonts pipewire-jack python-gobject glib2 wob"

sudo pacman -S --needed --noconfirm $PACKAGES

# Optimize Mirrors (Crucial for speed)
if ! command -v reflector &> /dev/null; then sudo pacman -S --noconfirm reflector; fi
sudo reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# ==============================================================================
# CHUNK 2: AUR (Theming & Lock)
# ==============================================================================
echo ":: [2/6] Installing AUR Essentials..."
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && cd .. && rm -rf yay-bin
fi

# qt5-styleplugins: The magic package that makes Qt apps look like GTK
# swaylock-effects-git: Required for Blur
yay -S --noconfirm librewolf-bin gruvbox-dark-gtk swaylock-effects-git qt5-styleplugins fastfetch

# ==============================================================================
# CHUNK 3: SURE-FIRE THEMING (GTK + Qt Sync)
# ==============================================================================
echo ":: [3/6] Forcing Deep Dark Theme..."

# 1. Force GTK Settings (The Source of Truth)
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cat <<EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Gruvbox-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrainsMono Nerd Font 10
gtk-cursor-theme-name=Vanilla-DMZ
gtk-application-prefer-dark-theme=1
EOF
cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

# 2. Force Qt to read GTK settings (The Sure-Fire Fix for PCManFM)
# We do not use qt5ct anymore. We use gtk2 platform theme.
# The variable is set in the Fish config below.

# ==============================================================================
# CHUNK 4: CONFIGURATION (Sway & Bar)
# ==============================================================================
echo ":: [4/6] Configuring Sway..."
mkdir -p ~/.config/sway ~/.config/swaylock

# Wallpaper
mkdir -p ~/Pictures/Wallpapers
cp "./classroom.jpg" ~/Pictures/Wallpapers/classroom.jpg

# --- Sway Config ---
cat <<EOF > ~/.config/sway/config
# Variables
set \$mod Mod4
set \$term foot
set \$menu fuzzel

# Visuals (JetBrains Font)
font pango:JetBrainsMono Nerd Font 10
default_border pixel 2
output * scale 2
output * bg ~/Pictures/Wallpapers/classroom.jpg fill

# Transparency
for_window [app_id=".*"] opacity 0.95

# Gruvbox Colors
client.focused          #d79921 #282828 #ebdbb2 #d79921   #d79921
client.focused_inactive #3c3836 #3c3836 #a89984 #3c3836   #3c3836
client.unfocused        #3c3836 #3c3836 #a89984 #3c3836   #3c3836

# Bar (JetBrains Font + Clean)
bar {
    position top
    font pango:JetBrainsMono Nerd Font Bold 10
    
    # Recording Indicator Logic
    status_command while true; do \
        if [ -f /tmp/recording.pid ]; then \
            echo "🔴 REC | \$(date +'%I:%M %p')"; \
        else \
            echo "\$(date +'%I:%M %p | %d-%m-%Y')"; \
        fi; \
        sleep 1; \
    done

    colors {
        statusline #ebdbb2
        background #282828
        focused_workspace  #282828 #d79921 #282828
        active_workspace   #282828 #3c3836 #ebdbb2
        inactive_workspace #282828 #282828 #a89984
    }
}

# --- Inputs ---
input * {
    xkb_layout "us"
    repeat_delay 300
    repeat_rate 50
    tap enabled
}
seat seat0 xcursor_theme Vanilla-DMZ 48

# --- Volume (Wob Only) ---
set \$WOBSOCK \$XDG_RUNTIME_DIR/wob.sock
exec mkfifo \$WOBSOCK && tail -f \$WOBSOCK | wob
bindsym \$mod+equal exec pamixer -i 5 && pamixer --get-volume > \$WOBSOCK
bindsym \$mod+minus exec pamixer -d 5 && pamixer --get-volume > \$WOBSOCK
# Removed Super+0 mute binding

# --- Keybindings ---
bindsym \$mod+Return exec \$term
bindsym \$mod+Shift+q kill
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes' 'swaymsg exit'

# Apps
bindsym \$mod+b exec librewolf
bindsym \$mod+c exec zed --disable-gpu
bindsym \$mod+Shift+Return exec pcmanfm-qt

# Lock Screen (Omarchy Style - Blurred, Minimal)
bindsym \$mod+Escape exec swaylock \
    --screenshots \
    --clock \
    --indicator \
    --indicator-radius 120 \
    --indicator-thickness 10 \
    --effect-blur 10x5 \
    --effect-vignette 0.5:0.5 \
    --ring-color 282828 \
    --key-hl-color d79921 \
    --text-color ebdbb2 \
    --line-color 00000000 \
    --inside-color 00000088 \
    --separator-color 00000000 \
    --fade-in 0.2

# Screenshots & Recording
bindsym \$mod+p exec grim ~/Pictures/shot_\$(date +%s).png
bindsym \$mod+Shift+s exec grim -g "\$(slurp)" ~/Pictures/shot_\$(date +%s).png
bindsym \$mod+Shift+r exec ~/.local/bin/record-screen.sh

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

# Autostart
exec /usr/lib/lxpolkit/lxpolkit
EOF

# ==============================================================================
# CHUNK 5: SHELL & EXTRAS
# ==============================================================================
echo ":: [5/6] Finalizing Shell..."

# Fish Config (Fastfetch + Theme Vars)
cat <<EOF > ~/.config/fish/config.fish
if status is-interactive
    set fish_greeting
    fastfetch
    alias ls='eza -al --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'
    alias vim='zed' 
    starship init fish | source
end

# SURE-FIRE DARK MODE VARS
set -gx GTK_THEME "Gruvbox-Dark"
# This forces Qt apps to look exactly like GTK apps
set -gx QT_QPA_PLATFORMTHEME "gtk2"
set -gx GDK_SCALE 2
set -gx QT_SCALE_FACTOR 2
set -gx XCURSOR_SIZE 48
EOF

# Wob Config
mkdir -p ~/.config/wob
cat <<EOF > ~/.config/wob/wob.ini
timeout = 1000
max = 100
width = 400
height = 40
border_size = 2
bar_color = d79921
border_color = 282828
background_color = 282828
EOF

# Recording Script
mkdir -p ~/.local/bin
cat <<EOF > ~/.local/bin/record-screen.sh
#!/bin/bash
PIDFILE="/tmp/recording.pid"
if [ -f "\$PIDFILE" ]; then
    kill -SIGINT \$(cat "\$PIDFILE")
    rm "\$PIDFILE"
else
    mkdir -p ~/Videos
    wf-recorder -f ~/Videos/recording_\$(date +%s).mp4 &
    echo \$! > "\$PIDFILE"
fi
EOF
chmod +x ~/.local/bin/record-screen.sh

# Power & Services
sudo systemctl enable --now power-profiles-daemon.service
sudo systemctl mask sleep.target suspend.target
systemctl --user enable --now wireplumber.service pipewire-pulse.service
chsh -s /usr/bin/fish

echo ":: ---------------------------------------------------"
echo ":: INSTALL COMPLETE."
echo ":: ---------------------------------------------------"
