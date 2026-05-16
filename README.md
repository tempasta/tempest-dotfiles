<h1 align="center">
  minimal hyprland dotfiles for nobara/fedora
</h1>

<p align="center">
  <img src="https://github.com/user-attachments/assets/3012f48f-89c3-4e71-93ea-52a73c412df8" width="850">
</p>

## features
- hyprland
- waybar
- kitty
- fuzzel
- swaync
- pywal theming
- wallpaper picker (automatic color scheme switch for hyprland, hyprlock, waybar, fuzzel, and swaync)

## install
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tempasta/tempest-dotfiles/main/install.sh)
```

## keybinds
| keybind | action |
|----------|--------|
| `SUPER + T` | open terminal (kitty) |
| `SUPER + D` | open app launcher (fuzzel) |
| `SUPER + E` | open file manager (thunar) |
| `SUPER + B` | open browser (brave) |
| `SUPER + W` | change wallpaper/theme (fuzzel) |
| `SUPER + Q` | close active window |
| `SUPER + F` | toggle floating |
| `SUPER + L` | lock screen (hyprlock) |
| `SUPER + 1-0` | switch workspace |
| `SUPER + SHIFT + 1-0` | move window to workspace |
| `Print` | screenshot (flameshot) |
> `SUPER` = windows key

## notes
- designed for nobara/fedora
- existing configs are automatically backed up
- wallpapers are copied to `~/Pictures/wallpapers` you can add more if you want
- after install, it will prompt you to choose a wallpaper to generate the initial theme
- change wallpapers later with `SUPER + W`
- manual configuration of `hyprland.conf` may be required for multiple monitors

## preview
<p align="center">
  <img src="https://github.com/user-attachments/assets/23a7f6bb-e12a-4db1-ba10-d09abbdf050e" width="500">
</p>

<p align="center">
  <i>(too lazy to upload fuzzel previews for the rest)</i>
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/8ec43a49-3eba-454e-a8d0-573892304012" width="48%">
  <img src="https://github.com/user-attachments/assets/f4b8f56e-374b-4fda-9208-c3aac9774c71" width="48%">
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/243dfa10-c846-446a-b05f-16cc149aa251" width="850">
</p>
