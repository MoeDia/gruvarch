#!/bin/bash

# ==============================================================================
# PRE-FLIGHT CHECK
# ==============================================================================
if [ ! -f "./classroom.jpg" ]; then
    echo ":: ERROR: 'classroom.jpg' missing. Place it next to this script."
    exit 1
fi

# ==============================================================================
# CHUNK 1: CORE PACKAGES (Fixed for VM & Theming)
# ==============================================================================
echo ":: [1/7] Installing Dependencies..."

# Added: vulkan-swrast (Fixes Zed in VM), chafa (Images in terminal), 
# qt5ct/qt6ct (Fixes PCManFM theme), wob (Gruvbox volume bar)
PACKAGES="sway swaybg foot fuzzel mako \
wl-clipboard grim slurp imv pcmanfm-qt \
pipewire pipewire-pulse wireplumber pamixer \
lxsession xcursor-vanilla-dmz \
inter-font ttf-jetbrains-mono-nerd ttf-font-awesome \
fish eza fzf starship mpv ffmpeg zed power-profiles-daemon \
unzip wf-recorder noto-fonts pipewire-jack python-gobject glib2 \
wob qt5ct qt6ct kvantum vulkan-swrast chafa reflector"

sudo pacman -S --needed --noconfirm $PACKAGES

# Optimize Mirrors
sudo reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# ==============================================================================
# CHUNK 2: AUR (Swaylock-Effects & Themes)
# ==============================================================================
echo ":: [2/7] Installing AUR Packages..."
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && cd .. && rm -rf yay-bin
fi

# swaylock-effects-git is REQUIRED for blur/screenshots
yay -S --noconfirm librewolf-bin gruvbox-dark-gtk swaylock-effects-git

# ==============================================================================
# CHUNK 3: SYSTEM-WIDE THEMING (The Real Fix)
# ==============================================================================
echo ":: [3/7] Forcing Deep Theming..."

# 1. Force GTK Settings (Fixes LibreWolf)
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cat <<EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Gruvbox-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter 10
gtk-cursor-theme-name=Vanilla-DMZ
gtk-application-prefer-dark-theme=1
EOF
cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

# 2. Force Qt Settings (Fixes PCManFM)
# We set the environment variable later in Fish config
mkdir -p ~/.config/qt5ct
echo "[Appearance]
style=gtk2
icon_theme=Papirus-Dark
standard_dialogs=default" > ~/.config/qt5ct/qt5ct.conf

# ==============================================================================
# CHUNK 4: CUSTOM VISUALS (Wob & Wallpaper)
# ==============================================================================
echo ":: [4/7] Setting Visuals..."

# Wallpaper
mkdir -p ~/Pictures/Wallpapers
cp "./classroom.jpg" ~/Pictures/Wallpapers/classroom.jpg
if [ -f "./logo.png" ]; then cp "./logo.png" ~/Pictures/Wallpapers/logo.png; fi
if [ -f "./logo.jpg" ]; then cp "./logo.jpg" ~/Pictures/Wallpapers/logo.jpg; fi

# Wob (Volume Bar) - Gruvbox Theme
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
overflow_bar_color = cc241d
overflow_background_color = 282828
EOF

# ==============================================================================
# CHUNK 5: HELPER SCRIPTS (Recording & Lock)
# ==============================================================================
mkdir -p ~/.local/bin

# Recording Script (Updates status for Bar)
cat <<EOF > ~/.local/bin/record-screen.sh
#!/bin/bash
PIDFILE="/tmp/recording.pid"
if [ -f "\$PIDFILE" ]; then
    kill -SIGINT \$(cat "\$PIDFILE")
    rm "\$PIDFILE"
    pkill -RTMIN+1 swaybar # Refresh bar immediately
else
    mkdir -p ~/Videos
    TIMESTAMP=\$(date +%Y-%m-%d_%H-%M-%S)
    wf-recorder -f ~/Videos/recording_\$TIMESTAMP.mp4 &
    echo \$! > "\$PIDFILE"
    pkill -RTMIN+1 swaybar
fi
EOF
chmod +x ~/.local/bin/record-screen.sh

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

# ==============================================================================
# CHUNK 6: SWAY CONFIGURATION (Fixed Lock & Recording)
# ==============================================================================
echo ":: [5/7] Writing Sway Config..."
mkdir -p ~/.config/sway

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
output * scale 2
output * bg ~/Pictures/Wallpapers/classroom.jpg fill

