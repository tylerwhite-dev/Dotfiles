#!/bin/bash

# Install wmctrl to run script correctly

# Function to launch Obsidian
launch_obsidian() {
    # Try to launch Obsidian as a Flatpak package
    if command -v flatpak &> /dev/null; then
        flatpak run md.obsidian.Obsidian &>/dev/null &
    else
        echo "Obsidian flatpak not found."
    fi
}

# Checking if Obsidian is running
if pgrep -x "obsidian" > /dev/null
then
    # If running, focus its window using wmctrl
    if wmctrl -a "Obsidian"; then
        echo "Obsidian is already running, window activated."
    else
        echo "Obsidian window not found."
    fi
else
    # If not running, launch it
    launch_obsidian
fi
