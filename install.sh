#!/bin/bash

# ==============================================================================
# CHUNK 1: MIRROR OPTIMIZATION (MAX SPEED)
# ==============================================================================
echo ":: [1/6] Optimizing Mirrors with Reflector..."
# Installs reflector to find fastest servers
if ! command -v reflector &> /dev/null; then
    sudo pacman -S --noconfirm reflector
fi
# Save 5 fastest HTTPS mirrors
sudo reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
echo ":: Mirrors optimized."

# ==============================================================================
# CHUNK 2: PACKAGE INSTALLATION (CLEANED)
# ==============================================================================
echo ":: [2/6] Installing Base System (No Swayidle, Added Recorder)..."

# Removed: swayidle, nvidia
# Added: wf-recorder (screen recording)
PACKAGES="sway swaybg swaylock foot fuzzel mako \
wl-clipboard grim slurp imv pcmanfm-qt \
pipewire pipewire-pulse wireplumber pamixer \
lxsession xcursor-vanilla-dmz \
inter-font ttf-jetbrains-mono-nerd ttf-font-awesome \
fish eza fzf starship \
mpv ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav \
zed power-profiles-daemon unzip wf-recorder \
noto-fonts pipewire-jack"

sudo pacman -S --needed --noconfirm $PACKAGES

# ==============================================================================
# CHUNK 3: AUR & SYSTEM OPTIMIZATION
# ==============================================================================
echo ":: [3/6] Setting up AUR & Power Management..."

# 3.1 Install Yay (if missing)
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ..
    rm -rf yay-bin
fi

# 3.2 Install AUR Packages (LibreWolf + Themes + Pfetch)
yay -S --noconfirm librewolf-bin gruvbox-dark-gtk pfetch

# 3.3 Power Management (Fixed with Wait Loop)
echo ":: Setting Power Profile..."
sudo systemctl enable --now power-profiles-daemon.service
# Wait up to 5 seconds for service to be active
for i in {1..5}; do
    if systemctl is-active --quiet power-profiles-daemon; then
        break
    fi
    sleep 1
done

# Force Performance Mode
if command -v powerprofilesctl &> /dev/null; then
    powerprofilesctl set performance || echo ":: Warning: 'performance' mode not supported on this hardware."
fi

# 3.4 Disable Sleep/Suspend permanently
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# ==============================================================================
# CHUNK 4: CONFIGURATION - SCRIPTS
# ==============================================================================
echo ":: [4/6] Creating Helper Scripts..."
mkdir -p ~/.config/{sway,foot,fuzzel,fish,mako,pcmanfm-qt/default}
mkdir -p ~/.local/bin

# --- 4.1 Audio Selector Script ---
cat <<EOF > ~/.local/bin/audio-selector.sh
#!/bin/bash
sink=\$(pactl list short sinks | cut -f 2 | fuzzel --dmenu --prompt="Audio Output: " --lines=5 --width=50)
if [ -n "\$sink" ]; then
    pactl set-default-sink "\$sink"
    pactl list short sink-inputs | cut -f 1 | xargs -I {} pactl move-sink-input {} "\$sink"
fi
EOF
chmod +x ~/.local/bin/audio-selector.sh

# --- 4.2 Screen Recording Script (Toggle) ---
cat <<EOF > ~/.local/bin/record-screen.sh
#!/bin/bash
PIDFILE="/tmp/recording.pid"
if [ -f "\$PIDFILE" ]; then
    kill -SIGINT \$(cat "\$PIDFILE")
    rm "\$PIDFILE"
    notify-send "Recording Stopped" "Saved to ~/Videos"
else
    mkdir -p ~/Videos
    TIMESTAMP=\$(date +%Y-%m-%d_%H-%M-%S)
    wf-recorder -f ~/Videos/recording_\$TIMESTAMP.mp4 &
    echo \$! > "\$PIDFILE"
    notify-send "Recording Started" "Recording to ~/Videos/recording_\$TIMESTAMP.mp4"
fi
EOF
chmod +x ~/.local/bin/record-screen.sh

# --- 4.3 Zed CLI Symlink ---
if [ ! -f /usr/bin/zed ] && [ -f /usr/bin/zeditor ]; then
    sudo ln -s /usr/bin/zeditor /usr/bin/zed
fi

# ==============================================================================
# CHUNK 5: CONFIGURATION - SWAY & VISUALS
# ==============================================================================
echo ":: [5/6] Generating Sway Config..."

