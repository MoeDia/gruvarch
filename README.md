🌿 GruvArch

    A cozy, minimal Arch + Sway environment with a touch of Gruvbox.

Welcome to GruvArch! This is a simple, automated setup designed to turn a fresh Arch Linux install into a productive, earth-toned workspace. It handles everything from your bootloader theme to your terminal file manager.
✨ Features

🛠️ Installation

Before running the script, ensure you are on a fresh Arch install and have an internet connection.

Run:

```bash
git clone https://github.com/yourusername/GruvArch.git
cd GruvArch
chmod +x setup.sh
./setup.sh
```

Bash

chmod +x setup.sh
./setup.sh

⌨️ Quick Controls
Keybind	Action
Mod + Enter	Open Foot Terminal
Mod + D	App Launcher
Mod + Shift + E	Exit Sway

📦 Core Dependencies

The script will automatically install these, but here's what’s under the hood:

    Window Manager: Sway

    Bar: Waybar (with playerctl for media)

    Terminal: Foot

    File Manager: Thunar (with exo helpers)

    Bootloader: Limine
