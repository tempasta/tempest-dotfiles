#!/bin/bash

set -euo pipefail

echo "=== Dotfiles installer starting ==="

sudo -v

DOTFILES="$HOME/dotfiles"
REPO="https://github.com/tempasta/tempest-dotfiles.git"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup"
WALLPAPER_DEST="$HOME/Pictures/wallpapers"

echo "Installing repos..."

sudo dnf copr enable -y solopasha/hyprland || true

echo "Installing packages..."

PACKAGES=(
    git
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
)

for pkg in "${PACKAGES[@]}"; do
    echo "Installing: $pkg"

    if rpm -q "$pkg" >/dev/null 2>&1; then
        echo "  -> already installed"
        continue
    fi

    sudo dnf install -y "$pkg" || {
        echo "  -> failed to install $pkg (continuing)"
    }
done

echo "Fetching dotfiles..."

if [ -d "$DOTFILES/.git" ]; then
    echo "Updating dotfiles..."
    git -C "$DOTFILES" pull
else
    echo "Cloning dotfiles..."
    git clone "$REPO" "$DOTFILES"
fi

cd "$DOTFILES"

echo "Creating backup folder..."
mkdir -p "$BACKUP_DIR"

backup_config() {
    local name="$1"

    if [ -e "$CONFIG_DIR/$name" ]; then
        echo "Backing up $name"
        rm -rf "$BACKUP_DIR/$name.old" 2>/dev/null || true
        mv "$CONFIG_DIR/$name" "$BACKUP_DIR/$name"
    fi
}

copy_config() {
    local name="$1"

    local src="$DOTFILES/$name"
    local dest="$CONFIG_DIR/$name"

    if [ ! -d "$src" ]; then
        echo "Skipping missing config: $name"
        return
    fi

    backup_config "$name"

    echo "Copying $name..."
    cp -r "$src" "$dest"
}

echo "Installing configs..."

mkdir -p "$CONFIG_DIR"

copy_config hypr
copy_config waybar
copy_config fuzzel
copy_config kitty
copy_config swaync
copy_config fastfetch

echo "Installing wallpapers..."

mkdir -p "$WALLPAPER_DEST"

if [ -d "$DOTFILES/wallpapers" ]; then
    cp -rf "$DOTFILES/wallpapers/"* "$WALLPAPER_DEST/"
    echo "Wallpapers copied to $WALLPAPER_DEST"
else
    echo "No wallpapers folder found in repo."
fi

echo "Making scripts executable..."

chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh 2>/dev/null || true

echo "Running initial wallpaper/theme setup..."

if [ -f "$CONFIG_DIR/hypr/scripts/wallpaper_fuzzel.sh" ]; then
    bash "$CONFIG_DIR/hypr/scripts/wallpaper_fuzzel.sh" || true
else
    echo "wallpaper_fuzzel.sh not found"
fi

echo ""
echo "=== INSTALL COMPLETE ==="
echo "Log out and select the Hyprland session."