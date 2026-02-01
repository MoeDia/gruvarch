#!/bin/bash

# ==============================================================================
# PRE-FLIGHT CHECK
# ==============================================================================
if [ ! -f "./classroom.jpg" ]; then
    echo ":: ERROR: 'classroom.jpg' missing. Place it next to this script."
    exit 1
fi

# ==============================================================================
# 1. INSTALLATION
# ==============================================================================
echo ":: [1/4] Installing Production Packages..."

# Core Wayland & Audio
PACKAGES="sway swaybg foot fuzzel mako \
pipewire pipewire-pulse wireplumber pamixer \
wl-clipboard grim slurp imv \
wob wf-recorder btop"

# Clipboard Manager (Persistence)
PACKAGES+=" cliphist"

# Screen Sharing (Portal Bridge)
PACKAGES+=" xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk"

# GPU Drivers (AMD RX 6400 Specific)
PACKAGES+=" mesa vulkan-radeon libva-mesa-driver"

# File Management (Thumbnails Included)
PACKAGES+=" thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp ntfs-3g udiskie unzip \
tumbler ffmpegthumbnailer poppler-glib"

# Media Codecs
PACKAGES+=" ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav"

# System Tools
PACKAGES+=" polkit-gnome power-profiles-daemon python-gobject glib2 libnotify"

# Fonts & Visuals
PACKAGES+=" xcursor-vanilla-dmz ttf-jetbrains-mono-nerd ttf-font-awesome inter-font noto-fonts"

# Shell & Utilities
PACKAGES+=" fish eza fzf starship zed mpv"

sudo pacman -S --needed --noconfirm $PACKAGES

# ==============================================================================
# 2. REFLECTOR (MIRROR FIX FOR UAE)
# ==============================================================================
echo ":: [2/4] Optimizing Mirrors (Targeting DE/NL/SG for Speed)..."

# Installs Reflector
if ! command -v reflector &> /dev/null; then sudo pacman -S --noconfirm reflector; fi

# The Strategy:
# 1. --country DE,NL,SG: These usually have the best routing for UAE.
# 2. --latest 20: Only check fresh servers.
# 3. --download-timeout 20: Gives them 20s to respond before "Timing Out".
sudo reflector \
    --country 'Germany,Netherlands,Singapore,United Arab Emirates' \
    --latest 20 \
    --protocol https \
    --sort rate \
    --download-timeout 20 \
    --save /etc/pacman.d/mirrorlist

echo ":: Mirrors Updated."

# ==============================================================================
# 3. AUR ESSENTIALS
# ==============================================================================
echo ":: [3/4] Installing AUR Tools..."

if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && cd .. && rm -rf yay-bin
fi

yay -S --noconfirm librewolf-bin fastfetch

# ==============================================================================
# 4. CRITICAL FIXES (Zed & Shell)
# ==============================================================================
echo ":: [3/4] Applying Binary & Shell Fixes..."

# FIX: Zed Binary Name
if [ -f /usr/bin/zeditor ]; then
    sudo ln -sf /usr/bin/zeditor /usr/bin/zed
fi

# FIX: TTY vs Foot Separation
echo ":: Resetting system shell to Bash (for TTY)..."
sudo chsh -s /bin/bash $(whoami)

# ==============================================================================
# 5. CONFIGURATION
# ==============================================================================
echo ":: [4/4] Writing Configurations..."
mkdir -p ~/.config/{sway,foot,fuzzel,fish,mako,wob}
mkdir -p ~/.local/bin
mkdir -p ~/Pictures/Wallpapers

# Wallpaper Setup
cp "./classroom.jpg" ~/Pictures/Wallpapers/classroom.jpg

# --- A. Helper Scripts (Audio Selector) ---
cat <<EOF > ~/.local/bin/audio-selector.sh
#!/bin/bash
sink=\$(pactl list short sinks | cut -f 2 | fuzzel --dmenu --prompt="Audio Output: " --lines=5 --width=50)
if [ -n "\$sink" ]; then
    pactl set-default-sink "\$sink"
    pactl list short sink-inputs | cut -f 1 | xargs -I {} pactl move-sink-input {} "\$sink"
