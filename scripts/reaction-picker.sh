#!/usr/bin/env bash
# reaction-picker-launcher: open the reaction picker in a floating terminal.
# Called from niri via Mod+Shift+M.
#
# Kitty is used as the default; override with REACTION_TERMINAL.

set -eu

TERMINAL="${REACTION_TERMINAL:-kitty}"
APP_ID="reaction-picker"

case "$TERMINAL" in
  kitty)
    exec kitty --class "$APP_ID" -- ~/.local/bin/reaction-pick.sh ;;
  foot)
    exec foot --app-id "$APP_ID" -- ~/.local/bin/reaction-pick.sh ;;
  alacritty)
    exec alacritty --class "$APP_ID" --command ~/.local/bin/reaction-pick.sh ;;
  *)
    echo "unknown terminal: $TERMINAL" >&2
    exit 1 ;;
esac
