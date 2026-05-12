#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
THEME_DIR="$HOME/.cache/wal"

echo "enter wallpaper name (no extension):"
read NAME

FILE="$WALLPAPER_DIR/$NAME"

if [ -f "$FILE.png" ]; then FILE="$FILE.png"
elif [ -f "$FILE.jpg" ]; then FILE="$FILE.jpg"
elif [ -f "$FILE.jpeg" ]; then FILE="$FILE.jpeg"
elif [ ! -f "$FILE" ]; then
    echo "not found"
    exit 1
fi

echo "applying: $FILE"

# ---------------- wallpaper ----------------
MONITOR=$(hyprctl monitors | awk '/Monitor/ {print $2; exit}')
[ -z "$MONITOR" ] && MONITOR="HDMI-A-2"

cat > "$HYPRPAPER_CONF" <<EOF
wallpaper {
    monitor = $MONITOR
    path = $FILE
    fit_mode = cover
}
splash = false
ipc = off
EOF

pkill hyprpaper
sleep 0.3
nohup hyprpaper >/dev/null 2>&1 & disown

# ---------------- pywal ----------------
mkdir -p "$THEME_DIR"
wal -i "$FILE" || { echo "pywal failed"; exit 1; }

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

# remove old values first (prevents duplicates)
sed -i '/col.active_border/d' "$HYPR_CONF"
sed -i '/col.inactive_border/d' "$HYPR_CONF"

# ensure general block exists
if ! grep -q "^general {" "$HYPR_CONF"; then
    echo -e "\ngeneral {\n}\n" >> "$HYPR_CONF"
fi

# insert inside general block (safe append)
awk -v active="col.active_border = 0xff$hex" \
    -v inactive="col.inactive_border = 0xff$hex" '
/^general {/ {
    print
    print "    " inactive
    print "    " active
    next
}
{print}
' "$HYPR_CONF" > "$HYPR_CONF.tmp" && mv "$HYPR_CONF.tmp" "$HYPR_CONF"

# ---------------- waybar ----------------
cat > "$THEME_DIR/theme.css" <<EOF
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", monospace;
    font-size: 12px;
}

window#waybar {
    background: rgba(0,0,0,0.35);
    border: 2px solid ${BORDER_RGBA};
}

#custom-power {
    margin-left: 8px;
    margin-right: 8px;
}

#tray {
    margin-right: 4px;
}

#workspaces button,
#clock,
#cpu,
#memory,
#pulseaudio,
#window {
    color: $color7;
    padding: 8px;
}

button:hover {
    box-shadow: none;
    text-shadow: none;
    background: none;
    transition: none;
}
EOF

# ---------------- kitty ----------------
cat > ~/.config/kitty/kitty.conf <<EOF
include ~/.cache/wal/colors-kitty.conf
font_family JetBrainsMono Nerd Font
font_size 11
confirm_os_window_close 0
EOF

pkill -USR1 kitty 2>/dev/null

# ---------------- fuzzel ----------------
mkdir -p ~/.config/fuzzel

cat > ~/.config/fuzzel/fuzzel.ini <<EOF
[main]
width=60
horizontal-pad=20
vertical-pad=10

[colors]
background=00000066
text=${color7}ff
selection=${color7}ff
border=${color1}ff

[border]
width=2
radius=0
EOF

# ---------------- hyprlock ----------------
cat > ~/.config/hypr/hyprlock.conf <<EOF
general {
    hide_cursor = true
    fade_in = 0.08
    fade_out = 0.05
}

background {
    path = $FILE
    blur_passes = 3
    blur_size = 8
}

label {
    text = cmd[update:1000] echo "[ $(date +'%I:%M %P') ]"
    font_size = 32
    color = rgb(${color7#\#})
    position = 0, 180
}

label {
    text = cmd[update:60000] echo "[ $USER ]"
    font_size = 20
    color = rgb(${color6#\#})
    position = 0, 120
}

input-field {
    size = 300, 50
    position = 0, -80
    rounding = 0
    outer_color = rgb(${hex})
    inner_color = rgba(0, 0, 0, 0.3)
    font_color = rgb(${color7#\#})
    outline_thickness = 2
}
EOF

# ---------------- GTK ----------------
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0

cat > ~/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Adwaita
gtk-font-name=JetBrainsMono Nerd Font 10
gtk-application-prefer-dark-theme=1
EOF

cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

# ---------------- discord ----------------
cat > "$THEME_DIR/discord-pywal.css" <<EOF
:root {
    --text-1: ${color7};
    --text-2: ${color6};
    --text-3: ${color5};

    --bg-4: ${color0};
    --bg-3: ${color1};

    --accent-1: ${color4};
    --accent-2: ${color5};
}
EOF

# ---------------- swaync (safe, non-destructive) ----------------
cat > ~/.config/swaync/style.css <<EOF
* {
    font-family: "JetBrainsMono Nerd Font";
    border-radius: 0;
}

.notification {
    background: ${BG_RGBA};
    color: ${color7};
    border: 2px solid ${BORDER_RGBA};
    margin: 15px;
    margin-top: 21px;
}

EOF

# ---------------- restart ----------------
pkill waybar
sleep 0.3
nohup waybar >/dev/null 2>&1 & disown

pkill swaync
nohup swaync >/dev/null 2>&1 & disown

echo "done"
