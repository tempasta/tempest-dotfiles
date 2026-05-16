#!/bin/bash

set -euo pipefail

log() {
    echo "[$1] ${2,,}"
}

log init "dotfiles installer starting"

sudo -v

DOTFILES="$HOME/dotfiles"
REPO="https://github.com/tempasta/tempest-dotfiles.git"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup"
WALLPAPER_DEST="$HOME/Pictures/wallpapers"

log repos "installing copr repos"

sudo dnf copr enable -y solopasha/hyprland || true

log packages "installing packages"

PACKAGES=(
    git
    rsync
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
    log package "installing $pkg"

    if rpm -q "$pkg" >/dev/null 2>&1; then
        log package "$pkg already installed"
        continue
    fi

    sudo dnf install -y "$pkg" || {
        log warning "failed to install $pkg, continuing"
    }
done

log git "fetching dotfiles"

if [ -d "$DOTFILES/.git" ]; then
    log git "updating dotfiles"
    git -C "$DOTFILES" pull
else
    log git "cloning dotfiles"
    git clone "$REPO" "$DOTFILES"
fi

cd "$DOTFILES"

log backup "creating backup folder"
mkdir -p "$BACKUP_DIR"

sync_config() {
    local name="$1"

    local src="$DOTFILES/$name/"
    local dest="$CONFIG_DIR/$name/"
    local backup="$BACKUP_DIR/$name/"

    if [ ! -d "$src" ]; then
        log skip "missing config $name"
        return
    fi

    mkdir -p "$dest"
    mkdir -p "$backup"

    log config "syncing $name"

    rsync -ah \
        --backup \
        --backup-dir="$backup" \
        "$src" "$dest"
}

log config "installing configs"

mkdir -p "$CONFIG_DIR"

sync_config hypr
sync_config waybar
sync_config fuzzel
sync_config kitty
sync_config swaync
sync_config fastfetch
sync_config equibop
sync_config wal

log wallpapers "installing wallpapers"

mkdir -p "$WALLPAPER_DEST"

if [ -d "$DOTFILES/wallpapers" ]; then
    cp -rf "$DOTFILES/wallpapers/"* "$WALLPAPER_DEST/"
    log wallpapers "copied wallpapers"
else
    log warning "wallpapers folder missing"
fi

log theme "installing cursor and gtk theme"

mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.themes"

if [ -d "$DOTFILES/Empty-Pixel-White" ]; then
    log cursor "installing empty-pixel-white"

    rm -rf "$HOME/.local/share/icons/Empty-Pixel-White"

    cp -r "$DOTFILES/Empty-Pixel-White" \
        "$HOME/.local/share/icons/"
else
    log warning "empty-pixel-white missing"
fi

if [ -d "$DOTFILES/Adwaita-dark" ]; then
    log gtk "installing adwaita-dark"

    rm -rf "$HOME/.themes/Adwaita-dark"

    cp -r "$DOTFILES/Adwaita-dark" \
        "$HOME/.themes/"
else
    log warning "adwaita-dark missing"
fi

log shell "installing zshrc"

if [ -f "$DOTFILES/.zshrc" ]; then
    cp -f "$DOTFILES/.zshrc" "$HOME/.zshrc"
    log shell "zshrc installed"
else
    log warning "zshrc not found in repo"
fi

log gtk "applying gtk settings"

gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark" || true
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" || true
gsettings set org.gnome.desktop.interface cursor-theme "Empty-Pixel-White" || true

log fonts "installing jetbrains mono"

fc-cache -fv >/dev/null 2>&1 || true

log fonts "setting default monospace font"

gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 11" || true
gsettings set org.gnome.desktop.interface font-name "Adwaita Sans 11" || true
gsettings set org.gnome.desktop.interface document-font-name "Adwaita Sans 11" || true

mkdir -p "$HOME/.config/fontconfig"

cat > "$HOME/.config/fontconfig/fonts.conf" <<EOF
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

log scripts "making scripts executable"
chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh 2>/dev/null || true

log wallpaper "running wallpaper setup"
log wallpaper "please choose your initial wallpaper to generate a theme. you can always change this later with the keybind [SUPER + W] when in hyprland"

if [ -f "$CONFIG_DIR/hypr/scripts/wallpaper_fuzzel.sh" ]; then
    bash "$CONFIG_DIR/hypr/scripts/wallpaper_fuzzel.sh" || true
else
    log warning "could not run wallpaper picker: wallpaper_fuzzel.sh not found"
fi

echo
log done "install complete!"
