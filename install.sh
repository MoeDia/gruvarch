#!/bin/bash

# ==============================================================================
# PRE-FLIGHT CHECK
# ==============================================================================
if [ ! -f "./classroom.jpg" ]; then
    echo ":: ERROR: 'classroom.jpg' missing. Place it next to this script."
    exit 1
fi

# ==============================================================================
# 1. INSTALLATION (Optimized)
# ==============================================================================
echo ":: [1/4] Installing Optimized Packages..."

# Core Wayland & Audio
PACKAGES="sway swaybg foot fuzzel mako \
pipewire pipewire-pulse wireplumber pamixer \
wl-clipboard grim slurp imv \
wob wf-recorder"

# File Management (Thunar + Archives + Drives + NTFS)
PACKAGES+=" thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp ntfs-3g udiskie unzip"

# Media Codecs
PACKAGES+=" ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav"

# System Tools (Polkit, Power)
PACKAGES+=" polkit-gnome power-profiles-daemon python-gobject glib2 libnotify"

# Fonts & Visuals
PACKAGES+=" xcursor-vanilla-dmz ttf-jetbrains-mono-nerd ttf-font-awesome inter-font noto-fonts"

# Shell & Utilities (No ImageMagick, No Gtklock)
PACKAGES+=" fish eza fzf starship zed mpv"

sudo pacman -S --needed --noconfirm $PACKAGES

# Speed up future downloads
if ! command -v reflector &> /dev/null; then sudo pacman -S --noconfirm reflector; fi
sudo reflector --latest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# ==============================================================================
# 2. AUR ESSENTIALS
# ==============================================================================
echo ":: [2/4] Installing AUR Tools..."

if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si --noconfirm && cd .. && rm -rf yay-bin
fi

# Only essentials (No Lockscreen)
yay -S --noconfirm librewolf-bin fastfetch

# ==============================================================================
# 3. VISUAL PREP
# ==============================================================================
echo ":: [3/4] Setting up Visuals..."
mkdir -p ~/Pictures/Wallpapers
cp "./classroom.jpg" ~/Pictures/Wallpapers/classroom.jpg

# ==============================================================================
# 4. CONFIGURATION
# ==============================================================================
echo ":: [4/4] Writing Configurations..."
mkdir -p ~/.config/{sway,foot,fuzzel,fish,mako,wob}
mkdir -p ~/.local/bin

# --- A. Helper Scripts (Audio Selector) ---
cat <<EOF > ~/.local/bin/audio-selector.sh
#!/bin/bash
# Lists audio outputs and lets you select one via Fuzzel
sink=\$(pactl list short sinks | cut -f 2 | fuzzel --dmenu --prompt="Audio Output: " --lines=5 --width=50)
if [ -n "\$sink" ]; then
    pactl set-default-sink "\$sink"
    pactl list short sink-inputs | cut -f 1 | xargs -I {} pactl move-sink-input {} "\$sink"
fi
EOF
chmod +x ~/.local/bin/audio-selector.sh

# --- B. Fish Shell (GUI Only) ---
cat <<EOF > ~/.config/fish/config.fish
if status is-interactive
    set fish_greeting
    
    # Aliases
    alias ls='eza -al --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'

    # Run Fastfetch
    fastfetch
    
    # Use Starship Prompt
    starship init fish | source
    
    # GUI Theme Variables (Sure-fire Dark Mode)
    set -gx GTK_THEME "Gruvbox-Dark"
    set -gx QT_QPA_PLATFORMTHEME "gtk2"
    set -gx GDK_SCALE 2
    set -gx QT_SCALE_FACTOR 2
    set -gx XCURSOR_SIZE 48
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

# --- D. Foot (Gruvbox + Fish Launch) ---
cat <<EOF > ~/.config/foot/foot.ini
[main]
font=JetBrainsMono Nerd Font:size=10
pad=10x10
# Launch Fish automatically in the terminal, keeping TTY as Bash
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

# --- H. Sway Config (Optimized) ---
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

# Transparency (95% Opacity)
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

# --- Bar (JetBrains Regular, Seconds Added) ---
bar {
    position top
    font pango:JetBrainsMono Nerd Font Regular 10
    
    # Format: 04:30:15 PM | 01-02-2026
    status_command while date +'%I:%M:%S %p | %d-%m-%Y'; do sleep 1; done

    colors {
        statusline #ebdbb2
        background #282828
        inactive_workspace #282828 #282828 #a89984
        focused_workspace  #282828 #d79921 #282828
        active_workspace   #282828 #3c3836 #ebdbb2
        urgent_workspace   #282828 #cc241d #ebdbb2
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
# Instant Exit (No Nag)
bindsym \$mod+Shift+e exec swaymsg exit

# Apps
bindsym \$mod+b exec librewolf
bindsym \$mod+c exec zed --disable-gpu
bindsym \$mod+Shift+Return exec thunar

# Audio Selector (Super+A)
bindsym \$mod+a exec ~/.local/bin/audio-selector.sh

# Screenshots & Recording (No Print Key)
bindsym \$mod+p exec grim ~/Pictures/shot_\$(date +%s).png
bindsym \$mod+Shift+s exec grim -g "\$(slurp)" ~/Pictures/shot_\$(date +%s).png
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
exec /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec udiskie --tray
exec mako
EOF

# ==============================================================================
# 5. FINAL STEPS
# ==============================================================================
echo ":: [5/5] Finalizing..."

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

# Performance & Services
sudo systemctl enable --now power-profiles-daemon.service
sleep 2
if command -v powerprofilesctl &> /dev/null; then
    powerprofilesctl set performance || echo ":: Performance mode not supported (VM?)"
fi

# Disable Sleep
sudo systemctl mask sleep.target suspend.target

# Enable Audio
systemctl --user enable --now wireplumber.service pipewire-pulse.service

echo ":: ---------------------------------------------------"
echo ":: INSTALL COMPLETE."
echo ":: TTY is Bash. Terminal is Fish."
echo ":: Type 'sway' to launch."
echo ":: ---------------------------------------------------"
