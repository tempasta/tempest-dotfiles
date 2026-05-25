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
WALLPAPER_DEST="$HOME/.config/wallpapers"

# ── banner ────────────────────────────────────────────────────────────────────

echo
printf "${BOLD}${CYAN}  ╭──────────────────────────────────────────────────────╮${RESET}\n"
printf "${BOLD}${CYAN}  │${RESET}        ${BOLD}tempest${RESET} ${DIM}·${RESET} dotfiles installer                  ${BOLD}${CYAN}│${RESET}\n"
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
    wl-clipboard
    cliphist
    python3-pywal16
    cava
    nmtui
    hyprland
    hyprpaper
    hyprlock
    waybar
    fuzzel
    kitty
    swaync
    fastfetch
    flameshot
    wl-clipboard
    xdg-desktop-portal-hyprland
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

for cfg in hypr waybar fuzzel kitty swaync fastfetch equibop wal cava; do
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

# ── shell (zsh + oh-my-zsh) ────────────────────────────────────────────────

section "shell"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_plugin() {
    local repo="$1"
    local name="$2"
    local dir="$ZSH_CUSTOM/plugins/$name"

    if [[ ! -d "$dir" ]]; then
        log info "installing $name"
        git clone "$repo" "$dir" >/dev/null 2>&1 || true
        log ok "$name installed"
    else
        log skip "$name already installed"
    fi
}

if ! command -v zsh >/dev/null 2>&1; then
    log info "installing zsh"
    sudo dnf install -y zsh >/dev/null 2>&1 || true
    log ok "zsh installed"
else
    log skip "zsh already installed"
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log info "installing oh-my-zsh"

    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    >/dev/null 2>&1 || true

    log ok "oh-my-zsh installed"
else
    log skip "oh-my-zsh already exists"
fi

# ── plugins ────────────────────────────────────────────────────────────────

install_plugin \
    https://github.com/zsh-users/zsh-autosuggestions \
    zsh-autosuggestions

install_plugin \
    https://github.com/zsh-users/zsh-syntax-highlighting \
    zsh-syntax-highlighting

# ensure plugins are enabled
if [[ -f "$HOME/.zshrc" ]]; then
    if grep -q '^plugins=' "$HOME/.zshrc"; then
        sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
    fi
    log ok "zsh plugins enabled"
fi

# ── zshrc install ──────────────────────────────────────────────────────────

if [ -f "$DOTFILES/.zshrc" ]; then
    cp -f "$DOTFILES/.zshrc" "$HOME/.zshrc"
    log ok "zshrc installed from repo"
else
    log warn "zshrc not found in dotfiles"
fi

# ── default shell ──────────────────────────────────────────────────────────

if [[ "$SHELL" != "$(which zsh)" ]]; then
    log info "setting zsh as default shell"
    chsh -s "$(which zsh)" "$USER" >/dev/null 2>&1 || true
    log ok "default shell set to zsh"
else
    log skip "zsh already default shell"
fi

# ── monitors ─────────────────────────────────────────────────────────────────

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

MONITOR_FILE="$CONFIG_DIR/hypr/monitors.conf"
mkdir -p "$CONFIG_DIR/hypr"

generate_monitors_conf() {
    for m in "${MON_LIST[@]}"; do
        printf "monitor = %s, %sx%s@%s, %sx%s, 1\n" \
            "$m" \
            "${MON_SEL_W[$m]:-1920}" \
            "${MON_SEL_H[$m]:-1080}" \
            "${MON_SEL_R[$m]:-60}" \
            "${MON_X[$m]:-0}" \
            "${MON_Y[$m]:-0}"
    done
}

