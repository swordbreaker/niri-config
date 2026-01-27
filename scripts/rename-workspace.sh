#!/usr/bin/env bash

# Prompt for a new workspace name using fuzzel
name="$(printf '' | fuzzel --dmenu --prompt='WS name: ')"

# If the user cancelled or left it empty, unset the name
if [ -z "$name" ]; then
    niri msg action unset-workspace-name
    exit 0
fi

# Set the name on the currently focused workspace
niri msg action set-workspace-name "$name"
