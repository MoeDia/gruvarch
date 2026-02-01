#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# PRE-FLIGHT CHECK
# ==============================================================================
WALLPAPER_SRC="./classroom.jpg"
if [[ ! -f "$WALLPAPER_SRC" ]]; then
  echo ":: ERROR: 'classroom.jpg' missing. Place it next to this script."
  exit 1
fi

echo ":: Starting install + config for Sway (main machine)..."

# ==============================================================================
# 1) PACKAGES (PACMAN)
# ==============================================================================
echo ":: [1/4] Installing packages..."

PACKAGES=(
  # Core Wayland + Sway
  sway swaybg foot fuzzel mako xorg-xwayland

  # Clipboard (critical)
  wl-clipboard cliphist

  # Screenshots/selection (your binds)
  grim slurp

  # Audio
  pipewire pipewire-pulse wireplumber pamixer

  # OSD + recording
  wob wf-recorder

  # File management + mounts + thumbnails
  thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp udiskie
  tumbler ffmpegthumbnailer poppler-glib
  ntfs-3g unzip

  # Codecs
  ffmpeg gstreamer gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav

  # GPU drivers (AMD RX 6400)
  mesa vulkan-radeon libva-mesa-driver

  # System helpers
  polkit-gnome power-profiles-daemon python-gobject glib2 libnotify

  # Portals (screen share, file pickers)
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk

  # Fonts & visuals
  xcursor-vanilla-dmz ttf-jetbrains-mono-nerd ttf-font-awesome inter-font noto-fonts

  # Shell & tools
  fish eza fzf starship zed mpv btop fastfetch
)

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

# ==============================================================================
# 2) AUR (YAY) + OPTIONAL EXTRAS
# ==============================================================================
echo ":: [2/4] Installing AUR tools..."

if ! command -v yay >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm base-devel git
  rm -rf yay-bin
  git clone https://aur.archlinux.org/yay-bin.git
  pushd yay-bin >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf yay-bin
fi

# Browser from AUR (matches your setup)
yay -S --noconfirm librewolf-bin

# ==============================================================================
# 3) CONFIG + SCRIPTS
# ==============================================================================
echo ":: [3/4] Writing configs..."

# Fix Zed binary naming if needed
if [[ -f /usr/bin/zeditor ]]; then
  sudo ln -sf /usr/bin/zeditor /usr/bin/zed
fi

# Login shell: keep bash for TTY safety, foot will run fish
sudo chsh -s /bin/bash "$(whoami)" || true

# Dirs
mkdir -p ~/.config/{sway,foot,fuzzel,fish,mako,wob}
mkdir -p ~/.local/bin
mkdir -p ~/Pictures/Wallpapers
mkdir -p ~/Pictures
mkdir -p ~/Videos

# Wallpaper
cp -f "$WALLPAPER_SRC" ~/Pictures/Wallpapers/classroom.jpg

# ------------------------------------------------------------------------------
# A) Audio selector (Fuzzel)
# ------------------------------------------------------------------------------
cat > ~/.local/bin/audio-selector.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
sink="$(pactl list short sinks | cut -f2 | fuzzel --dmenu --prompt="Audio Output: " --lines=10 --width=60 || true)"
if [[ -n "${sink:-}" ]]; then
  pactl set-default-sink "$sink"
  pactl list short sink-inputs | cut -f1 | xargs -r -I {} pactl move-sink-input {} "$sink"
  notify-send "Audio" "Output set to: $sink"
fi
EOF
chmod +x ~/.local/bin/audio-selector.sh

# ------------------------------------------------------------------------------
# B) Clipboard menu (Mod+V)
# ------------------------------------------------------------------------------
cat > ~/.local/bin/clipmenu.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
choice="$(cliphist list | fuzzel --dmenu --prompt="Clipboard: " --lines=12 --width=80 || true)"
if [[ -n "${choice:-}" ]]; then
  cliphist decode <<<"$choice" | wl-copy
  notify-send "Clipboard" "Pasted from history"
fi
EOF
chmod +x ~/.local/bin/clipmenu.sh

# ------------------------------------------------------------------------------
# C) i3bar JSON status script (fixes red :( while keeping same text style)
# ------------------------------------------------------------------------------
cat > ~/.local/bin/sway-status.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# i3bar protocol header
printf '{"version":1}\n[\n'
printf '[]\n'

while :; do
  now="$(date +'%I:%M:%S %p | %a %d-%m-%Y')"
  # One block, same visual text you wanted
  printf '[{"full_text":"%s"}],\n' "$now"
  sleep 1
