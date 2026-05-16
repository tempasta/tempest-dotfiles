#!/bin/bash
set -euo pipefail

# ── colors ────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── logging ───────────────────────────────────────────────────────────────────

section() {
    echo
    printf "${BOLD}${BLUE}  ◆ %s${RESET}\n" "${1^^}"
    printf "${DIM}  $(printf '─%.0s' {1..54})${RESET}\n"
}

log() {
    local type="$1"
    local msg="${2,,}"
    case "$type" in
        ok)   printf "  ${GREEN}✓${RESET}  %s\n" "$msg"                      ;;
        info) printf "  ${CYAN}→${RESET}  %s\n"  "$msg"                      ;;
        skip) printf "  ${DIM}·${RESET}  %s\n"   "$msg"                      ;;
        warn) printf "  ${YELLOW}⚠${RESET}  %s\n" "$msg"                     ;;
        err)  printf "  ${RED}✗${RESET}  %s\n"   "$msg"                      ;;
        done) printf "\n  ${GREEN}${BOLD}◆ %s${RESET}\n\n" "${msg^^}"        ;;
    esac
}

# ── paths ─────────────────────────────────────────────────────────────────────

DOTFILES="$HOME/dotfiles"
REPO="https://github.com/tempasta/tempest-dotfiles.git"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup"
WALLPAPER_DEST="$HOME/Pictures/wallpapers"

# ── banner ────────────────────────────────────────────────────────────────────

echo
printf "${BOLD}${CYAN}  ╭──────────────────────────────────────────────────────╮${RESET}\n"
printf "${BOLD}${CYAN}  │${RESET}        ${BOLD}tempest${RESET} ${DIM}·${RESET} dotfiles installer                    ${BOLD}${CYAN}│${RESET}\n"
printf "${BOLD}${CYAN}  ╰──────────────────────────────────────────────────────╯${RESET}\n"
echo
sudo -v

# ── copr repos ────────────────────────────────────────────────────────────────

section "repos"
log info "enabling solopasha/hyprland"
sudo dnf copr enable -y solopasha/hyprland 2>/dev/null || true
log ok "copr repos ready"

# ── packages ──────────────────────────────────────────────────────────────────

section "packages"

PACKAGES=(
    git
    rsync
    wlr-randr
    hyprland
    hyprpaper
    waybar
    fuzzel
    kitty
    swaync
    fastfetch
    flameshot
    wl-clipboard
    xdg-desktop-portal-hyprland
    polkit-gnome
    grim
    slurp
    swappy
    brightnessctl
    pavucontrol
    wireplumber
    jetbrains-mono-fonts
)

for pkg in "${PACKAGES[@]}"; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
        log skip "$pkg already installed"
    else
        log info "installing $pkg"
        if sudo dnf install -y "$pkg" >/dev/null 2>&1; then
            log ok "$pkg installed"
        else
            log warn "failed to install $pkg, continuing"
        fi
    fi
done

# ── dotfiles ──────────────────────────────────────────────────────────────────

section "dotfiles"

if [ -d "$DOTFILES/.git" ]; then
    log info "updating existing repo"
    git -C "$DOTFILES" pull
    log ok "dotfiles up to date"
else
    log info "cloning $REPO"
    git clone "$REPO" "$DOTFILES"
    log ok "dotfiles cloned"
fi

cd "$DOTFILES"

# ── backup ────────────────────────────────────────────────────────────────────

section "backup"

mkdir -p "$BACKUP_DIR"
log ok "backup dir ready → $BACKUP_DIR"

# ── configs ───────────────────────────────────────────────────────────────────

section "configs"

sync_config() {
    local name="$1"
    local src="$DOTFILES/$name/"
    local dest="$CONFIG_DIR/$name/"
    local backup="$BACKUP_DIR/$name/"

    if [ ! -d "$src" ]; then
        log skip "no config for $name"
        return
    fi

    mkdir -p "$dest" "$backup"
    rsync -ah --backup --backup-dir="$backup" "$src" "$dest"
    log ok "$name synced"
}

mkdir -p "$CONFIG_DIR"

