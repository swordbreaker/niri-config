#!/bin/sh

CLEAR_TIMEOUT=45

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
    echo "$vaults_json" | jq -r '.vaults[] | .name' | while read -r vault; do
        pass-cli item list "$vault" --output json | \
        jq -r --arg vault "$vault" '.items[] | "\(.content.title)\t" + $vault + "\t" + (.id // "")'
    done
}

select_item() {
    get_all_items | fuzzel -d -p "Select item: " --with-nth=1
}

get_item_fields() {
    local title="$1"
    local vault="$2"
    
    pass-cli item view --item-title "$title" --vault-name "$vault" --output json | \
    jq -r '.item.content.content | to_entries[] | "\(.key)\t" + (if .value | type == "string" and .value == "" then "(empty)" else if .value | type == "array" or .value | type == "object" then "(complex)" else .value end end)'
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
    
    pass-cli item view --item-title "$title" --vault-name "$vault" --output json | \
    jq -r ".item.content.content.\"$field\" // empty"
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
