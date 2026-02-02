#!/bin/sh

CLEAR_TIMEOUT=45
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_FILE="$CACHE_DIR/pass-fuzzel-items.cache"
CACHE_TIMEOUT=300

check_and_login() {
    if ! pass-cli test >/dev/null 2>&1; then
        tmpfile=$(mktemp)
        pass-cli login >"$tmpfile" 2>&1 &
        login_pid=$!

        sleep 2
        url=$(grep -oE 'https://[^[:space:]]+' "$tmpfile" | head -1)

        if [ -n "$url" ]; then
            notify-send "Proton Pass Login" "Opening browser to complete login"
            xdg-open "$url" >/dev/null 2>&1 &
        fi

        while ! pass-cli test >/dev/null 2>&1; do
            sleep 1
        done

        rm -f "$tmpfile"
    fi
}

get_all_items() {
    vaults_json=$(pass-cli vault list --output json)

    cache_valid=0
    if [ -f "$CACHE_FILE" ]; then
        cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
        if [ "$cache_age" -lt "$CACHE_TIMEOUT" ]; then
            cache_valid=1
        fi
    fi

    if [ "$cache_valid" -eq 1 ]; then
        cat "$CACHE_FILE"
        return
    fi

    tmpdir=$(mktemp -d)
    touch "$tmpdir/items.txt"

    echo "$vaults_json" | jq -r '.vaults[] | .name' >"$tmpdir/vaults.txt"

    while read -r vault; do
        pass-cli item list "$vault" --output json >"$tmpdir/$vault.json" 2>/dev/null &
    done <"$tmpdir/vaults.txt"

    wait

    for json_file in "$tmpdir"/*.json; do
        [ ! -f "$json_file" ] && continue
        vault=$(basename "$json_file" .json)
        jq -r --arg vault "$vault" '.items[] | "\(.content.title)\t" + $vault + "\t" + (.id // "")' "$json_file" 2>/dev/null >>"$tmpdir/items.txt"
    done

    mkdir -p "$CACHE_DIR"
    cp "$tmpdir/items.txt" "$CACHE_FILE"
    cat "$tmpdir/items.txt"

    rm -rf "$tmpdir"
}

select_item() {
    get_all_items | fuzzel -d -p "Select item: " --with-nth=1
}

get_item_fields() {
    local title="$1"
    local vault="$2"

    fields=$(pass-cli item view --item-title "$title" --vault-name "$vault" --output json | \
        jq -r '.item.content.content | keys[0] as $type | .[$type] | keys[]')

    totp_uri=$(pass-cli item view --item-title "$title" --vault-name "$vault" --output json | \
        jq -r '.item.content.content | keys[0] as $type | .[$type].totp_uri // empty')

    echo "$fields" | grep -v "^totp_uri$"

    if [ -n "$totp_uri" ]; then
        echo "totp"
    fi
}

select_field() {
    local title="$1"
    local vault="$2"

    get_item_fields "$title" "$vault" | fuzzel -d -p "Copy field: " | cut -f1
}

get_field_value() {
    local title="$1"
    local vault="$2"
    local field="$3"

    if [ "$field" = "totp" ]; then
        totp_uri=$(pass-cli item view --item-title "$title" --vault-name "$vault" --output json | \
            jq -r '.item.content.content | keys[0] as $type | .[$type].totp_uri // empty')
        if [ -n "$totp_uri" ]; then
            pass-cli totp generate "$totp_uri"
        fi
    else
        pass-cli item view --item-title "$title" --vault-name "$vault" --output json | \
            jq -r ".item.content.content | keys[0] as \$type | .[\$type].\"$field\" // empty"
    fi
}

copy_to_clipboard() {
    local value="$1"

    echo "$value" | wl-copy
    notify-send "Copied to clipboard" "Will clear in ${CLEAR_TIMEOUT}s"
    sleep $CLEAR_TIMEOUT
    wl-copy --clear
    notify-send "Clipboard cleared"
}

main() {
    check_and_login

    selection=$(select_item)
    [ -z "$selection" ] && exit 0

    title=$(echo "$selection" | cut -f1)
    vault=$(echo "$selection" | cut -f2)

    field=$(select_field "$title" "$vault")
    [ -z "$field" ] && exit 0

    value=$(get_field_value "$title" "$vault" "$field")
    [ -z "$value" ] && exit 0

    copy_to_clipboard "$value"
}

main