for cfg in hypr waybar fuzzel kitty swaync fastfetch equibop wal; do
    sync_config "$cfg"
done

# ── wallpapers ────────────────────────────────────────────────────────────────

section "wallpapers"

mkdir -p "$WALLPAPER_DEST"

if [ -d "$DOTFILES/wallpapers" ]; then
    cp -rf "$DOTFILES/wallpapers/"* "$WALLPAPER_DEST/"
    log ok "wallpapers copied to $WALLPAPER_DEST"
else
    log warn "wallpapers folder missing from dotfiles"
fi

# ── themes ────────────────────────────────────────────────────────────────────

section "themes"

mkdir -p "$HOME/.local/share/icons" "$HOME/.themes"

if [ -d "$DOTFILES/Empty-Pixel-White" ]; then
    rm -rf "$HOME/.local/share/icons/Empty-Pixel-White"
    cp -r "$DOTFILES/Empty-Pixel-White" "$HOME/.local/share/icons/"
    log ok "cursor theme installed"
else
    log warn "empty-pixel-white not found in dotfiles"
fi

if [ -d "$DOTFILES/Adwaita-dark" ]; then
    rm -rf "$HOME/.themes/Adwaita-dark"
    cp -r "$DOTFILES/Adwaita-dark" "$HOME/.themes/"
    log ok "gtk theme installed"
else
    log warn "adwaita-dark not found in dotfiles"
fi

# ── shell ─────────────────────────────────────────────────────────────────────

section "shell"

if [ -f "$DOTFILES/.zshrc" ]; then
    cp -f "$DOTFILES/.zshrc" "$HOME/.zshrc"
    log ok "zshrc installed"
else
    log warn "zshrc not found in dotfiles"
fi

# ── gtk settings ──────────────────────────────────────────────────────────────

section "gtk settings"

gsettings set org.gnome.desktop.interface gtk-theme            "Adwaita-dark"        || true
gsettings set org.gnome.desktop.interface color-scheme         "prefer-dark"         || true
gsettings set org.gnome.desktop.interface cursor-theme         "Empty-Pixel-White"   || true
gsettings set org.gnome.desktop.interface monospace-font-name  "JetBrains Mono 11"   || true
gsettings set org.gnome.desktop.interface font-name            "Adwaita Sans 11"     || true
gsettings set org.gnome.desktop.interface document-font-name   "Adwaita Sans 11"     || true
log ok "gtk settings applied"

# ── fonts ─────────────────────────────────────────────────────────────────────

section "fonts"

fc-cache -fv >/dev/null 2>&1 || true
log ok "font cache refreshed"

mkdir -p "$HOME/.config/fontconfig"

cat > "$HOME/.config/fontconfig/fonts.conf" <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <alias>
        <family>monospace</family>
        <prefer>
            <family>JetBrains Mono</family>
        </prefer>
    </alias>
</fontconfig>
EOF

log ok "fontconfig written"

# ── scripts ───────────────────────────────────────────────────────────────────

section "scripts"

chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh 2>/dev/null || true
log ok "hypr scripts marked executable"

# ── monitors ─────────────────────────────────────────────────────────────────
#
# Detects monitors across Hyprland, wlroots, Plasma, and X11.
# Lets the user pick resolution + layout position,
# then writes hypr/monitors.conf.

section "monitors"

declare -a MON_LIST=()
declare -A MON_MODEL=()
declare -A MON_MODES=()
declare -A MON_SEL_W=()
declare -A MON_SEL_H=()
declare -A MON_SEL_R=()
declare -A MON_ROW=()
declare -A MON_COL=()
declare -A MON_X=()
declare -A MON_Y=()

show_position_layout() {
    printf "  ${DIM}pick a position:${RESET}\n"
    printf "  ${BOLD}[   top-left  ]${RESET}   ${BOLD}[  top   ]${RESET}   ${BOLD}[   top-right  ]${RESET}\n"
    printf "  ${BOLD}[    left     ]${RESET}   ${BOLD}[ middle ]${RESET}   ${BOLD}[    right     ]${RESET}\n"
    printf "  ${BOLD}[ bottom-left ]${RESET}   ${BOLD}[ bottom ]${RESET}   ${BOLD}[ bottom-right ]${RESET}\n"
    printf "\n"
}

