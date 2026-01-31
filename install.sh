#!/bin/bash

# ==============================================================================
# PRE-FLIGHT
# ==============================================================================
if [ ! -f "./classroom.jpg" ]; then
    echo ":: ERROR: 'classroom.jpg' missing. Place it next to this script."
    exit 1
fi

# ==============================================================================
# CHUNK 1: CORE PACKAGES (Thunar & Utils)
# ==============================================================================
echo ":: [1/7] Installing Core System..."

# Removed: pcmanfm-qt, lxsession, swaylock-effects
# Added: thunar, gvfs (drives), udiskie (automount), imagemagick (blur tool)
PACKAGES="sway swaybg foot fuzzel mako \
wl-clipboard grim slurp imv \
thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp ntfs-3g udiskie \
pipewire pipewire-pulse wireplumber pamixer \
polkit-gnome xcursor-vanilla-dmz \
ttf-jetbrains-mono-nerd ttf-font-awesome inter-font \
fish eza fzf starship mpv ffmpeg zed power-profiles-daemon \
unzip wf-recorder noto-fonts pipewire-jack python-gobject glib2 wob imagemagick"

sudo pacman -S --needed --noconfirm $PACKAGES

# Optimize Mirrors
if ! command -v reflector &> /dev/null; then sudo pacman -S --noconfirm reflector; fi
sudo reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# ==============================================================================
# CHUNK 2: AUR (Gtklock & Extras)
# ==============================================================================
echo ":: [2/7] Installing AUR Essentials..."
if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && cd .. && rm -rf yay-bin
fi

# gtklock: The alternative lock screen
# fastfetch: Terminal info
yay -S --noconfirm librewolf-bin gruvbox-dark-gtk gtklock fastfetch

# ==============================================================================
# CHUNK 3: VISUALS (Wallpaper & Lock Prep)
# ==============================================================================
echo ":: [3/7] Preparing Visuals..."
mkdir -p ~/Pictures/Wallpapers

# 1. Main Wallpaper
cp "./classroom.jpg" ~/Pictures/Wallpapers/classroom.jpg

# 2. Generate "Fake" Blurred Lockscreen Background
# This is the sure-fire way to get blur without crashing.
echo ":: Generating blurred lockscreen image..."
convert ~/Pictures/Wallpapers/classroom.jpg -blur 0x16 ~/Pictures/Wallpapers/lock_blurred.jpg

# ==============================================================================
# CHUNK 4: CONFIGURATION (Gtklock & Thunar)
# ==============================================================================
echo ":: [4/7] Configuring Apps..."

# --- Gtklock Config (The "Box" Look) ---
mkdir -p ~/.config/gtklock
cat <<EOF > ~/.config/gtklock/config.ini
[main]
gtk-theme=Gruvbox-Dark
style=~/.config/gtklock/style.css
EOF

cat <<EOF > ~/.config/gtklock/style.css
window {
    background-image: url("$(echo ~)/Pictures/Wallpapers/lock_blurred.jpg");
    background-size: cover;
    background-repeat: no-repeat;
}

#input-label {
    /* Hidden, we just want the box */
    opacity: 0;
}

#input {
    background-color: #282828;
    color: #ebdbb2;
    border: 2px solid #d79921;
    border-radius: 0px;
    padding: 10px;
    box-shadow: 0 0 10px rgba(0,0,0,0.5);
    margin-top: 200px; /* Push it down a bit */
}
EOF

# --- GTK Settings (Forces Thunar Theme) ---
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

# ==============================================================================
# CHUNK 5: SWAY CONFIGURATION
# ==============================================================================
echo ":: [5/7] Writing Sway Config..."
mkdir -p ~/.config/sway

cat <<EOF > ~/.config/sway/config
# Variables
set \$mod Mod4
set \$term foot
set \$menu fuzzel

# Visuals
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

# Bar (Clean - No Recording Indicator)
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

# --- Inputs ---
input * {
    xkb_layout "us"
    repeat_delay 300
    repeat_rate 50
    tap enabled
}
seat seat0 xcursor_theme Vanilla-DMZ 48

# --- Volume (Wob) ---
set \$WOBSOCK \$XDG_RUNTIME_DIR/wob.sock
exec mkfifo \$WOBSOCK && tail -f \$WOBSOCK | wob
bindsym \$mod+equal exec pamixer -i 5 && pamixer --get-volume > \$WOBSOCK
bindsym \$mod+minus exec pamixer -d 5 && pamixer --get-volume > \$WOBSOCK

# --- Keybindings ---
bindsym \$mod+Return exec \$term
bindsym \$mod+Shift+q kill
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes' 'swaymsg exit'

# Apps (Thunar & Zed)
bindsym \$mod+b exec librewolf
bindsym \$mod+c exec zed --disable-gpu
bindsym \$mod+Shift+Return exec thunar

# Lock Screen (Gtklock)
bindsym \$mod+Escape exec gtklock

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
exec /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec udiskie --tray # Auto-mounts USBs
EOF

# ==============================================================================
# CHUNK 6: SHELL & EXTRAS
# ==============================================================================
echo ":: [6/7] Finalizing Shell..."

# Fish Config (Test Notification Alias)
cat <<EOF > ~/.config/fish/config.fish
if status is-interactive
    set fish_greeting
    fastfetch
    alias ls='eza -al --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'
    alias vim='zed'
    alias test-notify='notify-send "Test" "Mako is working!"'
    starship init fish | source
end

# Vars
set -gx GTK_THEME "Gruvbox-Dark"
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

# Recording Script (No Bar Update)
mkdir -p ~/.local/bin
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
echo ":: INSTALL COMPLETE."
echo ":: ---------------------------------------------------"
