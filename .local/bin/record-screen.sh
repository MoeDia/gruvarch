#!/bin/bash
PIDFILE="/tmp/recording.pid"

if [ -f "$PIDFILE" ]; then
    # Stop Recording
    kill -SIGINT $(cat "$PIDFILE")
    rm "$PIDFILE"
    notify-send "Recording" "Stopped and saved to ~/Videos"
else
    # Start Recording
    mkdir -p ~/Videos
    # Record full screen (slurp can be added for region if preferred)
    wf-recorder -f ~/Videos/recording_$(date +%s).mp4 &
    echo $! > "$PIDFILE"
    notify-send "Recording" "Started..."
fi
