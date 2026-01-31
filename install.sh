#!/bin/bash

# --- 1. Base Installation (Official Repos) ---
echo ":: [1/5] Installing Official Packages..."

# Core Sway, Tools, Audio, Fonts, Shell, Editor (Zed), Media (MPV+Codecs)
PACKAGES="sway swaybg swayidle swaylock foot fuzzel mako \
wl-clipboard grim slurp imv nnn \
pipewire pipewire-pulse wireplumber pamixer \
lxsession xcursor-vanilla-dmz \
inter-font ttf-jetbrains-mono-nerd ttf-font-awesome \
fish eza fzf starship \
mpv ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav \
zed \
noto-fonts pipewire-jack"

sudo pacman -S --needed --noconfirm $PACKAGES

# --- 2. AUR Installation (LibreWolf) ---
echo ":: [2/5] Setting up AUR for LibreWolf..."

if ! command -v yay &> /dev/null; then
    echo ":: Installing yay (AUR Helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ..
    rm -rf yay-bin
fi

echo ":: Installing LibreWolf..."
yay -S --noconfirm librewolf-bin

# --- 3. Create Config Directories ---
echo ":: [3/5] Creating Config Directories..."
mkdir -p ~/.config/{sway,foot,fuzzel,fish}

# --- 4. Configuration Files (Gruvbox + 4K Optimized) ---

# --- Fish Config (With 4K Env Vars) ---
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

# 4K / HiDPI Environment Variables
set -gx GDK_SCALE 2
set -gx QT_SCALE_FACTOR 2
set -gx XCURSOR_SIZE 48
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

# --- Sway Config (4K Scaled + Gruvbox) ---
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
# Scale factor 2 is standard for 4K (3840x2160 -> 1920x1080 logical)
output * scale 2
output * bg #282828 solid_color

# --- Input (Real Hardware) ---
input * {
    xkb_layout "us"
    repeat_delay 300
    repeat_rate 50
    dwindle:enabled enable
    tap enabled
}

# --- Cursor (Large for 4K) ---
seat seat0 xcursor_theme Vanilla-DMZ 48

# --- Default Bar (Gruvbox Customized) ---
bar {
    position top
    status_command while date +'%Y-%m-%d %I:%M %p'; do sleep 1; done

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

# Launch Browsers/Editors
bindsym \$mod+b exec librewolf
bindsym \$mod+c exec zed

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

# Audio & Brightness
bindsym XF86AudioRaiseVolume exec pamixer -i 5
bindsym XF86AudioLowerVolume exec pamixer -d 5
bindsym XF86AudioMute exec pamixer -t

# --- Autostart ---
exec /usr/lib/lxpolkit/lxpolkit
exec swayidle -w timeout 600 'swaylock -f -c 282828' timeout 610 'swaymsg "output * power off"' resume 'swaymsg "output * power on"'
EOF

# --- 5. Finalize ---
echo ":: [4/5] Enabling Audio Services..."
systemctl --user enable --now wireplumber.service pipewire-pulse.service

echo ":: [5/5] Changing default shell to Fish (Enter Password if asked)..."
chsh -s /usr/bin/fish

echo ":: ---------------------------------------------------"
echo ":: INSTALLATION COMPLETE."
echo ":: Type 'sway' to launch your 4K Optimized environment."
echo ":: ---------------------------------------------------"