show_position_layout() {
    printf "\n  ${DIM}pick a position:${RESET}\n"
    printf "  ${BOLD}[   top-left   ]${RESET}   ${BOLD}[  top   ]${RESET}   ${BOLD}[   top-right   ]${RESET}\n"
    printf "  ${BOLD}[    left      ]${RESET}   ${BOLD}[ middle ]${RESET}   ${BOLD}[     right     ]${RESET}\n"
    printf "  ${BOLD}[ bottom-left ]${RESET}   ${BOLD}[ bottom ]${RESET}   ${BOLD}[ bottom-right ]${RESET}\n\n"
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

print_monitor_context() {
    local m="$1"
    printf "\n  ${BOLD}[monitor:${RESET} ${CYAN}%s${RESET} ${DIM}(%s)]${RESET}\n" \
        "$m" "${MON_MODEL[$m]}"
}

show_monitor_labels() {
    if ! command -v hyprctl >/dev/null 2>&1 || ! command -v zenity >/dev/null 2>&1; then
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

detect_backend() {
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] \
        && command -v hyprctl >/dev/null 2>&1 \
        && hyprctl monitors >/dev/null 2>&1; then
        echo "hyprctl"
        return 0
    fi

    if command -v wlr-randr >/dev/null 2>&1; then
        if wlr-randr 2>&1 | grep -qE "Monitor|Output"; then
            echo "wlr-randr"
            return 0
        fi
    fi

    if command -v kscreen-doctor >/dev/null 2>&1; then
        if kscreen-doctor --outputs 2>&1 | grep -qE "Output|connected|Name"; then
            echo "kscreen-doctor"
            return 0
        fi
    fi

    if command -v xrandr >/dev/null 2>&1 && xrandr --query >/dev/null 2>&1; then
        echo "xrandr"
        return 0
    fi

    return 1
}

detect_monitors() {
    MON_LIST=()
    shopt -s extglob

    local backend
    backend="$(detect_backend || true)"
    [[ -z "$backend" ]] && return 1

    log info "monitor backend: $backend"

    case "$backend" in
        hyprctl)
            local current="" name="" res=""
            while IFS= read -r line; do
                if [[ "$line" =~ ^Monitor[[:space:]]+([A-Za-z0-9._-]+) ]]; then
                    name="${BASH_REMATCH[1]}"
                    current="$name"
                    MON_LIST+=("$name")
                    MON_MODEL["$name"]="$name"
                    MON_MODES["$name"]=""
                    continue
                fi
                if [[ -n "$current" && "$line" =~ ([0-9]+)x([0-9]+)@([0-9.]+) ]]; then
                    res="${BASH_REMATCH[1]}x${BASH_REMATCH[2]} @ ${BASH_REMATCH[3]}Hz"
                    MON_MODES["$current"]+="$res"$'\n'
                fi
                if [[ "$line" == "" ]]; then
                    current=""
                fi
            done < <(hyprctl monitors all 2>/dev/null)
            ;;

        wlr-randr)
            local name="" model=""
            while IFS= read -r line; do
                if [[ "$line" =~ ^([A-Za-z0-9._-]+)[[:space:]]\"([^\"]+)\" ]]; then
                    name="${BASH_REMATCH[1]}"
                    model="${BASH_REMATCH[2]}"
                    MON_LIST+=("$name")
                    MON_MODEL["$name"]="$(pretty_model "$model")"
                    MON_MODES["$name"]=""
                    continue
                fi
                if [[ -n "$name" && "$line" =~ ([0-9]+)x([0-9]+)[[:space:]]px,[[:space:]]+([0-9.]+) ]]; then
                    MON_MODES["$name"]+="${BASH_REMATCH[1]}x${BASH_REMATCH[2]} @ ${BASH_REMATCH[3]}Hz"$'\n'
                fi
            done < <(wlr-randr 2>/dev/null)
            ;;

        kscreen-doctor)
            local name=""
            local line

            while IFS= read -r line; do

                # NEW OUTPUT BLOCK
                if [[ "$line" =~ ^Output:[[:space:]]+[0-9]+[[:space:]]+([A-Za-z0-9._-]+) ]]; then
                    name="${BASH_REMATCH[1]}"

                    MON_LIST+=("$name")
                    MON_MODEL["$name"]="$name"
                    MON_MODES["$name"]=""
                    continue
                fi

                # MODES (only if inside a monitor block)
                if [[ -n "$name" && "$line" =~ ([0-9]+)x([0-9]+)@([0-9.]+) ]]; then
                    local w="${BASH_REMATCH[1]}"
                    local h="${BASH_REMATCH[2]}"
                    local r="${BASH_REMATCH[3]}"

                    MON_MODES["$name"]+="${w}x${h} @ ${r}Hz"$'\n'
                fi

            done < <(kscreen-doctor -o 2>/dev/null)
            ;;

        xrandr)
            local name=""
            while IFS= read -r line; do
                if [[ "$line" =~ ^([A-Za-z0-9._-]+)[[:space:]]connected ]]; then
                    name="${BASH_REMATCH[1]}"
                    MON_LIST+=("$name")
                    MON_MODEL["$name"]="$name"
                    MON_MODES["$name"]=""
                    continue
                fi
                if [[ -n "$name" && "$line" =~ ^[[:space:]]*([0-9]+x[0-9]+)[[:space:]]+([0-9.]+)\*? ]]; then
                    MON_MODES["$name"]+="${BASH_REMATCH[1]} @ ${BASH_REMATCH[2]}Hz"$'\n'
                fi
            done < <(xrandr --query)
            ;;
    esac

    [[ ${#MON_LIST[@]} -eq 0 ]] && return 1
    return 0
}

if ! detect_monitors; then
    log warn "no monitors detected"
    exit 1
fi

log ok "found ${#MON_LIST[@]} monitor(s)"
show_monitor_labels

for m in "${MON_LIST[@]}"; do
    printf "\n  ${BOLD}${MAGENTA}󰍹 %s${RESET}\n" "$m"

    mapfile -t modes < <(printf '%s' "${MON_MODES[$m]}" | sed '/^$/d')

    if [[ ${#modes[@]} -eq 0 ]]; then
        MON_SEL_W["$m"]=1920
        MON_SEL_H["$m"]=1080
        MON_SEL_R["$m"]=60
    else
        for i in "${!modes[@]}"; do
            printf "  ${DIM}%2d)${RESET} %s\n" "$((i+1))" "${modes[$i]}"
        done

        while true; do
            print_monitor_context "$m"
            printf "  ${CYAN}➜ resolution [1-%d]: ${RESET}" "${#modes[@]}"
            read -r choice
            choice="${choice:-1}"

            if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice>=1 && choice<=${#modes[@]})); then
                sel="${modes[$((choice-1))]}"
                if [[ "$sel" =~ ([0-9]+)x([0-9]+)[[:space:]]*@[[:space:]]*([0-9.]+) ]]; then
                    MON_SEL_W["$m"]="${BASH_REMATCH[1]}"
                    MON_SEL_H["$m"]="${BASH_REMATCH[2]}"
                    MON_SEL_R["$m"]="${BASH_REMATCH[3]}"
                fi
                break
            fi
        done
    fi

    print_monitor_context "$m"
    show_position_layout

    while true; do
        printf "  ➜ position: "
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
done

top_h=0; mid_h=0; bot_h=0

for m in "${MON_LIST[@]}"; do
    h_val="${MON_SEL_H[$m]:-1080}"
    case "${MON_ROW[$m]:-middle}" in
        top)    (( h_val > top_h )) && top_h="$h_val" ;;
        middle) (( h_val > mid_h )) && mid_h="$h_val" ;;
        bottom) (( h_val > bot_h )) && bot_h="$h_val" ;;
    esac
done

for row in top middle bottom; do
    x_coord=0
    for col in left middle right; do
        for m in "${MON_LIST[@]}"; do
            if [[ "${MON_ROW[$m]:-middle}" == "$row" && "${MON_COL[$m]:-middle}" == "$col" ]]; then
                MON_X["$m"]="$x_coord"

                case "$row" in
                    top)    MON_Y["$m"]=0 ;;
                    middle) MON_Y["$m"]="$top_h" ;;
                    bottom) MON_Y["$m"]=$((top_h + mid_h)) ;;
                esac

                w_val="${MON_SEL_W[$m]:-1920}"
                x_coord=$((x_coord + w_val))
            fi
        done
    done
done

generate_monitors_conf > "$MONITOR_FILE"
log ok "monitors.conf written"

printf "\n  ${CYAN}review monitors.conf in nano? [y/N]: ${RESET}"
read -r confirm
confirm="${confirm:-n}"

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    nano "$MONITOR_FILE"
    log ok "user reviewed monitors.conf"
else
    log skip "skipped review"
fi

# ── clipboard ──────────────────────────────────────────────

section "clipboard"

if command -v cliphist >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
    log info "starting clipboard watcher"

    if ! pgrep -x "wl-paste" >/dev/null 2>&1; then
        nohup wl-paste --watch cliphist store >/dev/null 2>&1 &
        log ok "clipboard watcher started"
    else
        log skip "clipboard watcher already running"
    fi
else
    log warn "cliphist or wl-paste missing"
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

pkill hyprpaper || true
pkill waybar    || true
pkill swaync    || true

# ── done ──────────────────────────────────────────────────────────────────────

log done "install complete"
