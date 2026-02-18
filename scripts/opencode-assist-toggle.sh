#!/bin/sh

APP_ID="opencode-assist"
COMMAND="foot --app-id=opencode-assist opencode --agent assistant"

if ! niri msg -j windows | jq -e ".[] | select(.app_id==\"$APP_ID\")" >/dev/null 2>&1; then
  exec $COMMAND &

  while true; do
    if niri msg -j windows | jq -e ".[] | select(.app_id==\"$APP_ID\")" > /dev/null; then
      break
    fi
    sleep 0.1
  done

  nirius scratchpad-toggle --app-id="$APP_ID"
  echo "Started $APP_ID instance"
fi

nirius scratchpad-show --app-id="$APP_ID"