set_monitor_position() {
    local mon="$1"
    local pos="$2"

    case "$pos" in
        left)         MON_ROW["$mon"]="middle"; MON_COL["$mon"]="left" ;;
        middle)       MON_ROW["$mon"]="middle"; MON_COL["$mon"]="middle" ;;
        right)        MON_ROW["$mon"]="middle"; MON_COL["$mon"]="right" ;;
        top)          MON_ROW["$mon"]="top";    MON_COL["$mon"]="middle" ;;
        bottom)       MON_ROW["$mon"]="bottom"; MON_COL["$mon"]="middle" ;;
        top-left)     MON_ROW["$mon"]="top";    MON_COL["$mon"]="left" ;;
        top-right)    MON_ROW["$mon"]="top";    MON_COL["$mon"]="right" ;;
        bottom-left)  MON_ROW["$mon"]="bottom"; MON_COL["$mon"]="left" ;;
        bottom-right) MON_ROW["$mon"]="bottom"; MON_COL["$mon"]="right" ;;
    esac
}

pretty_model() {
    local raw="$1"

    raw="${raw%%, *}"

    case "$raw" in
        *" Inc. "*)         raw="${raw#*Inc. }" ;;
        *" Corporation "*)  raw="${raw#*Corporation }" ;;
        *" Co., Ltd. "*)    raw="${raw#*Co., Ltd. }" ;;
        *" Technologies "*) raw="${raw#*Technologies }" ;;
    esac

    printf '%s' "${raw:-Unknown display}"
}

