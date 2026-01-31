#!/bin/bash

# Check for wallpaper file first
if [ ! -f "./classroom.jpg" ]; then
    echo ":: ERROR: 'classroom.jpg' not found in the current directory."
    echo ":: Please place the wallpaper file next to this script and try again."
    exit 1
fi

# ==============================================================================
# CHUNK 1: MIRROR OPTIMIZATION
# ==============================================================================
echo ":: [1/7] Optimizing Mirrors..."
if ! command -v reflector &> /dev/null; then
    sudo pacman -S --noconfirm reflector
fi
sudo reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# ==============================================================================
# CHUNK 2: PACKAGE INSTALLATION (FIXED)
# ==============================================================================
echo ":: [2/7] Installing Base System..."

# Added: python-gobject (for powerprofilesctl), glib2 (for gsettings), wob (volume OSD)
PACKAGES="sway swaybg swaylock foot fuzzel mako \
wl-clipboard grim slurp imv pcmanfm-qt \
pipewire pipewire-pulse wireplumber pamixer \
lxsession xcursor-vanilla-dmz \
inter-font ttf-jetbrains-mono-nerd ttf-font-awesome \
fish eza fzf starship \
mpv ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav \
zed power-profiles-daemon unzip wf-recorder \
noto-fonts pipewire-jack python-gobject glib2 wob"

sudo pacman -S --needed --noconfirm $PACKAGES

# ==============================================================================
# CHUNK 3: AUR, POWER & SYSTEM THEME
# ==============================================================================
echo ":: [3/7] Setting up AUR, Power & Theme..."

# 3.1 Install Yay
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ..
    rm -rf yay-bin
fi

# 3.2 Install AUR Packages
yay -S --noconfirm librewolf-bin gruvbox-dark-gtk pfetch

# 3.3 Apply GTK Theme Globally
echo ":: Applying Gruvbox Theme..."
# This is necessary for apps like LibreWolf to pick up the theme
gsettings set org.gnome.desktop.interface gtk-theme 'Gruvbox-Dark'
gsettings set org.gnome.desktop.interface font-name 'Inter 10'
gsettings set org.gnome.desktop.interface cursor-theme 'Vanilla-DMZ'

# 3.4 Power Management
sudo systemctl enable --now power-profiles-daemon.service
sleep 3
if command -v powerprofilesctl &> /dev/null; then
    powerprofilesctl set performance || echo ":: Warning: 'performance' mode not supported."
fi
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# ==============================================================================
# CHUNK 4: WALLPAPER SETUP
# ==============================================================================
echo ":: [4/7] Setting up Wallpaper..."
mkdir -p ~/Pictures/Wallpapers
cp "./classroom.jpg" ~/Pictures/Wallpapers/classroom.jpg

# ==============================================================================
# CHUNK 5: HELPER SCRIPTS
# ==============================================================================
echo ":: [5/7] Creating Scripts..."
mkdir -p ~/.config/{sway,foot,fuzzel,fish,mako,pcmanfm-qt/default,swaylock}
mkdir -p ~/.local/bin

# Audio Selector
cat <<EOF > ~/.local/bin/audio-selector.sh
#!/bin/bash
sink=\$(pactl list short sinks | cut -f 2 | fuzzel --dmenu --prompt="Audio Output: " --lines=5 --width=50)
if [ -n "\$sink" ]; then
    pactl set-default-sink "\$sink"
    pactl list short sink-inputs | cut -f 1 | xargs -I {} pactl move-sink-input {} "\$sink"
fi
EOF
chmod +x ~/.local/bin/audio-selector.sh

# Screen Recorder
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

# Zed Symlink
if [ ! -f /usr/bin/zed ] && [ -f /usr/bin/zeditor ]; then
    sudo ln -s /usr/bin/zeditor /usr/bin/zed
fi

# ==============================================================================
# CHUNK 6: CONFIGURATION FILES
# ==============================================================================
echo ":: [6/7] Generating Configs..."

# --- 6.1 Sway Config (Corrected) ---
cat <<EOF > ~/.config/sway/config
# --- Variables ---
set \$mod Mod4
set \$term foot
set \$menu fuzzel

# --- Visuals ---
font pango:Inter 10
default_border pixel 2
gaps inner 5
gaps outer 0
# Transparency
for_window [app_id=".*"] opacity 0.95
for_window [class=".*"] opacity 0.95