fi
EOF
chmod +x ~/.local/bin/audio-selector.sh

# --- B. Fish Shell (Updated with Mirror Test) ---
cat <<EOF > ~/.config/fish/config.fish
if status is-interactive
    set fish_greeting
    
    alias ls='eza -al --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'

    # Test Mirrors Alias
    alias test-mirrors='sudo reflector --country "Germany,Netherlands,Singapore" --latest 5 --sort rate --save /etc/pacman.d/mirrorlist'

    # GUI Tools (Always run because TTY is Bash)
    fastfetch
    starship init fish | source
    
    # Critical for Screen Sharing
    set -gx XDG_CURRENT_DESKTOP sway
    set -gx XDG_SESSION_DESKTOP sway
end
EOF

# --- C. Starship (Pure Preset) ---
cat <<EOF > ~/.config/starship.toml
[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold green)"

[directory]
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
format = "on [\$symbol\$branch]($style) "
symbol = " "
style = "bold yellow"

[git_status]
format = '([\$all_status\$ahead_behind]($style) )'
style = "bold red"

[cmd_duration]
format = "took [\$duration]($style) "
style = "yellow"

[hostname]
ssh_only = false
format = "[\$hostname](bold blue) "
disabled = false

[line_break]
disabled = false

[package]
disabled = true
EOF

# --- D. Foot (FORCES FISH) ---
cat <<EOF > ~/.config/foot/foot.ini
[main]
font=JetBrainsMono Nerd Font:size=10
pad=10x10
shell=/usr/bin/fish

[colors]
alpha=1.0
background=282828
foreground=ebdbb2
regular0=282828
regular1=cc241d
regular2=98971a
regular3=d79921
regular4=458588
regular5=b16286
regular6=689d6a
regular7=a89984
bright0=928374
bright1=fb4934
bright2=b8bb26
bright3=fabd2f
bright4=83a598
bright5=d3869b
bright6=8ec07c
bright7=ebdbb2
EOF

# --- E. Fuzzel (Gruvbox) ---
cat <<EOF > ~/.config/fuzzel/fuzzel.ini
[main]
font=JetBrainsMono Nerd Font:size=11
terminal=foot -e
width=40
lines=10
horizontal-pad=20
vertical-pad=10
inner-pad=5

[colors]
background=282828ff
text=ebdbb2ff
match=fabd2fff
selection=d79921ff
selection-text=282828ff
border=d79921ff
EOF

# --- F. Wob (Gruvbox Volume Bar) ---
cat <<EOF > ~/.config/wob/wob.ini
timeout = 1000
max = 100
width = 400
height = 50
border_size = 2
bar_color = d79921
border_color = 282828
background_color = 282828
EOF

# --- G. Mako (Gruvbox Notifications) ---
cat <<EOF > ~/.config/mako/config
font=JetBrainsMono Nerd Font 10
background-color=#282828
text-color=#ebdbb2
border-color=#d79921
border-size=2
default-timeout=5000
EOF

# --- H. Sway Config (Fixed Clipboard & Portals) ---
cat <<EOF > ~/.config/sway/config
# --- Variables ---
set \$mod Mod4
set \$term foot
set \$menu fuzzel

# --- Visuals ---
font pango:JetBrainsMono Nerd Font Regular 10
default_border pixel 2
gaps inner 5
gaps outer 0

# Transparency
for_window [app_id=".*"] opacity 0.95

# Gruvbox Colors
client.focused          #d79921 #282828 #ebdbb2 #d79921   #d79921
client.focused_inactive #3c3836 #3c3836 #a89984 #3c3836   #3c3836
client.unfocused        #3c3836 #3c3836 #a89984 #3c3836   #3c3836
client.urgent           #cc241d #cc241d #ebdbb2 #cc241d   #cc241d

