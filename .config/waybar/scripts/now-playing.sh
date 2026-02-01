#!/bin/bash

# Check if anything is playing (Spotify, Firefox, mpv, etc.)
status=$(playerctl status 2>/dev/null)

if [ "$status" != "Playing" ] && [ "$status" != "Paused" ]; then
  echo "" # Hide module if nothing is open
  exit 0
fi

# Get metadata
artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)

# Fallback if empty
if [ -z "$artist" ]; then 
    text="$title"
else
    text="$artist - $title"
fi

# Icon based on status
if [ "$status" == "Playing" ]; then
    icon=""
    # Fake Visualizer (Random bars)
    bars=(" " "▂" "▃" "▄" "▅" "▆" "▇" "█")
    vis=""
    for i in {1..4}; do
        vis+="${bars[$RANDOM % ${#bars[@]}]}"
    done
else
    icon=""
    vis=""
fi

echo "$icon $text $vis"
