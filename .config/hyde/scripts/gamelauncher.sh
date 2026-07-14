#!/usr/bin/env zsh
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"

# --- Configuration ---
ROM_PATH="$HOME/Documents/ROMs"
EMULATOR="mgba-qt"
EXTENSION="*.gba"

style="5"
rofi_config="gamelauncher_5"

elem_border=$((hypr_border * 2))
icon_border=$((elem_border - 3))

# --- Steam Deck Background & Layout Math ---
monitor_info=()
eval "$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) |
"monitor_info=(\(.width) \(.height) \(.scale) \(.x) \(.y)) reserved_info=(\(.reserved | join(" ")))"')"
percent=80
monitor_scale="${monitor_info[2]//./}"
monitor_width=$((monitor_info[0] * percent / monitor_scale))
monitor_height=$((monitor_info[1] * percent / monitor_scale))
BG=$HOME/.local/share/hyde/rofi/assets/steamdeck_holographic.png
BGfx=$HOME/.cache/hyde/landing/steamdeck_holographic_${monitor_width}x$monitor_height.png
if [ ! -e "$BGfx" ]; then
    magick "$BG" -resize ${monitor_width}x$monitor_height -background none -gravity center -extent ${monitor_width}x$monitor_height "$BGfx"
fi

# --- THE LAYOUT OVERRIDE ---
r_override="
window {
    width: ${monitor_width}px;
    height: ${monitor_height}px;
    background-image: url('$BGfx', width);
}
mainbox {
    padding: 21% 17%;
}
listview {
    columns: 5;
    lines: 1;
    cycle: false;
    spacing: 15px;
    scrollbar: true;
}
scrollbar {
    handle-width: 8px;
    handle-color: #ffffff;
    background-color: rgba(255, 255, 255, 0.1);
    border-radius: 4px;
    padding: 2px;
}
element {
    orientation: vertical;
    border-radius: ${elem_border}px;
    padding: 8px;
}
element-icon {
    size: 8em;
    border-radius: ${icon_border}px;
    horizontal-align: 0.5;
}
element-text {
    horizontal-align: 0.5;
    vertical-align: 0.5;
}
"

# --- Cover Extractor ---
fetch_boxart() {
    local rom_name="$1"
    local rom_dir="$2"
    local target_dir="$rom_dir/.art"
    local target_file="$target_dir/$rom_name.png"

    mkdir -p "$target_dir"

    # Use python to cleanly URL-encode spaces, &, and parentheses
    local encoded_name=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$rom_name")
    local url="https://raw.githubusercontent.com/libretro-thumbnails/Nintendo_-_Game_Boy_Advance/master/Named_Boxarts/${encoded_name}.png"

    # -f fails silently on 404 (not found), -s is silent, -L follows redirects
    if curl -fsSL "$url" -o "$target_file"; then
        echo "$target_file"
    else
        rm -f "$target_file" 2>/dev/null # Clean up empty file if failed
        echo "hyde" # Fallback system icon
    fi
}

# --- ROM Scanner ---
scan_roms() {
    if [[ ! -d "$ROM_PATH" ]]; then
        printf "Error: ROM_PATH not found\0icon\x1fhyde\t#\n"
        return
    fi

    find "$ROM_PATH" -type f -name "$EXTENSION" | while read -r rom; do
        filename="${rom##*/}"
        raw_name="${filename%.*}"
        dir="${rom%/*}"

        display_name=$(echo "$raw_name" | sed 's/ *([A-Za-z0-9_, -]*)//g; s/ *\[[A-Za-z0-9_, -]*\]//g')

        icon="hyde"
        if [[ -f "$dir/.art/$raw_name.png" ]]; then
            icon="$dir/.art/$raw_name.png"
        elif [[ -f "$dir/.art/$raw_name.jpg" ]]; then
            icon="$dir/.art/$raw_name.jpg"
        elif [[ -f "$dir/$raw_name.png" ]]; then
            icon="$dir/$raw_name.png"
        elif [[ -f "$dir/$raw_name.jpg" ]]; then
            icon="$dir/$raw_name.jpg"
        else
            # No local art found? Trigger the downloader!
            icon=$(fetch_boxart "$raw_name" "$dir")
            # If fetch_boxart returned nothing (empty) or defaulted to hyde, use _not_found.png
            if [[ -z "$icon" || "$icon" == "hyde" ]]; then
                icon="$dir/.art/_not_found.png"
            fi
        fi

        printf "%s\t$EMULATOR \"%s\"\0icon\x1f%s\n" "$display_name" "$rom" "$icon"
    done
}

# --- Run Launcher ---
# Added '-i' right after -dmenu for case-insensitive searching!
selected=$(scan_roms | rofi -dmenu -i -p "GBA" -show-icons \
    -theme-str "$r_override" \
    -display-columns 1 \
    -config "$rofi_config")

if [[ -z "$selected" || "$selected" == "#" ]]; then
    exit 0
fi

cmd=${selected#*$'\t'}
eval exec "$cmd"
