#!/bin/bash
set -e

echo "=== Dotfiles installer starting ==="

sudo -v

DOTFILES="$HOME/dotfiles"
REPO="https://github.com/tempasta/tempest-dotfiles.git"

echo "Installing packages..."

sudo dnf copr enable -y solopasha/hyprland || true

sudo dnf install -y \
    git \
    hyprland \
    waybar \
    fuzzel \
    kitty \
    swaync \
    fastfetch \
    wofi \
    rofi \
    flameshot \
    wl-clipboard \
    xdg-desktop-portal-hyprland \
    polkit-gnome \
    grim \
    slurp \
    swappy \
    brightnessctl \
    pavucontrol \
    wireplumber

if [ -d "$DOTFILES/.git" ]; then
    echo "Updating dotfiles..."
    git -C "$DOTFILES" pull
else
    echo "Cloning dotfiles..."
    git clone "$REPO" "$DOTFILES"
fi

cd "$DOTFILES"

echo "Backing up configs..."
mkdir -p "$HOME/.config-backup"

backup() {
    [ -e "$HOME/.config/$1" ] && mv "$HOME/.config/$1" "$HOME/.config-backup/"
}

backup hypr
backup waybar

link() {
    src="$DOTFILES/$1"
    dest="$HOME/.config/$1"

    [ -e "$dest" ] && mv "$dest" "$dest.bak"
    ln -s "$src" "$dest"
    echo "linked $1"
}

link hypr
link waybar
link fuzzel
link kitty
link swaync
link wofi
link rofi

echo "=== Done ==="
echo "Log out and select Hyprland session."
