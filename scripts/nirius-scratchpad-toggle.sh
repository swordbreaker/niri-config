#!/bin/sh

# Generic scratchpad toggle script for niri
# Usage: nirius-scratchpad-toggle-generic.sh <app-id> <command> [args...]
#
# Example: nirius-scratchpad-toggle-generic.sh quake-foot foot --app-id=quake-foot
# Example: nirius-scratchpad-toggle-generic.sh my-term alacritty --class my-term

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <app-id> <command> [args...]" >&2
  echo "Example: $0 quake-foot foot --app-id=quake-foot" >&2
  exit 1
fi

APP_ID="$1"
shift
COMMAND="$@"

# Ensure the instance exists
if ! niri msg -j windows | jq -e ".[] | select(.app_id==\"$APP_ID\")" >/dev/null 2>&1; then
  exec $COMMAND &

  # Wait until niri reports a window with that app-id
  while true; do
    if niri msg -j windows | jq -e ".[] | select(.app_id==\"$APP_ID\")" > /dev/null; then
      break
    fi
    echo "Waiting for $APP_ID window to appear..."
    sleep 0.1
  done

  nirius scratchpad-toggle --app-id="$APP_ID"
  echo "Started $APP_ID instance"
fi

nirius scratchpad-show --app-id="$APP_ID"
