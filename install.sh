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

# Detects each connected monitor's name and preferred resolution via wlr-randr,
# lets user pick resolution + position, then calculates x offsets correctly.

section "monitors"

declare -a MON_LIST=()
declare -A MON_WIDTH=()
declare -A MON_HEIGHT=()
declare -A MON_RATE=()
declare -A MON_POS=()

show_position_layout() {
    printf "\n"
    printf "  ${DIM}pick a position:${RESET}\n"
    printf "  ${BOLD}[   top-left  ]${RESET}   ${BOLD}[  top   ]${RESET}   ${BOLD}[   top-right  ]${RESET}\n"
    printf "  ${BOLD}[    left     ]${RESET}   ${BOLD}[ middle ]${RESET}   ${BOLD}[    right     ]${RESET}\n"
    printf "  ${BOLD}[ bottom-left ]${RESET}   ${BOLD}[ bottom ]${RESET}   ${BOLD}[ bottom-right ]${RESET}\n\n"
}

print_monitor_context() {
    local m="$1"
    printf "\n"
    printf "  ${BOLD}editing monitor:${RESET} ${CYAN}%s${RESET}\n" "$m"
    printf "  ${DIM}current: %sx%s @ %sHz${RESET}\n" \
        "${MON_WIDTH[$m]}" "${MON_HEIGHT[$m]}" "${MON_RATE[$m]}"
    printf "\n"
}

set_monitor_position() {
    local mon="$1"
    local pos="$2"

    case "$pos" in
        left)         MON_POS["$mon"]="left" ;;
        middle)       MON_POS["$mon"]="middle" ;;
        right)        MON_POS["$mon"]="right" ;;
        top)          MON_POS["$mon"]="top" ;;
        bottom)       MON_POS["$mon"]="bottom" ;;
        top-left)     MON_POS["$mon"]="top-left" ;;
        top-right)    MON_POS["$mon"]="top-right" ;;
        bottom-left)  MON_POS["$mon"]="bottom-left" ;;
        bottom-right) MON_POS["$mon"]="bottom-right" ;;
    esac
}

if ! command -v wlr-randr &>/dev/null; then
    log warn "wlr-randr not found, skipping monitor setup"
    log warn "edit $CONFIG_DIR/hypr/monitors.conf manually after install pls"
else
    log info "querying connected monitors"

    current_mon=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^([A-Za-z0-9_-]+)[[:space:]]\" ]]; then
            current_mon="${BASH_REMATCH[1]}"
            MON_LIST+=("$current_mon")
            MON_WIDTH["$current_mon"]=1920
            MON_HEIGHT["$current_mon"]=1080
            MON_RATE["$current_mon"]=60

        elif [[ -n "$current_mon" && "$line" == *"(preferred)"* ]]; then
            if [[ "$line" =~ ([0-9]+)x([0-9]+)[[:space:]]px,[[:space:]]+([0-9]+\.[0-9]+) ]]; then
                MON_WIDTH["$current_mon"]="${BASH_REMATCH[1]}"
                MON_HEIGHT["$current_mon"]="${BASH_REMATCH[2]}"
                MON_RATE["$current_mon"]="${BASH_REMATCH[3]}"
            fi
            current_mon=""
        fi
    done < <(wlr-randr 2>/dev/null)

    if [[ ${#MON_LIST[@]} -eq 0 ]]; then
        log warn "no connected monitors found, skipping monitor config"
    else
        log ok "found ${#MON_LIST[@]} connected monitor(s)"

        echo
        printf "  ${DIM}available positions:${RESET}\n"
        printf "  left  middle  right  top  bottom  top-left  top-right  bottom-left  bottom-right\n\n"

        # ── resolution + position selection ───────────────────────────────

        for m in "${MON_LIST[@]}"; do
            mapfile -t modes < <(wlr-randr 2>/dev/null | awk -v mon="$m" '
                $0 ~ mon {found=1}
                found && /px/ {print}
                found && /^$/ {exit}
            ')

            print_monitor_context "$m"

            # fallback defaults
            MON_WIDTH["$m"]=1920
            MON_HEIGHT["$m"]=1080
            MON_RATE["$m"]=60

            if [[ ${#modes[@]} -gt 0 ]]; then
                for i in "${!modes[@]}"; do
                    printf "  ${DIM}%2d) %s${RESET}\n" "$((i+1))" "${modes[$i]}"
                done

                while true; do
                    printf "  ${CYAN}➜${RESET} resolution [1-${#modes[@]}]: "
                    read -r choice
                    choice="${choice:-1}"

                    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#modes[@]} )); then
                        sel="${modes[$((choice-1))]}"
                        if [[ "$sel" =~ ([0-9]+)x([0-9]+)[[:space:]]px,[[:space:]]+([0-9]+\.[0-9]+) ]]; then
                            MON_WIDTH["$m"]="${BASH_REMATCH[1]}"
                            MON_HEIGHT["$m"]="${BASH_REMATCH[2]}"
                            MON_RATE["$m"]="${BASH_REMATCH[3]}"
                        fi
                        break
                    fi
                done
            fi

            print_monitor_context "$m"
            show_position_layout

            while true; do
                printf "  ${CYAN}➜${RESET} position: "
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

        # ── sort + compute x offsets ────────────────────

        MONITOR_FILE="$CONFIG_DIR/hypr/monitors.conf"
        mkdir -p "$CONFIG_DIR/hypr"
        : > "$MONITOR_FILE"

        declare -a SORTED_MONS=()
        for slot in left middle right top bottom top-left top-right bottom-left bottom-right; do
            for m in "${MON_LIST[@]}"; do
                [[ "${MON_POS[$m]}" == "$slot" ]] && SORTED_MONS+=("$m")
            done
        done

        cumulative_x=0
        for m in "${SORTED_MONS[@]}"; do
            w="${MON_WIDTH[$m]}"
            h="${MON_HEIGHT[$m]}"
            r="${MON_RATE[$m]}"

            printf "monitor = %s, %sx%s@%s, %sx0, 1\n" \
                "$m" "$w" "$h" "$r" "$cumulative_x" >> "$MONITOR_FILE"

            cumulative_x=$(( cumulative_x + w ))
        done

        log ok "monitors.conf written"
    fi
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