# Transparency
for_window [app_id=".*"] opacity 0.95

# Gruvbox Colors
client.focused          #d79921 #282828 #ebdbb2 #d79921   #d79921
client.focused_inactive #3c3836 #3c3836 #a89984 #3c3836   #3c3836
client.unfocused        #3c3836 #3c3836 #a89984 #3c3836   #3c3836

# --- Bar with Recording Indicator ---
bar {
    position top
    # Check for recording PID file. If exists, show red [REC].
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

# --- Volume (Using WOB) ---
set \$WOBSOCK \$XDG_RUNTIME_DIR/wob.sock
exec mkfifo \$WOBSOCK && tail -f \$WOBSOCK | wob
bindsym \$mod+equal exec pamixer -i 5 && pamixer --get-volume > \$WOBSOCK
bindsym \$mod+minus exec pamixer -d 5 && pamixer --get-volume > \$WOBSOCK
bindsym \$mod+0 exec pamixer -t && (pamixer --get-mute && echo 0 || pamixer --get-volume) > \$WOBSOCK

# --- Keybindings ---
bindsym \$mod+Return exec \$term
bindsym \$mod+Shift+q kill
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes' 'swaymsg exit'

# Apps
bindsym \$mod+b exec librewolf
# Force Zed to use software rendering to prevent VM crash
bindsym \$mod+c exec zed --disable-gpu
bindsym \$mod+Shift+Return exec pcmanfm-qt

# Audio Selector
bindsym \$mod+a exec ~/.local/bin/audio-selector.sh

# Screenshots (Full Res) & Recording
bindsym \$mod+p exec grim ~/Pictures/shot_\$(date +%s).png
bindsym \$mod+Shift+s exec grim -g "\$(slurp)" ~/Pictures/shot_\$(date +%s).png
bindsym \$mod+Shift+r exec ~/.local/bin/record-screen.sh

# BLURRED Lock Screen (Gruvbox Box Style)
bindsym \$mod+Escape exec swaylock \
    --screenshots \
    --clock \
    --indicator \
    --indicator-radius 100 \
    --indicator-thickness 7 \
    --effect-blur 7x5 \
    --effect-vignette 0.5:0.5 \
    --ring-color d79921 \
    --key-hl-color b8bb26 \
    --text-color ebdbb2 \
    --inside-color 282828ff \
    --line-color 00000000 \
    --ring-clear-color cc241d \
    --inside-clear-color 282828

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
# CHUNK 7: TERMINAL & SHELL (Custom Image)
# ==============================================================================
echo ":: [6/7] Customizing Shell..."

# Fish Config with Chafa (Image) & Theme Vars
cat <<EOF > ~/.config/fish/config.fish
if status is-interactive
    set fish_greeting
    
    # Check for custom logo, otherwise fallback to pfetch
    if test -f ~/Pictures/Wallpapers/logo.png
        chafa --size=30x30 ~/Pictures/Wallpapers/logo.png
    else if test -f ~/Pictures/Wallpapers/logo.jpg
        chafa --size=30x30 ~/Pictures/Wallpapers/logo.jpg
    else
        pfetch
    end

    alias ls='eza -al --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'
    alias vim='zed' 
    starship init fish | source
end

# FORCE THEMING for Qt/GTK Apps
set -gx GTK_THEME "Gruvbox-Dark"
set -gx QT_QPA_PLATFORMTHEME "qt5ct"
set -gx GDK_SCALE 2
set -gx QT_SCALE_FACTOR 2
set -gx XCURSOR_SIZE 48
EOF

# Power Profile (Soft Fail)
sudo systemctl enable --now power-profiles-daemon.service
if command -v powerprofilesctl &> /dev/null; then
    powerprofilesctl set performance || echo ":: Note: Performance mode unavailable (VM restriction)."
fi
sudo systemctl mask sleep.target suspend.target

# Finalize
systemctl --user enable --now wireplumber.service pipewire-pulse.service
chsh -s /usr/bin/fish

echo ":: ---------------------------------------------------"
echo ":: INSTALL COMPLETE."
echo ":: 1. PCManFM/LibreWolf should now be dark."
echo ":: 2. Lock screen is now blurred with a box."
echo ":: 3. Zed should launch (using software renderer)."
echo ":: 4. Volume bar is Gruvbox themed."
echo ":: Type 'sway' to start."
echo ":: ---------------------------------------------------"
