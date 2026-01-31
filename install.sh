#!/bin/bash

# --- 1. Base Installation (Official Repos) ---
echo ":: [1/6] Installing Packages (No Nvidia, No NNN, LXQt FM added)..."

# Removed: nvidia, nnn, waybar
# Added: pcmanfm-qt, power-profiles-daemon, unzip (useful for archive tools)
PACKAGES="sway swaybg swayidle swaylock foot fuzzel mako \
wl-clipboard grim slurp imv pcmanfm-qt \
pipewire pipewire-pulse wireplumber pamixer \
lxsession xcursor-vanilla-dmz \
inter-font ttf-jetbrains-mono-nerd ttf-font-awesome \
fish eza fzf starship \
mpv ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav \
zed power-profiles-daemon \
noto-fonts pipewire-jack"

sudo pacman -S --needed --noconfirm $PACKAGES

# --- 2. AUR Installation (LibreWolf + Gruvbox GTK) ---
echo ":: [2/6] Setting up AUR for LibreWolf & Themes..."

if ! command -v yay &> /dev/null; then
    echo ":: Installing yay (AUR Helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ..
    rm -rf yay-bin
fi

echo ":: Installing LibreWolf and Gruvbox GTK Theme..."
yay -S --noconfirm librewolf-bin gruvbox-dark-gtk

# --- 3. Create Config Directories ---
echo ":: [3/6] Creating Config Directories..."
mkdir -p ~/.config/{sway,foot,fuzzel,fish,pcmanfm-qt/default}
mkdir -p ~/.local/bin

# --- 4. System Optimization (Power & Sleep) ---
echo ":: [4/6] Optimizing Power & Disabling Sleep..."

# Enable Power Profiles Daemon
sudo systemctl enable --now power-profiles-daemon.service

# Force Performance Mode
powerprofilesctl set performance

# Disable Sleep/Hibernate completely (No screensaver behavior)
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# --- 5. Custom Scripts ---

# Create Audio Selector Script (Super+A)
cat <<EOF > ~/.local/bin/audio-selector.sh
#!/bin/bash
# Lists audio sinks (outputs) and uses Fuzzel to select one
sink=\$(pactl list short sinks | cut -f 2 | fuzzel --dmenu --prompt="Audio Output: " --lines=5 --width=50)

if [ -n "\$sink" ]; then
    pactl set-default-sink "\$sink"
    # Move all currently playing streams to the new sink
    pactl list short sink-inputs | cut -f 1 | xargs -I {} pactl move-sink-input {} "\$sink"
fi
EOF
chmod +x ~/.local/bin/audio-selector.sh

# Link Zed to 'zed' command if needed
if [ ! -f /usr/bin/zed ] && [ -f /usr/bin/zeditor ]; then
    sudo ln -s /usr/bin/zeditor /usr/bin/zed
fi

# --- 6. Configuration Files ---

# --- Fish Config (Dark Mode & 4K) ---
cat <<EOF > ~/.config/fish/config.fish
if status is-interactive
    set fish_greeting
    
    # Aliases
    alias ls='eza -al --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'
    alias vim='zed' 

    # Starship
    starship init fish | source
end

# 4K / HiDPI Variables
set -gx GDK_SCALE 2
set -gx QT_SCALE_FACTOR 2
set -gx XCURSOR_SIZE 48

# Force Dark Mode (Apps will detect this)
set -gx GTK_THEME "Gruvbox-Dark"
set -gx QT_QPA_PLATFORMTHEME "gtk2"
set -gx COLORTERM "truecolor"
EOF

# --- Starship (Pure Preset) ---
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
[cmd_duration]
format = "took [\$duration]($style) "
style = "yellow"
[hostname]
ssh_only = false
format = "[\$hostname](bold blue) "
EOF

# --- Foot Terminal (Gruvbox) ---
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

# --- Fuzzel Launcher (Gruvbox) ---
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

# --- PCManFM-Qt (Basic config to respect dark theme) ---
cat <<EOF > ~/.config/pcmanfm-qt/default/settings.conf
[System]
IconTheme=Papirus-Dark
EOF

# --- Sway Config (Fixed Workspaces + Center Time + No Sleep) ---
cat <<EOF > ~/.config/sway/config
# --- Variables ---
set \$mod Mod4
set \$term foot
set \$menu fuzzel

# --- Visuals (Gruvbox) ---
font pango:Inter 10
default_border pixel 2
gaps inner 5
gaps outer 0

# Class                 Border  Backgr. Text    Indicator Child Border
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

# --- Cursor (Large) ---
seat seat0 xcursor_theme Vanilla-DMZ 48

# --- Status Bar ---
# NOTE: Stock swaybar cannot do 'Center' alignment perfectly.
# We format it to look clean on the right side.
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

# --- Workspaces (Fixed 1-5) ---
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

# --- Keybindings ---
bindsym \$mod+Return exec \$term
bindsym \$mod+Shift+q kill
bindsym \$mod+d exec \$menu
bindsym \$mod+Shift+c reload
# Minimal Lock (Super+L) - No screenshots, just dark color
bindsym \$mod+l exec swaylock -c 1d2021
bindsym \$mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -B 'Yes' 'swaymsg exit'

# Apps
bindsym \$mod+b exec librewolf
bindsym \$mod+c exec zed
bindsym \$mod+Shift+Enter exec pcmanfm-qt

# Audio Selector (Super+A)
bindsym \$mod+a exec ~/.local/bin/audio-selector.sh

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

# Audio Keys (Hardware)
bindsym XF86AudioRaiseVolume exec pamixer -i 5
bindsym XF86AudioLowerVolume exec pamixer -d 5
bindsym XF86AudioMute exec pamixer -t

# --- Autostart ---
exec /usr/lib/lxpolkit/lxpolkit
# Swayidle removed (No screensaver requested)
EOF

# --- 7. Finalize ---
echo ":: [5/6] Enabling Audio Services..."
systemctl --user enable --now wireplumber.service pipewire-pulse.service

echo ":: [6/6] Changing default shell to Fish..."
chsh -s /usr/bin/fish

echo ":: ---------------------------------------------------"
echo ":: INSTALLATION COMPLETE."
echo ":: Type 'sway' to start."
echo ":: ---------------------------------------------------"
