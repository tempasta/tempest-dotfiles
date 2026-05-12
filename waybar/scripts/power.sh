#!/bin/bash

choice=$(printf " shutdown\n reboot\n󰍃 log out\n󰌾 lock\n󰤄 suspend" | fuzzel --dmenu)
choice=$(echo "$choice" | sed 's/^[^ ]* //')

# trim whitespace/newlines
choice=$(echo "$choice" | xargs)

case "$choice" in
    shutdown) systemctl poweroff ;;
    reboot) systemctl reboot ;;
    "log out") hyprctl dispatch exit ;;
    lock) hyprlock ;;
    suspend) systemctl suspend ;;
esac
