#!/bin/bash
# 1. Get the list of audio devices (sinks)
# 2. Show them in a menu (Fuzzel)
# 3. 'cut' grabs just the ID number of the device
sink=$(pactl list short sinks | cut -f 2 | fuzzel --dmenu --prompt="Audio Output: " --lines=5 --width=50)

# 4. If you picked something...
if [ -n "$sink" ]; then
    # Set it as the default for new apps
    pactl set-default-sink "$sink"
    # Move everything currently playing to this new device
    pactl list short sink-inputs | cut -f 1 | xargs -I {} pactl move-sink-input {} "$sink"
fi