# --- 5.1 Sway Config ---
cat <<EOF > ~/.config/sway/config
# --- Variables ---
set \$mod Mod4
set \$term foot
set \$menu fuzzel

# --- Visuals (Gruvbox + Transparency) ---
font pango:Inter 10
default_border pixel 2
gaps inner 5
gaps outer 0

# Transparency (Glass Effect) - 95% Opacity
for_window [app_id=".*"] opacity 0.95
for_window [class=".*"] opacity 0.95

# Colors                Border  Backgr. Text    Indicator Child Border
client.focused          #d79921 #282828 #ebdbb2 #d79921   #d79921
client.focused_inactive #3c3836 #3c3836 #a89984 #3c3836   #3c3836
client.unfocused        #3c3836 #3c3836 #a89984 #3c3836   #3c3836
client.urgent           #cc241d #cc241d #ebdbb2 #cc241d   #cc241d

# --- 4K Monitor Scaling ---
output * scale 2
output * bg #282828 solid_color

# --- Input ---
input * {
    xkb_layout "us"
    repeat_delay 300
    repeat_rate 50
    tap enabled
}

# --- Cursor ---
seat seat0 xcursor_theme Vanilla-DMZ 48

# --- Status Bar ---
bar {
    position top
    # Custom Format: HH:MM:SS PM  |  DD-MM-YYYY
    status_command while date +'%I:%M:%S %p  |  %d-%m-%Y'; do sleep 1; done

    colors {
        statusline #ebdbb2
        background #282828
        inactive_workspace #282828 #282828 #a89984
        focused_workspace  #282828 #d79921 #282828
        active_workspace   #282828 #3c3836 #ebdbb2
        urgent_workspace   #282828 #cc241d #ebdbb2
    }
}

# --- Keybindings ---
bindsym \$mod+Return exec \$term
bindsym \$mod+Shift+q kill
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+c reload
# Minimal Dark Lock
bindsym \$mod+l exec swaylock -c 1d2021
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes' 'swaymsg exit'

# Apps
bindsym \$mod+b exec librewolf
bindsym \$mod+c exec zed
bindsym \$mod+Shift+Enter exec pcmanfm-qt

# Audio Selector (Super+A)
bindsym \$mod+a exec ~/.local/bin/audio-selector.sh

# --- Custom Keys (No Print Screen / Compact Keyboard) ---
# Screenshots
bindsym \$mod+p exec grim ~/Pictures/screenshot_\$(date +%s).png
bindsym \$mod+Shift+s exec grim -g "\$(slurp)" ~/Pictures/screenshot_\$(date +%s).png

# Screen Recording (Toggle)
bindsym \$mod+Shift+r exec ~/.local/bin/record-screen.sh

# Volume (Super + Plus/Minus)
bindsym \$mod+equal exec pamixer -i 5
bindsym \$mod+minus exec pamixer -d 5
bindsym \$mod+0 exec pamixer -t

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

# Workspaces 1-5
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
exec /usr/lib/lxpolkit/lxpolkit
EOF

# ==============================================================================
# CHUNK 6: CONFIGURATION - THEMING & SHELL
# ==============================================================================

# --- 6.1 Mako (Notifications) - Gruvbox ---
cat <<EOF > ~/.config/mako/config
font=Inter 10
background-color=#282828
text-color=#ebdbb2
border-color=#d79921
border-size=2
default-timeout=5000
EOF

# --- 6.2 Fish & Starship (Pure Prompt) ---
# Initialize Starship Pure Preset
starship preset pure-preset -o ~/.config/starship.toml

cat <<EOF > ~/.config/fish/config.fish
if status is-interactive
    set fish_greeting
    
    # Run pfetch on start
    pfetch

    alias ls='eza -al --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'
    alias vim='zed' 
    
    starship init fish | source
end

# 4K & Theme Variables
set -gx GDK_SCALE 2
set -gx QT_SCALE_FACTOR 2
set -gx XCURSOR_SIZE 48
set -gx GTK_THEME "Gruvbox-Dark"
EOF

# --- 6.3 Finalize ---
echo ":: [6/6] Finalizing..."
systemctl --user enable --now wireplumber.service pipewire-pulse.service
chsh -s /usr/bin/fish

echo ":: ---------------------------------------------------"
echo ":: INSTALL COMPLETE."
echo ":: Type 'sway' to start."
echo ":: ---------------------------------------------------"