# Gruvbox Colors
client.focused          #d79921 #282828 #ebdbb2 #d79921   #d79921
client.focused_inactive #3c3836 #3c3836 #a89984 #3c3836   #3c3836
client.unfocused        #3c3836 #3c3836 #a89984 #3c3836   #3c3836
client.urgent           #cc241d #cc241d #ebdbb2 #cc241d   #cc241d

# --- Output & Wallpaper ---
output * scale 2
output * bg ~/Pictures/Wallpapers/classroom.jpg fill

# --- Input & Seat ---
input * {
    xkb_layout "us"
    repeat_delay 300
    repeat_rate 50
    tap enabled
}
seat seat0 xcursor_theme Vanilla-DMZ 48

# --- Volume OSD Setup (wob) ---
set \$WOBSOCK \$XDG_RUNTIME_DIR/wob.sock
exec mkfifo \$WOBSOCK && tail -f \$WOBSOCK | wob

# --- Status Bar ---
bar {
    position top
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
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes' 'swaymsg exit'

# --- Fixed/New Keybindings ---
# Lock Screen (Changed from 'l' to 'Escape' to fix conflict)
bindsym \$mod+Escape exec swaylock

# Apps (Fixed 'Enter' to 'Return')
bindsym \$mod+b exec librewolf
bindsym \$mod+c exec zed
bindsym \$mod+Shift+Return exec pcmanfm-qt

# Volume with OSD
bindsym \$mod+equal exec pamixer -i 5 && pamixer --get-volume > \$WOBSOCK
bindsym \$mod+minus exec pamixer -d 5 && pamixer --get-volume > \$WOBSOCK
bindsym \$mod+0 exec pamixer -t && (pamixer --get-mute && echo 0 || pamixer --get-volume) > \$WOBSOCK

# Audio Selector
bindsym \$mod+a exec ~/.local/bin/audio-selector.sh

# Screenshots & Recording
bindsym \$mod+p exec grim ~/Pictures/screenshot_\$(date +%s).png
bindsym \$mod+Shift+s exec grim -g "\$(slurp)" ~/Pictures/screenshot_\$(date +%s).png
bindsym \$mod+Shift+r exec ~/.local/bin/record-screen.sh

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
exec /usr/lib/lxpolkit/lxpolkit
EOF

# --- 6.2 Swaylock Config (Gruvbox) ---
cat <<EOF > ~/.config/swaylock/config
color=282828
ring-color=d79921
key-hl-color=b8bb26
line-color=d79921
inside-color=282828
separator-color=d79921
text-color=ebdbb2
layout-txt-color=ebdbb2
ring-clear-color=cc241d
inside-clear-color=282828
line-clear-color=cc241d
ring-ver-color=98971a
inside-ver-color=282828
line-ver-color=98971a
EOF

# --- 6.3 Mako Config ---
cat <<EOF > ~/.config/mako/config
font=Inter 10
background-color=#282828
text-color=#ebdbb2
border-color=#d79921
border-size=2
default-timeout=5000
EOF

# --- 6.4 Foot Config ---
cat <<EOF > ~/.config/foot/foot.ini
[main]
font=JetBrainsMono Nerd Font:size=10
pad=10x10
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

# --- 6.5 Fuzzel Config ---
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

# --- 6.6 Fish & Starship Config ---
starship preset pure-preset -o ~/.config/starship.toml
cat <<EOF > ~/.config/fish/config.fish
if status is-interactive
    set fish_greeting
    pfetch
    alias ls='eza -al --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'
    alias vim='zed' 
    starship init fish | source
end
set -gx GDK_SCALE 2
set -gx QT_SCALE_FACTOR 2
set -gx XCURSOR_SIZE 48
# Set GTK theme for apps that read env vars
set -gx GTK_THEME "Gruvbox-Dark"
EOF

# ==============================================================================
# CHUNK 7: FINALIZE
# ==============================================================================
echo ":: [7/7] Finalizing..."
systemctl --user enable --now wireplumber.service pipewire-pulse.service
chsh -s /usr/bin/fish

echo ":: ---------------------------------------------------"
echo ":: INSTALL COMPLETE."
echo ":: New Keybindings:"
echo ":: - Lock Screen: Super + Escape"
echo ":: - File Manager: Super + Shift + Return"
echo ":: - Zed Editor: Super + C"
echo ":: - Volume: Super + (=/-)"
echo ":: Type 'sway' to start."
echo ":: ---------------------------------------------------"
