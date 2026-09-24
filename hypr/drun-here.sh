#!/usr/bin/env bash

set -u

target_workspace=$(hyprctl activeworkspace -j | jq -r '.id // empty') || exit 1
[[ -n $target_workspace ]] || exit 1

known_addresses=$(hyprctl clients -j | jq -c '[.[].address]') || exit 1

rofi -show drun
rofi_status=$?
((rofi_status == 0)) || exit "$rofi_status"

# Rofi can launch into an existing application process, so Hyprland's process
# token is not sufficient. Catch the new top-level window and put it back on
# the workspace from which the launcher was opened.
for ((attempt = 0; attempt < 300; attempt++)); do
    new_address=$(hyprctl clients -j | jq -r --argjson known "$known_addresses" '
        [
            .[]
            | select(.address as $address | ($known | index($address) | not))
        ]
        | sort_by(.focusHistoryID)
        | .[0].address // empty
    ') || exit 1

    if [[ -n $new_address ]]; then
        hyprctl dispatch movetoworkspacesilent \
            "$target_workspace,address:$new_address" >/dev/null
        exit $?
    fi

    sleep 0.1
done
