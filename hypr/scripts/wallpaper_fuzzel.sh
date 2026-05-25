#!/bin/bash

WALLPAPER_DIR="$HOME/.config/wallpapers"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
THEME_DIR="$HOME/.cache/wal"

get_monitors() {
    local mons=()

    if command -v wlr-randr >/dev/null 2>&1; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^([A-Za-z0-9_-]+)[[:space:]]\" ]]; then
                mons+=("${BASH_REMATCH[1]}")
            fi
        done < <(wlr-randr 2>/dev/null)
    fi

    if [[ ${#mons[@]} -eq 0 ]] && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^Monitor[[:space:]]+([A-Za-z0-9_-]+) ]]; then
                mons+=("${BASH_REMATCH[1]}")
            fi
        done < <(hyprctl monitors 2>/dev/null)
    fi

    printf '%s\n' "${mons[@]}"
}

# ---------------- fuzzel picker ----------------
FILE=$(find "$WALLPAPER_DIR" -type f \
    | sort \
    | sed "s|$WALLPAPER_DIR/||" \
    | fuzzel --dmenu --prompt="> ")

[ -z "$FILE" ] && exit 0

FILE="$WALLPAPER_DIR/$FILE"

[ ! -f "$FILE" ] && exit 1

echo "applying: $FILE"

# ---------------- wallpaper ----------------
mapfile -t MONITORS < <(get_monitors)

if [[ ${#MONITORS[@]} -eq 0 ]]; then
    echo "no monitors found"
    exit 1
fi

mkdir -p "$(dirname "$HYPRPAPER_CONF")"

{
    echo "preload = $FILE"
    echo

    for mon in "${MONITORS[@]}"; do
        echo "wallpaper = $mon,$FILE"
    done

    echo
    echo "splash = false"
    echo "ipc = off"
} > "$HYPRPAPER_CONF"

# ---------------- pywal ----------------
mkdir -p "$THEME_DIR"
wal -i "$FILE" || { echo "pywal failed"; exit 1; }

mkdir -p ~/.config/waybar

source ~/.cache/wal/colors.sh

# ---------------- derived colors ----------------
hex="${color1#\#}"
r=$((16#${hex:0:2}))
g=$((16#${hex:2:2}))
b=$((16#${hex:4:2}))
BORDER_RGBA="rgba($r, $g, $b, 0.85)"

hex2="${color5#\#}"
r2=$((16#${hex2:0:2}))
g2=$((16#${hex2:2:2}))
b2=$((16#${hex2:4:2}))
BG_RGBA="rgba($r2, $g2, $b2, 0.8)"

# ---------------- HYPRLAND ----------------
sed -i '/col.active_border/d' "$HYPR_CONF"
sed -i '/col.inactive_border/d' "$HYPR_CONF"

if ! grep -q "^general {" "$HYPR_CONF"; then
    echo -e "\ngeneral {\n}\n" >> "$HYPR_CONF"
fi

awk -v active="col.active_border = 0xff$hex" \
    -v inactive="col.inactive_border = 0xff$hex" '
/^general {/ {
    print
    print "  " inactive
    print "  " active
    next
}
{print}
' "$HYPR_CONF" > "$HYPR_CONF.tmp" && mv "$HYPR_CONF.tmp" "$HYPR_CONF"

# ---------------- waybar derived colors ----------------
hex7="${color7#\#}"

r7=$((16#${hex7:0:2}))
g7=$((16#${hex7:2:2}))
b7=$((16#${hex7:4:2}))

lighten() {
    local c=$1
    echo $(( c + (255 - c) * 40 / 100 ))
}

r7_light=$(lighten "$r7")
g7_light=$(lighten "$g7")
b7_light=$(lighten "$b7")

ACTIVE_COLOR=$(printf "#%02x%02x%02x" "$r7_light" "$g7_light" "$b7_light")

# ---------------- waybar background ----------------
hex0="${color0#\#}"

r0=$((16#${hex0:0:2}))
g0=$((16#${hex0:2:2}))
b0=$((16#${hex0:4:2}))

WAYBAR_BG="rgba($r0, $g0, $b0, 0.6)"

# ---------------- waybar ----------------
cat > ~/.config/waybar/theme.css <<EOF
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", monospace;
    font-size: 12px;
}

window#waybar {
    background: ${WAYBAR_BG};
    border: 2px solid ${color1};
}

#custom-power, #battery {
    margin-left: 4px;
    margin-right: 4px;
}

#tray {
    margin-right: 4px;
}

#workspaces button,
#custom-clock,
#cpu,
#memory,
#battery,
#network,
#custom-power,
#pulseaudio,
#window {
    color: ${color15};
    padding: 4px;
}

button:hover {
    box-shadow: none;
    text-shadow: none;
    background: none;
    transition: none;
}

#workspaces button.active {
    color: ${color11};
}

#pulseaudio {
    margin-right: 4px;
}

#battery {
    margin-right: 4px;
}

#battery:not(.empty) {
    margin-right: 4px;
}

#battery:not(.empty) ~ #pulseaudio {
    margin-right: 4px;
}
EOF

# ---------------- kitty ----------------
cat > ~/.config/kitty/kitty.conf <<EOF
include ~/.cache/wal/colors-kitty.conf
font_family JetBrainsMono Nerd Font
font_size 11
confirm_os_window_close 0
background_opacity 0.65
EOF

pkill -USR1 kitty 2>/dev/null

# ---------------- fuzzel theme ----------------
mkdir -p ~/.config/fuzzel

cat > ~/.config/fuzzel/fuzzel.ini <<EOF
[main]
width=60
horizontal-pad=20
vertical-pad=10

[colors]
background=00000066
text=${color7}ff
prompt=${color8}ff
input=${color4}ff
selection=${color1}26
selection-text=${color2}ff
border=${color1}ff
match=${color2}ff
selection-match=${color2}ff

[border]
width=2
radius=0
EOF

# ---------------- hyprlock ----------------
cat > ~/.config/hypr/hyprlock.conf <<EOF
general {
    hide_cursor = true
    fade_in = 0.05
    fade_out = 0.05
    ignore_empty_input = true
    fail_timeout = 1000
}

background {
    path = $FILE
    blur_passes = 3
    blur_size = 8
}

label {
    text = cmd[update:1000] echo "[ \$(date +'%I:%M:%S %P') ]"
    font_size = 32
    color = rgba(${color7#\#}aa)
    position = 0, 100
    halign = center
    valign = center
}

input-field {
    size = 300, 50
    position = 0, -80
    rounding = 0

    outer_color = rgb(${hex})
    inner_color = rgba(0, 0, 0, 0.3)

    font_color = rgb(${color7#\#})
    font_family = JetBrainsMono Nerd Font

    outline_thickness = 1

    halign = center
    valign = center
}
EOF

# ---------------- swaync ----------------
cat > ~/.config/swaync/style.css <<EOF
* {
    border-radius: 0;
    font-family: monospace; !important
}

.floating-notifications {
    spacing: 4px;
}

.notification {
    background: rgba(0, 0, 0, 0.7);
    color: ${color7};
    border: 2px solid ${BORDER_RGBA};

    margin: 0;
    padding: 6px;
}

.floating-notifications {
    margin: 16px;
    margin-top: 23px;
}

.body {
    color: ${color7};
}

/* action buttons */
.notification-action,
.notification-default-action {
    background: transparent;
    color: ${color7};
    padding: 8px;
}

.notification-action:hover,
.notification-default-action:hover {
    background: transprent;
}

/* close (X) button */
.close-button {
    background: rgba(0, 0, 0, 0.25);
    color: ${color7};
    border: 2px solid ${BORDER_RGBA};
}

.close-button:hover {
    background: rgba($r, $g, $b, 0.15);
    color: ${color1};
}

/* control center buttons */
button {
    background: rgba(0, 0, 0, 0.25);
    color: ${color7};
    border: 2px solid ${BORDER_RGBA};
}

button:hover {
    background: rgba($r, $g, $b, 0.15);
}
EOF

# ---------------- equibop ----------------
mkdir -p ~/.config/equibop/themes

hex8="${color2#\#}"
r8=$((16#${hex8:0:2}))
g8=$((16#${hex8:2:2}))
b8=$((16#${hex8:4:2}))

ACCENT_RGB="$r8, $g8, $b8"
EQUIBOP_CSS="$HOME/.config/equibop/themes/main.css"

sed -i -E \
    "s|--accentcolor:[[:space:]]*[0-9]+,[[:space:]]*[0-9]+,[[:space:]]*[0-9]+;|--accentcolor: ${ACCENT_RGB};|g" \
    "$EQUIBOP_CSS"

# ---------------- cava ----------------
mkdir -p ~/.config/cava

awk -v color="${color2}" '
BEGIN { in_color=0; fg_set=0 }

/^\[color\]/ {
    in_color=1
    print
    next
}

/^\[/ && !/^\[color\]/ {
    if (in_color && !fg_set)
        print "foreground = '\''" color "'\''"
    in_color=0
}

in_color && /^[; ]*foreground[ ]*=/ {
    print "foreground = '\''" color "'\''"
    fg_set=1
    next
}

{ print }

END {
    if (in_color && !fg_set)
        print "foreground = '\''" color "'\''"
}
' ~/.config/cava/config > ~/.config/cava/config.tmp \
&& mv ~/.config/cava/config.tmp ~/.config/cava/config

pkill -USR1 cava 2>/dev/null

# ---------------- restart ----------------
hyprctl reload

pkill hyprpaper
nohup hyprpaper >/dev/null 2>&1 & disown

pkill waybar
rm -rf ~/.cache/waybar
sleep 0.3
waybar >/dev/null 2>&1 &
disown

pkill swaync
nohup swaync >/dev/null 2>&1 & disown

pkill kded6

echo "done"