# --- Output ---
output * scale 2
output * bg ~/Pictures/Wallpapers/classroom.jpg fill

# --- Input ---
input * {
    xkb_layout "us"
    repeat_delay 300
    repeat_rate 50
    tap enabled
}
seat seat0 xcursor_theme Vanilla-DMZ 48

# --- Bar ---
bar {
    position top
    font pango:JetBrainsMono Nerd Font Regular 10
    
    # Format: 04:30:15 PM | Sun 01-02-2026
    status_command while date +'%I:%M:%S %p | %a %d-%m-%Y'; do sleep 1; done

    colors {
        statusline #ebdbb2
        background #282828
        inactive_workspace #282828 #282828 #a89984
        focused_workspace  #282828 #d79921 #282828
        active_workspace   #282828 #3c3836 #ebdbb2
        urgent_workspace   #282828 #cc241d #ebdbb2
    }
}

# --- Audio (Wob) ---
set \$WOBSOCK \$XDG_RUNTIME_DIR/wob.sock
exec mkfifo \$WOBSOCK && tail -f \$WOBSOCK | wob
bindsym \$mod+equal exec pamixer -i 5 && pamixer --get-volume > \$WOBSOCK
bindsym \$mod+minus exec pamixer -d 5 && pamixer --get-volume > \$WOBSOCK

# --- Keybindings ---
bindsym \$mod+Return exec \$term
bindsym \$mod+Shift+q kill
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaymsg exit

# Apps
bindsym \$mod+b exec librewolf
bindsym \$mod+c exec zed
bindsym \$mod+Shift+Return exec thunar

# Helper Scripts
bindsym \$mod+a exec ~/.local/bin/audio-selector.sh
bindsym \$mod+Shift+r exec ~/.local/bin/record-screen.sh

# Screenshots (CLIPBOARD PERSISTENCE)
# We pipe to 'wl-copy' AND save to file.
# Note: cliphist must be running (see autostart) to save this after the command ends.
bindsym \$mod+p exec grim - | tee ~/Pictures/shot_\$(date +%s).png | wl-copy && notify-send "Screenshot" "Full Screen Copied"
bindsym \$mod+Shift+s exec grim -g "\$(slurp)" - | tee ~/Pictures/shot_\$(date +%s).png | wl-copy && notify-send "Screenshot" "Region Copied"

# Navigation
bindsym \$mod+h focus left
bindsym \$mod+j focus down
bindsym \$mod+k focus up
bindsym \$mod+l focus right

# Moving windows
bindsym \$mod+Shift+h move left
bindsym \$mod+Shift+j move down
bindsym \$mod+Shift+k move up
bindsym \$mod+Shift+l move right

# Layout
bindsym \$mod+f fullscreen
bindsym \$mod+s layout stacking
bindsym \$mod+w layout tabbed
bindsym \$mod+e layout toggle split

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
# 1. Screen Sharing Portals (Must run first)
exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway

# 2. Permissions
exec /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# 3. CLIPBOARD MANAGER (Critical for Persistence)
# This daemon catches your copies so they don't vanish
exec wl-paste --watch cliphist store

# 4. Other Services
exec udiskie --tray
exec mako
exec /usr/lib/xdg-desktop-portal-wlr
EOF

# ==============================================================================
# 6. FINAL STEPS
# ==============================================================================
echo ":: [4/4] Finalizing..."

# Recording Script
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

# Power & Services
sudo systemctl enable --now power-profiles-daemon.service
if command -v powerprofilesctl &> /dev/null; then
    powerprofilesctl set performance
fi

# Disable Sleep
sudo systemctl mask sleep.target suspend.target

# Enable Audio
systemctl --user enable --now wireplumber.service pipewire-pulse.service

echo ":: ---------------------------------------------------"
echo ":: INSTALL COMPLETE."
echo ":: 1. Clipboard Manager (Cliphist) is now active."
echo ":: 2. Reflector updated (Targeting DE/NL/SG)."
echo ":: 3. Thumbnails enabled."
echo ":: ---------------------------------------------------"
