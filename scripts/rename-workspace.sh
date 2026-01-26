#!/usr/bin/env bash

# Prompt for a new workspace name using fuzzel
name="$(printf '' | fuzzel --dmenu --prompt='WS name: ')"

# If the user cancelled or left it empty, do nothing
[ -z "$name" ] && exit 0

# Set the name on the currently focused workspace
niri msg action set-workspace-name "$name"