show_monitor_labels() {
    if ! command -v hyprctl &>/dev/null || ! command -v zenity &>/dev/null; then
        return 0
    fi

    [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && return 0

    log info "showing temporary monitor labels"
    echo

    for m in "${MON_LIST[@]}"; do
        local label="THIS IS ${m} (${MON_MODEL[$m]})"

        hyprctl dispatch focusmonitor "$m" >/dev/null 2>&1 || true

        zenity --info \
            --no-wrap \
            --title="Monitor identifier" \
            --text="$label" \
            --timeout=3 \
            >/dev/null 2>&1 &

        sleep 0.15
    done
}

print_monitor_context() {
    local m="$1"

    printf "\n"
    printf "  ${BOLD}[editing monitor:${RESET} ${CYAN}%s${RESET} ${DIM}(%s)]${RESET}\n" \
        "$m" "${MON_MODEL[$m]}"
}

detect_monitors() {
    local current_mon=""
    local backend=""

    MON_LIST=()

    # ── Hyprland ─────────────────────────────────────
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
        backend="hyprctl"

        current_mon=""

        while IFS= read -r line; do
            # Example:
            # Monitor HDMI-A-2 (ID 0):
            if [[ "$line" =~ ^Monitor[[:space:]]+([A-Za-z0-9._-]+) ]]; then
                current_mon="${BASH_REMATCH[1]}"

                MON_LIST+=("$current_mon")
                MON_MODEL["$current_mon"]="$current_mon"
                MON_MODES["$current_mon"]=""

                continue
            fi

            [[ -z "$current_mon" ]] && continue

            # Example:
            # availableModes: 1920x1080@60.00Hz 1920x1080@74.97Hz
            if [[ "$line" =~ availableModes: ]]; then
                modes_raw="${line#*availableModes: }"

                for mode in $modes_raw; do
                    if [[ "$mode" =~ ^([0-9]+)x([0-9]+)@([0-9]+(\.[0-9]+)?)Hz$ ]]; then
                        formatted="${BASH_REMATCH[1]}x${BASH_REMATCH[2]} @ ${BASH_REMATCH[3]}Hz"
                        MON_MODES["$current_mon"]+="$formatted"$'\n'
                    fi
                done
            fi

            # Example:
            # 1920x1080@74.97300 at 0x0
            if [[ "$line" =~ ^([0-9]+)x([0-9]+)@([0-9]+(\.[0-9]+)?) ]]; then
                current_mode="${BASH_REMATCH[1]}x${BASH_REMATCH[2]} @ ${BASH_REMATCH[3]}Hz"

                # Put active mode first
                if [[ -n "${MON_MODES[$current_mon]}" ]]; then
                    MON_MODES["$current_mon"]="$current_mode"$'\n'"${MON_MODES[$current_mon]}"
                else
                    MON_MODES["$current_mon"]="$current_mode"$'\n'
                fi
            fi
        done < <(hyprctl monitors all)

    # ── wlroots ──────────────────────────────────────
    elif command -v wlr-randr >/dev/null 2>&1; then
        backend="wlr-randr"

        while IFS= read -r line; do
            if [[ "$line" =~ ^([A-Za-z0-9._-]+)[[:space:]]\"([^\"]+)\" ]]; then
                current_mon="${BASH_REMATCH[1]}"

                MON_LIST+=("$current_mon")
                MON_MODEL["$current_mon"]="$(pretty_model "${BASH_REMATCH[2]}")"
                MON_MODES["$current_mon"]=""

                continue
            fi

            if [[ -n "$current_mon" && "$line" =~ ^[[:space:]]*([0-9]+)x([0-9]+)[[:space:]]px,[[:space:]]+([0-9]+(\.[0-9]+)?) ]]; then
                mode="${BASH_REMATCH[1]}x${BASH_REMATCH[2]} @ ${BASH_REMATCH[3]}Hz"
                MON_MODES["$current_mon"]+="$mode"$'\n'
            fi
        done < <(wlr-randr 2>/dev/null)

    # ── KDE Plasma ───────────────────────────────────
    elif command -v kscreen-doctor >/dev/null 2>&1; then
        backend="kscreen-doctor"

        while IFS= read -r line; do
            if [[ "$line" =~ Output:[[:space:]]+[0-9]+[[:space:]]+([A-Za-z0-9._-]+) ]]; then
                mon="${BASH_REMATCH[1]}"

                MON_LIST+=("$mon")
                MON_MODEL["$mon"]="$mon"
                MON_MODES["$mon"]="1920x1080 @ 60Hz"
            fi
        done < <(kscreen-doctor -o)

    # ── X11 ──────────────────────────────────────────
    elif command -v xrandr >/dev/null 2>&1; then
        backend="xrandr"

        while IFS= read -r line; do
            if [[ "$line" =~ ^([A-Za-z0-9._-]+)[[:space:]]connected ]]; then
                mon="${BASH_REMATCH[1]}"

                MON_LIST+=("$mon")
                MON_MODEL["$mon"]="$mon"
                MON_MODES["$mon"]=""

                while IFS= read -r mode; do
                    MON_MODES["$mon"]+="$mode"$'\n'
                done < <(
                    xrandr |
                    awk -v m="$mon" '
                        $1==m {found=1; next}
                        found && /^[[:space:]]+[0-9]/ {
                            gsub(/^[ \t]+/, "")
                            split($1,a,"x")
                            print a[1]"x"a[2]" @ "$2"Hz"
                        }
                        found && /^[A-Za-z]/ {exit}
                    '
                )
            fi
        done < <(xrandr --query)

    else
        return 1
    fi

    log info "monitor backend: $backend"
    return 0
}

if ! detect_monitors; then
    log warn "could not detect monitors"
else
    log ok "found ${#MON_LIST[@]} connected monitor(s)"

    show_monitor_labels

    for m in "${MON_LIST[@]}"; do
        local_label="${m} (${MON_MODEL[$m]})"
        printf "  ${BOLD}%s${RESET}\n" "$local_label"

        mapfile -t modes < <(printf '%s' "${MON_MODES[$m]}" | sed '/^$/d')

        if [[ ${#modes[@]} -eq 0 ]]; then
            log warn "no modes detected for $m, using 1920x1080 @ 60Hz"
            MON_SEL_W["$m"]=1920
            MON_SEL_H["$m"]=1080
            MON_SEL_R["$m"]=60
        else
            for i in "${!modes[@]}"; do
                printf "    ${DIM}%2d) %s${RESET}\n" "$((i + 1))" "${modes[$i]}"
            done

            while true; do
                print_monitor_context "$m"
                printf "  ${CYAN}➜${RESET} ${BOLD}resolution & refresh rate [1, 2, 3, ...]${RESET}: "

                read -r mode_choice
                mode_choice="${mode_choice:-1}"

                if [[ "$mode_choice" =~ ^[0-9]+$ ]] && (( mode_choice >= 1 && mode_choice <= ${#modes[@]} )); then
                    selected_mode="${modes[$((mode_choice - 1))]}"

                    if [[ "$selected_mode" =~ ^([0-9]+)x([0-9]+)[[:space:]]@\ ([0-9]+(\.[0-9]+)?)Hz$ ]]; then
                        MON_SEL_W["$m"]="${BASH_REMATCH[1]}"
                        MON_SEL_H["$m"]="${BASH_REMATCH[2]}"
                        MON_SEL_R["$m"]="${BASH_REMATCH[3]}"
                    fi
                    break
                fi

                log warn "invalid choice, try again"
            done
        fi

        print_monitor_context "$m"
        show_position_layout

        while true; do
            printf "  ${CYAN}➜${RESET} ${BOLD}position${RESET}: "
            read -r pos
            pos="${pos:-middle}"

            case "$pos" in
                left|middle|right|top|bottom|top-left|top-right|bottom-left|bottom-right)
                    set_monitor_position "$m" "$pos"
                    break
                    ;;
                *)
                    log warn "invalid position"
                    ;;
            esac
        done

        echo
    done

    top_h=0
    mid_h=0
    bot_h=0

    for m in "${MON_LIST[@]}"; do
        case "${MON_ROW[$m]}" in
            top)
                (( MON_SEL_H[$m] > top_h )) && top_h="${MON_SEL_H[$m]}"
                ;;
            middle)
                (( MON_SEL_H[$m] > mid_h )) && mid_h="${MON_SEL_H[$m]}"
                ;;
            bottom)
                (( MON_SEL_H[$m] > bot_h )) && bot_h="${MON_SEL_H[$m]}"
                ;;
        esac
    done

    for row in top middle bottom; do
        x=0

        for col in left middle right; do
            for m in "${MON_LIST[@]}"; do
                if [[ "${MON_ROW[$m]}" == "$row" && "${MON_COL[$m]}" == "$col" ]]; then
                    MON_X["$m"]="$x"

                    case "$row" in
                        top) MON_Y["$m"]=0 ;;
                        middle) MON_Y["$m"]="$top_h" ;;
                        bottom) MON_Y["$m"]=$((top_h + mid_h)) ;;
                    esac

                    x=$((x + MON_SEL_W[$m]))
                fi
            done
        done
    done

    MONITOR_FILE="$CONFIG_DIR/hypr/monitors.conf"

    mkdir -p "$CONFIG_DIR/hypr"
    : > "$MONITOR_FILE"

    for m in "${MON_LIST[@]}"; do
        printf "monitor = %s, %sx%s@%s, %sx%s, 1\n" \
            "$m" \
            "${MON_SEL_W[$m]}" \
            "${MON_SEL_H[$m]}" \
            "${MON_SEL_R[$m]}" \
            "${MON_X[$m]:-0}" \
            "${MON_Y[$m]:-0}" >> "$MONITOR_FILE"
    done

    log ok "monitors.conf written"
fi

# ── wallpaper picker ──────────────────────────────────────────────────────────

section "wallpaper"

printf "  ${DIM}pick a wallpaper to seed your color theme.\n"
printf "  you can change this any time with ${RESET}${BOLD}super + w${RESET}${DIM} in hyprland.${RESET}\n\n"

if [ -f "$CONFIG_DIR/hypr/scripts/wallpaper_fuzzel.sh" ]; then
    bash "$CONFIG_DIR/hypr/scripts/wallpaper_fuzzel.sh" || true
else
    log warn "wallpaper_fuzzel.sh not found, skipping picker"
fi

# Kill compositor-adjacent processes that the picker may have spawned
pkill hyprpaper || true
pkill waybar    || true
pkill swaync    || true

# ── done ──────────────────────────────────────────────────────────────────────

log done "install complete"