done
EOF
chmod +x ~/.local/bin/sway-status.sh

# ------------------------------------------------------------------------------
# D) Screen recording toggle
# ------------------------------------------------------------------------------
cat > ~/.local/bin/record-screen.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
PIDFILE="/tmp/wf-recorder.pid"

if [[ -f "$PIDFILE" ]]; then
  kill -SIGINT "$(cat "$PIDFILE")" 2>/dev/null || true
  rm -f "$PIDFILE"
  notify-send "Recording" "Stopped."
else
  out="$HOME/Videos/recording_$(date +%s).mp4"
  wf-recorder -f "$out" &
  echo $! > "$PIDFILE"
  notify-send "Recording" "Started: $out"
fi
EOF
chmod +x ~/.local/bin/record-screen.sh

# ------------------------------------------------------------------------------
# E) Fish config (interactive only)
# ------------------------------------------------------------------------------
cat > ~/.config/fish/config.fish <<'EOF'
if status is-interactive
    set fish_greeting
    alias ls='eza -al --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first'

    fastfetch
    starship init fish | source

    # Wayland session hints
    set -gx XDG_CURRENT_DESKTOP sway
    set -gx XDG_SESSION_DESKTOP sway
end
EOF

# ------------------------------------------------------------------------------
# F) Starship (your preset)
# ------------------------------------------------------------------------------
cat > ~/.config/starship.toml <<'EOF'
[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold green)"

[directory]
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
format = "on [$symbol$branch]($style) "
symbol = " "
style = "bold yellow"

[git_status]
format = '([$all_status$ahead_behind]($style) )'
style = "bold red"

[cmd_duration]
format = "took [$duration]($style) "
style = "yellow"

[hostname]
ssh_only = false
format = "[$hostname](bold blue) "
disabled = false

[line_break]
disabled = false

[package]
disabled = true
EOF

# ------------------------------------------------------------------------------
# G) Foot config (forces fish only in foot)
# ------------------------------------------------------------------------------
cat > ~/.config/foot/foot.ini <<'EOF'
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

# ------------------------------------------------------------------------------
# H) Fuzzel (Gruvbox)
# ------------------------------------------------------------------------------
cat > ~/.config/fuzzel/fuzzel.ini <<'EOF'
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

# ------------------------------------------------------------------------------
# I) Wob (Gruvbox)
# ------------------------------------------------------------------------------
cat > ~/.config/wob/wob.ini <<'EOF'
timeout = 1000
max = 100
width = 400
height = 50
border_size = 2
bar_color = d79921
border_color = 282828
background_color = 282828
EOF

# ------------------------------------------------------------------------------
# J) Mako (Gruvbox)
# ------------------------------------------------------------------------------
cat > ~/.config/mako/config <<'EOF'
font=JetBrainsMono Nerd Font 10
background-color=#282828
text-color=#ebdbb2
border-color=#d79921
border-size=2
default-timeout=5000
EOF

# ------------------------------------------------------------------------------
# K) Sway config (Swaybar kept, red face fixed, clipboard fixed)
# ------------------------------------------------------------------------------
cat > ~/.config/sway/config <<'EOF'
# --- Variables ---
set $mod Mod4
set $term foot
set $menu fuzzel

# --- Visuals ---
font pango:JetBrainsMono Nerd Font Regular 10
default_border pixel 2
gaps inner 5
gaps outer 0
for_window [app_id=".*"] opacity 0.95

# Gruvbox Colors
client.focused          #d79921 #282828 #ebdbb2 #d79921 #d79921
client.focused_inactive #3c3836 #3c3836 #a89984 #3c3836 #3c3836
client.unfocused        #3c3836 #3c3836 #a89984 #3c3836 #3c3836
client.urgent           #cc241d #cc241d #ebdbb2 #cc241d #cc241d

# --- Output ---
output * bg ~/Pictures/Wallpapers/classroom.jpg fill
# If you have a 4K display and want scaling, uncomment:
# output * scale 2

# --- Input ---
input * {
    xkb_layout "us"
    repeat_delay 300
    repeat_rate 50
    tap enabled
}
seat seat0 xcursor_theme Vanilla-DMZ 48

# --- Bar (KEEP SWAYBAR, fix :( using i3bar JSON status script) ---
bar {
    position top
    font pango:JetBrainsMono Nerd Font Regular 10
    status_command ~/.local/bin/sway-status.sh
    colors {
        statusline #ebdbb2
        background #282828
        inactive_workspace #282828 #282828 #a89984
        focused_workspace  #282828 #d79921 #282828
        active_workspace   #282828 #3c3836 #ebdbb2
        urgent_workspace   #282828 #cc241d #ebdbb2
    }
}

# --- Wob (volume OSD) ---
set $WOBFIFO $XDG_RUNTIME_DIR/wob.fifo
exec_always pkill -x wob || true
exec_always pkill -f "tail -f .*wob.fifo" || true
exec_always rm -f $WOBFIFO && mkfifo -m 600 $WOBFIFO
exec_always sh -c "tail -f $WOBFIFO | wob" &

bindsym $mod+equal exec pamixer -i 5 && pamixer --get-volume > $WOBFIFO
bindsym $mod+minus exec pamixer -d 5 && pamixer --get-volume > $WOBFIFO

# --- Keybindings ---
bindsym $mod+Return exec $term
bindsym $mod+Shift+q kill
bindsym $mod+d exec $menu
bindsym $mod+Shift+c reload
bindsym $mod+Shift+e exec swaymsg exit

# Apps
bindsym $mod+b exec librewolf
bindsym $mod+c exec zed
bindsym $mod+Shift+Return exec thunar

# Helper Scripts
bindsym $mod+a exec ~/.local/bin/audio-selector.sh
bindsym $mod+Shift+r exec ~/.local/bin/record-screen.sh

# Clipboard picker (1000% clipboard workflow)
bindsym $mod+v exec ~/.local/bin/clipmenu.sh

# Screenshots (save + copy)
bindsym $mod+p exec sh -c 'grim - | tee "$HOME/Pictures/shot_$(date +%s).png" | wl-copy && notify-send "Screenshot" "Saved & Copied"'
bindsym $mod+Shift+s exec sh -c 'grim -g "$(slurp)" - | tee "$HOME/Pictures/shot_$(date +%s).png" | wl-copy && notify-send "Screenshot" "Saved & Copied"'

# Navigation
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# Moving windows
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# Layout
bindsym $mod+f fullscreen
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Workspaces
bindsym $mod+1 workspace 1
bindsym $mod+2 workspace 2
bindsym $mod+3 workspace 3
bindsym $mod+4 workspace 4
bindsym $mod+5 workspace 5
bindsym $mod+Shift+1 move container to workspace 1
bindsym $mod+Shift+2 move container to workspace 2
bindsym $mod+Shift+3 move container to workspace 3
bindsym $mod+Shift+4 move container to workspace 4
bindsym $mod+Shift+5 move container to workspace 5

# --- Autostart (order matters) ---

# 1) DBus import (portals + notifications)
exec_always dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway XDG_SESSION_TYPE=wayland
exec_always systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE

# 2) Polkit
exec_always /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# 3) Notifications
exec_always mako

# 4) Portals (screen sharing, file pickers)
exec_always /usr/lib/xdg-desktop-portal-wlr
exec_always /usr/lib/xdg-desktop-portal

# 5) Clipboard: bulletproof (text+image, clipboard+primary, reload-safe)
exec_always pkill -x wl-paste || true
exec_always wl-paste --watch --type text  cliphist store --clipboard & 
exec_always wl-paste --watch --type image cliphist store --clipboard & 
exec_always wl-paste --watch --type text  cliphist store --primary & 
exec_always wl-paste --watch --type image cliphist store --primary & 

# 6) Automount WITHOUT tray (swaybar has no tray)
exec_always udiskie --no-tray
EOF

# ==============================================================================
# 4) SERVICES + FINALIZATION
# ==============================================================================
echo ":: [4/4] Enabling services..."

# Power profiles
sudo systemctl enable --now power-profiles-daemon.service || true
if command -v powerprofilesctl >/dev/null 2>&1; then
  powerprofilesctl set performance || true
fi

# PipeWire user services
systemctl --user enable --now wireplumber.service pipewire.service pipewire-pulse.service || true

echo ":: ---------------------------------------------------"
echo ":: INSTALL COMPLETE ✅"
echo ":: - Swaybar red :( fixed (proper i3bar JSON status)"
echo ":: - Clipboard fixed HARD (text+image, clipboard+primary, reload-safe)"
echo ":: - Clipboard picker: Mod+V"
echo ":: - Udiskie errors gone (no tray on swaybar)"
echo ":: ---------------------------------------------------"
